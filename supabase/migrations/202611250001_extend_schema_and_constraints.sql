-- ============================================================================
-- ISKOLARIUM MIGRATION 001: Extend existing schema & add missing student tables
-- Safe, idempotent migration designed for the existing Supabase schema.
-- ============================================================================

-- 1. Extend public.classes for sections, room, schedule, join code, archiving
ALTER TABLE public.classes
  ADD COLUMN IF NOT EXISTS section text NOT NULL DEFAULT 'Section A',
  ADD COLUMN IF NOT EXISTS room text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS schedule_day text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS schedule_time text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS enrollment_code text,
  ADD COLUMN IF NOT EXISTS is_archived boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE UNIQUE INDEX IF NOT EXISTS classes_enrollment_code_unique_idx
  ON public.classes (upper(enrollment_code))
  WHERE enrollment_code IS NOT NULL AND length(trim(enrollment_code)) > 0;

CREATE INDEX IF NOT EXISTS classes_instructor_id_idx
  ON public.classes (instructor_id);

-- 2. Extend public.enrollments for pending/approved/rejected & duplicate prevention
ALTER TABLE public.enrollments
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'approved',
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'enrollments_status_check'
  ) THEN
    ALTER TABLE public.enrollments
      ADD CONSTRAINT enrollments_status_check
      CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]));
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS enrollments_class_student_unique_idx
  ON public.enrollments (class_id, student_id);

CREATE INDEX IF NOT EXISTS enrollments_student_id_idx
  ON public.enrollments (student_id);

CREATE INDEX IF NOT EXISTS enrollments_class_status_idx
  ON public.enrollments (class_id, status);

-- 3. Extend public.attendance for updated_at & unique (class, student, date)
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE UNIQUE INDEX IF NOT EXISTS attendance_class_student_date_unique_idx
  ON public.attendance (class_id, student_id, attendance_date);

CREATE INDEX IF NOT EXISTS attendance_student_id_idx
  ON public.attendance (student_id, attendance_date DESC);

-- 4. Extend public.scores for max_score upper bound & updated_at
ALTER TABLE public.scores
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'scores_score_lte_max_check'
  ) THEN
    ALTER TABLE public.scores
      ADD CONSTRAINT scores_score_lte_max_check
      CHECK (score <= max_score);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS scores_student_id_idx
  ON public.scores (student_id);

CREATE INDEX IF NOT EXISTS scores_class_id_idx
  ON public.scores (class_id);

-- 5. Extend public.announcements for archiving & updated_at
ALTER TABLE public.announcements
  ADD COLUMN IF NOT EXISTS is_archived boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS announcements_class_created_idx
  ON public.announcements (class_id, created_at DESC);

-- 6. Extend public.student_tasks for subject & category labels
ALTER TABLE public.student_tasks
  ADD COLUMN IF NOT EXISTS subject text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS category text NOT NULL DEFAULT 'Task';

CREATE INDEX IF NOT EXISTS student_tasks_student_due_idx
  ON public.student_tasks (student_id, due_at);

CREATE INDEX IF NOT EXISTS student_events_student_starts_idx
  ON public.student_events (student_id, starts_at);

CREATE INDEX IF NOT EXISTS student_notifications_student_created_idx
  ON public.student_notifications (student_id, created_at DESC);

-- 7. Student personal classes (separate from official instructor classes)
CREATE TABLE IF NOT EXISTS public.student_personal_classes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  subject_code text NOT NULL,
  class_name text NOT NULL,
  instructor_name text NOT NULL DEFAULT '',
  location text NOT NULL DEFAULT '',
  schedule_day text NOT NULL DEFAULT '',
  schedule_time text NOT NULL DEFAULT '',
  section text NOT NULL DEFAULT 'Personal',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT student_personal_classes_pkey PRIMARY KEY (id),
  CONSTRAINT student_personal_classes_student_id_fkey
    FOREIGN KEY (student_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS student_personal_classes_student_idx
  ON public.student_personal_classes (student_id);

-- 8. Student study sessions
CREATE TABLE IF NOT EXISTS public.study_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  title text NOT NULL,
  subject text NOT NULL DEFAULT '',
  description text NOT NULL DEFAULT '',
  session_date date NOT NULL,
  start_time text NOT NULL,
  duration_minutes integer NOT NULL DEFAULT 60 CHECK (duration_minutes > 0),
  is_completed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT study_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT study_sessions_student_id_fkey
    FOREIGN KEY (student_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS study_sessions_student_date_idx
  ON public.study_sessions (student_id, session_date);

-- 9. Student private notes & reminders (supports class notes or standalone)
CREATE TABLE IF NOT EXISTS public.student_notes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  class_id uuid,
  personal_class_id uuid,
  title text NOT NULL DEFAULT '',
  subject_label text NOT NULL DEFAULT '',
  content text NOT NULL,
  reminder_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT student_notes_pkey PRIMARY KEY (id),
  CONSTRAINT student_notes_student_id_fkey
    FOREIGN KEY (student_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT student_notes_class_id_fkey
    FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE,
  CONSTRAINT student_notes_personal_class_id_fkey
    FOREIGN KEY (personal_class_id) REFERENCES public.student_personal_classes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS student_notes_student_idx
  ON public.student_notes (student_id, updated_at DESC);
