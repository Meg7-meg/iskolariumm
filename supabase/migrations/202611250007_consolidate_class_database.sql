-- ============================================================================
-- ISKOLARIUM MIGRATION 007: Consolidate Class Database
--
-- PURPOSE
-- -------
-- Audit confirmed:
--   classes              → 1 record   (PRIMARY system ✓)
--   enrollments          → 2 records  (PRIMARY system ✓)
--   courses              → 0 records  (legacy, unused)
--   course_enrollments   → 0 records  (legacy, unused)
--   course_assignments   → 0 records  (legacy, unused)
--
-- Flutter code has ZERO references to courses / course_enrollments /
-- course_assignments.  All app queries use:
--   classes, enrollments, class_assignments, attendance, scores,
--   announcements, class_schedules, student_* tables.
--
-- This migration:
--   1. Ensures public.class_assignments exists and is correctly structured
--      (class_id → classes.id, instructor_id → profiles.id).
--   2. Adds room column to class_schedules (required by per-meeting room
--      feature introduced alongside migration 004).
--   3. Safely drops the empty, unused course-based tables in dependency order:
--      course_assignments → course_enrollments → courses.
--   4. Verifies all RLS helper functions exist.
--   5. Re-applies all RLS policies relevant to class_assignments to ensure
--      they are present regardless of which prior migrations were run.
--   6. Reloads PostgREST schema cache.
--
-- SAFE TO RUN
-- -----------
-- All statements use IF NOT EXISTS / IF EXISTS / ON CONFLICT DO NOTHING.
-- Running this migration twice will not error or duplicate data.
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1: Ensure class_assignments table is correct
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
    FOREIGN KEY (class_id)
    REFERENCES public.classes(id) ON DELETE CASCADE,
  CONSTRAINT class_assignments_instructor_id_fkey
    FOREIGN KEY (instructor_id)
    REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- Ensure indexes (safe if already exist)
CREATE INDEX IF NOT EXISTS class_assignments_class_due_idx
  ON public.class_assignments (class_id, due_at);

CREATE INDEX IF NOT EXISTS class_assignments_instructor_idx
  ON public.class_assignments (instructor_id);

-- Enable RLS (idempotent)
ALTER TABLE public.class_assignments ENABLE ROW LEVEL SECURITY;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2: Ensure updated_at auto-trigger exists (class_assignments)
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
-- SECTION 3: RLS policies for class_assignments
--   (re-applied with DROP IF EXISTS + CREATE so they are always up to date)
-- ─────────────────────────────────────────────────────────────────────────────

-- Instructors: full CRUD on assignments they own for classes they teach
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

-- Students: read-only, only non-archived, only for their enrolled classes
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
-- SECTION 4: Ensure room column exists on class_schedules
--   (added by per-meeting room feature; class_service.dart reads/writes it)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.class_schedules
  ADD COLUMN IF NOT EXISTS room text NOT NULL DEFAULT '';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 5: Extend public.classes with academic_year and program columns
--   (added by migration 003; safe if already applied)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.classes
  ADD COLUMN IF NOT EXISTS academic_year text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS program       text NOT NULL DEFAULT '';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 6: Drop legacy course-based tables (all confirmed empty)
--   Drop in dependency order: course_assignments first, then course_enrollments,
--   then courses.  All use CASCADE to handle any stale RLS policies / indexes.
-- ─────────────────────────────────────────────────────────────────────────────

-- Only drop if the tables exist and are genuinely empty to stay safe.
DO $$
DECLARE
  v_count bigint;
BEGIN
  -- course_assignments
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'course_assignments'
  ) THEN
    SELECT COUNT(*) INTO v_count FROM public.course_assignments;
    IF v_count = 0 THEN
      DROP TABLE public.course_assignments CASCADE;
      RAISE NOTICE 'Dropped empty table: public.course_assignments';
    ELSE
      RAISE NOTICE 'Skipped dropping course_assignments: % rows still present', v_count;
    END IF;
  END IF;

  -- course_enrollments
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'course_enrollments'
  ) THEN
    SELECT COUNT(*) INTO v_count FROM public.course_enrollments;
    IF v_count = 0 THEN
      DROP TABLE public.course_enrollments CASCADE;
      RAISE NOTICE 'Dropped empty table: public.course_enrollments';
    ELSE
      RAISE NOTICE 'Skipped dropping course_enrollments: % rows still present', v_count;
    END IF;
  END IF;

  -- courses
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'courses'
  ) THEN
    SELECT COUNT(*) INTO v_count FROM public.courses;
    IF v_count = 0 THEN
      DROP TABLE public.courses CASCADE;
      RAISE NOTICE 'Dropped empty table: public.courses';
    ELSE
      RAISE NOTICE 'Skipped dropping courses: % rows still present', v_count;
    END IF;
  END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 7: Verify helper functions exist (non-destructive check)
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'is_class_instructor'
      AND pronamespace = 'public'::regnamespace
  ) THEN
    RAISE EXCEPTION
      'Required function public.is_class_instructor() is missing. '
      'Run migration 002 (rls_policies_and_functions.sql) first.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'is_enrolled_student'
      AND pronamespace = 'public'::regnamespace
  ) THEN
    RAISE EXCEPTION
      'Required function public.is_enrolled_student() is missing. '
      'Run migration 002 (rls_policies_and_functions.sql) first.';
  END IF;

  RAISE NOTICE 'All required RLS helper functions confirmed present.';
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 8: Reload PostgREST schema cache
-- ─────────────────────────────────────────────────────────────────────────────

NOTIFY pgrst, 'reload schema';
