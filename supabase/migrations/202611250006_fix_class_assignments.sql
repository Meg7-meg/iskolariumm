-- ============================================================================
-- ISKOLARIUM MIGRATION 006: Fix class_assignments table
-- 
-- PURPOSE
-- -------
-- The Flutter app queries `public.class_assignments` (with class_id FK to
-- public.classes). Some Supabase projects instead have `public.course_assignments`
-- referencing a `courses` table from an older schema.  This migration:
--
--   1. Creates `public.class_assignments` (idempotent – safe to re-run).
--   2. Migrates any existing rows from `public.course_assignments` that can be
--      matched to a class (via courses → classes by subject_code / name).
--   3. Applies correct RLS so instructors can CRUD and enrolled students can
--      read their own class assignments.
--   4. Refreshes the PostgREST schema cache.
--
-- SAFE TO RUN
-- -----------
-- Every statement uses IF NOT EXISTS / ON CONFLICT / DO NOTHING so running
-- this migration twice will not duplicate data or error.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Create public.class_assignments (the canonical table the app uses)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.class_assignments (
  id            uuid        NOT NULL DEFAULT gen_random_uuid(),
  class_id      uuid        NOT NULL,
  instructor_id uuid        NOT NULL,
  title         text        NOT NULL,
  description   text        NOT NULL DEFAULT '',
  category      text        NOT NULL DEFAULT 'Assignment',
  due_at        timestamptz,
  max_score     numeric,
  is_archived   boolean     NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT class_assignments_pkey
    PRIMARY KEY (id),
  CONSTRAINT class_assignments_class_id_fkey
    FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE,
  CONSTRAINT class_assignments_instructor_id_fkey
    FOREIGN KEY (instructor_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS class_assignments_class_due_idx
  ON public.class_assignments (class_id, due_at);

CREATE INDEX IF NOT EXISTS class_assignments_instructor_idx
  ON public.class_assignments (instructor_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Migrate rows from course_assignments → class_assignments
--    Only runs when course_assignments exists AND has rows that can be matched
--    to a class. Unmatched rows are left in course_assignments untouched.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_has_course_assignments boolean;
  v_has_courses            boolean;
BEGIN
  -- Check whether the legacy tables exist
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'course_assignments'
  ) INTO v_has_course_assignments;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'courses'
  ) INTO v_has_courses;

  IF v_has_course_assignments THEN
    IF v_has_courses THEN
      -- Strategy A: courses table exists → join course_assignments → courses
      --   then match courses to classes by subject_code (most reliable field).
      --   If multiple classes share a subject_code, we pick the first one by
      --   created_at to avoid ambiguity.
      INSERT INTO public.class_assignments (
        id, class_id, instructor_id,
        title, description, category,
        due_at, max_score, is_archived,
        created_at, updated_at
      )
      SELECT
        ca.id,
        c.id               AS class_id,
        COALESCE(ca.instructor_id, c.instructor_id) AS instructor_id,
        ca.title,
        COALESCE(ca.description, '')  AS description,
        COALESCE(ca.category, 'Assignment') AS category,
        ca.due_at,
        ca.max_score,
        COALESCE(ca.is_archived, false) AS is_archived,
        COALESCE(ca.created_at, now()) AS created_at,
        COALESCE(ca.updated_at, now()) AS updated_at
      FROM (
        -- Deduplicate: pick the class that best matches the course
        SELECT DISTINCT ON (ca2.id)
          ca2.*,
          cls.id AS matched_class_id
        FROM public.course_assignments ca2
        JOIN public.courses co ON co.id = ca2.course_id
        JOIN public.classes cls
          ON lower(trim(cls.subject_code)) = lower(trim(co.subject_code))
          OR lower(trim(cls.class_name))   = lower(trim(co.name))
          OR lower(trim(cls.class_name))   = lower(trim(co.title))
        ORDER BY ca2.id, cls.created_at ASC
      ) subq
      JOIN public.course_assignments ca ON ca.id = subq.id
      JOIN public.classes c ON c.id = subq.matched_class_id
      -- Skip rows already migrated
      ON CONFLICT (id) DO NOTHING;

    ELSE
      -- Strategy B: no courses table, but course_assignments has a class_id
      --   column already (some schemas use that name).  Copy directly when
      --   the class_id is a valid classes.id.
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name   = 'course_assignments'
          AND column_name  = 'class_id'
      ) THEN
        INSERT INTO public.class_assignments (
          id, class_id, instructor_id,
          title, description, category,
          due_at, max_score, is_archived,
          created_at, updated_at
        )
        SELECT
          ca.id,
          ca.class_id,
          COALESCE(ca.instructor_id, c.instructor_id) AS instructor_id,
          ca.title,
          COALESCE(ca.description, '')         AS description,
          COALESCE(ca.category, 'Assignment')  AS category,
          ca.due_at,
          ca.max_score,
          COALESCE(ca.is_archived, false)      AS is_archived,
          COALESCE(ca.created_at, now())       AS created_at,
          COALESCE(ca.updated_at, now())       AS updated_at
        FROM public.course_assignments ca
        JOIN public.classes c ON c.id = ca.class_id
        ON CONFLICT (id) DO NOTHING;
      END IF;
    END IF;

    RAISE NOTICE 'course_assignments migration complete (rows migrated where a matching class was found).';
  ELSE
    RAISE NOTICE 'course_assignments table not found – skipping legacy migration.';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. auto-updated updated_at trigger
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_class_assignments_updated_at ON public.class_assignments;
CREATE TRIGGER trg_class_assignments_updated_at
  BEFORE UPDATE ON public.class_assignments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Row Level Security
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.class_assignments ENABLE ROW LEVEL SECURITY;

-- Instructor: full CRUD on assignments they own for their classes
DROP POLICY IF EXISTS class_assignments_instructor_all ON public.class_assignments;
CREATE POLICY class_assignments_instructor_all
  ON public.class_assignments
  FOR ALL
  TO authenticated
  USING (
    instructor_id = auth.uid()
    AND public.is_class_instructor(class_id)
  )
  WITH CHECK (
    instructor_id = auth.uid()
    AND public.is_class_instructor(class_id)
  );

-- Students: read-only, only non-archived, only for enrolled classes
DROP POLICY IF EXISTS class_assignments_student_select ON public.class_assignments;
CREATE POLICY class_assignments_student_select
  ON public.class_assignments
  FOR SELECT
  TO authenticated
  USING (
    is_archived = false
    AND public.is_enrolled_student(class_id)
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Notify PostgREST to reload the schema cache
--    (This triggers Supabase's schema reload mechanism)
-- ─────────────────────────────────────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
