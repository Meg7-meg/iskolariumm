-- ============================================================================
-- ISKOLARIUM MIGRATION 003: Academic Year, Program & Instructor Assignments
-- Safe, idempotent migration extending public.classes and adding
-- public.class_assignments with RLS policies.
-- ============================================================================

-- 1. Add academic_year and program columns to public.classes
ALTER TABLE public.classes
  ADD COLUMN IF NOT EXISTS academic_year text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS program text NOT NULL DEFAULT '';

-- 2. Instructor-published class assignments
CREATE TABLE IF NOT EXISTS public.class_assignments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  class_id uuid NOT NULL,
  instructor_id uuid NOT NULL,
  title text NOT NULL,
  description text NOT NULL DEFAULT '',
  category text NOT NULL DEFAULT 'Assignment',
  due_at timestamptz,
  max_score numeric,
  is_archived boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT class_assignments_pkey PRIMARY KEY (id),
  CONSTRAINT class_assignments_class_id_fkey
    FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE,
  CONSTRAINT class_assignments_instructor_id_fkey
    FOREIGN KEY (instructor_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS class_assignments_class_due_idx
  ON public.class_assignments (class_id, due_at);

CREATE INDEX IF NOT EXISTS class_assignments_instructor_idx
  ON public.class_assignments (instructor_id);

-- 3. Row Level Security for public.class_assignments
ALTER TABLE public.class_assignments ENABLE ROW LEVEL SECURITY;

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

DROP POLICY IF EXISTS class_assignments_student_select ON public.class_assignments;
CREATE POLICY class_assignments_student_select
  ON public.class_assignments
  FOR SELECT
  TO authenticated
  USING (
    is_archived = false
    AND public.is_enrolled_student(class_id)
  );
