-- ============================================================================
-- ISKOLARIUM MIGRATION 005: Per-Meeting Attendance Sessions
-- Safe, idempotent migration linking public.attendance records to a specific
-- weekly meeting schedule (schedule_id + meeting_key) while preserving all
-- existing attendance rows (which default to meeting_key = '').
-- ============================================================================

-- 1. Add schedule_id and meeting_key columns to public.attendance
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS schedule_id uuid,
  ADD COLUMN IF NOT EXISTS meeting_key text NOT NULL DEFAULT '';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'attendance_schedule_id_fkey'
  ) THEN
    ALTER TABLE public.attendance
      ADD CONSTRAINT attendance_schedule_id_fkey
      FOREIGN KEY (schedule_id)
      REFERENCES public.class_schedules(id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- 2. Replace legacy (class_id, student_id, attendance_date) unique index
--    with (class_id, student_id, attendance_date, meeting_key) so multiple
--    meetings on the same day or week remain independent without duplicates.
DROP INDEX IF EXISTS public.attendance_class_student_date_unique_idx;

CREATE UNIQUE INDEX IF NOT EXISTS attendance_class_student_date_meeting_unique_idx
  ON public.attendance (class_id, student_id, attendance_date, meeting_key);

CREATE INDEX IF NOT EXISTS attendance_class_date_meeting_idx
  ON public.attendance (class_id, attendance_date, meeting_key);
