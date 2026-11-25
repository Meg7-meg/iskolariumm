-- ============================================================================
-- ISKOLARIUM MIGRATION 004: Multi-meeting Weekly Class Schedules
-- Safe, idempotent migration adding public.class_schedules with RLS policies.
-- Existing public.classes.schedule_day / schedule_time columns are preserved
-- for backward compatibility and summary display.
-- ============================================================================

-- 1. Create normalized weekly class schedules table
CREATE TABLE IF NOT EXISTS public.class_schedules (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  class_id uuid NOT NULL,
  day_of_week text NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT class_schedules_pkey PRIMARY KEY (id),
  CONSTRAINT class_schedules_class_id_fkey
    FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE,
  CONSTRAINT class_schedules_day_check
    CHECK (day_of_week = ANY (ARRAY[
      'Monday'::text,
      'Tuesday'::text,
      'Wednesday'::text,
      'Thursday'::text,
      'Friday'::text,
      'Saturday'::text,
      'Sunday'::text
    ])),
  CONSTRAINT class_schedules_time_order_check
    CHECK (end_time > start_time)
);

-- 2. Index for fast lookup by class and ordered weekly display
CREATE INDEX IF NOT EXISTS class_schedules_class_id_idx
  ON public.class_schedules (class_id, day_of_week, start_time);

-- 3. Row Level Security for public.class_schedules
ALTER TABLE public.class_schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS class_schedules_instructor_all ON public.class_schedules;
CREATE POLICY class_schedules_instructor_all
  ON public.class_schedules
  FOR ALL
  TO authenticated
  USING (public.is_class_instructor(class_id))
  WITH CHECK (public.is_class_instructor(class_id));

DROP POLICY IF EXISTS class_schedules_student_select ON public.class_schedules;
CREATE POLICY class_schedules_student_select
  ON public.class_schedules
  FOR SELECT
  TO authenticated
  USING (public.is_enrolled_student(class_id));
