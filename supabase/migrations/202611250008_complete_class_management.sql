-- ============================================================================
-- ISKOLARIUM MIGRATION 008: Complete Class Management (Tasks, Quizzes, Scores,
-- Attendance Sessions, Class Schedules, Learning Materials, RLS, & RPCs)
--
-- Inspected against live Supabase schema on 2026-11-25.
-- Preserves all existing data (classes, enrollments, attendance, announcements).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CLASS SCHEDULES: Add missing RLS policies & backfill existing class
-- ----------------------------------------------------------------------------
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

-- Backfill existing class schedules if class_schedules is empty for the existing class
INSERT INTO public.class_schedules (class_id, day_of_week, start_time, end_time, location_type, room)
SELECT '54b16f1b-7682-4a6d-b32b-b2181d529324'::uuid, 'Monday', '08:00:00'::time, '10:00:00'::time, 'room', 'room 2'
WHERE EXISTS (SELECT 1 FROM public.classes WHERE id = '54b16f1b-7682-4a6d-b32b-b2181d529324'::uuid)
  AND NOT EXISTS (SELECT 1 FROM public.class_schedules WHERE class_id = '54b16f1b-7682-4a6d-b32b-b2181d529324'::uuid);

INSERT INTO public.class_schedules (class_id, day_of_week, start_time, end_time, location_type, room)
SELECT '54b16f1b-7682-4a6d-b32b-b2181d529324'::uuid, 'Wednesday', '15:00:00'::time, '17:00:00'::time, 'room', 'room 4'
WHERE EXISTS (SELECT 1 FROM public.classes WHERE id = '54b16f1b-7682-4a6d-b32b-b2181d529324'::uuid)
  AND NOT EXISTS (
    SELECT 1 FROM public.class_schedules
    WHERE class_id = '54b16f1b-7682-4a6d-b32b-b2181d529324'::uuid
      AND day_of_week = 'Wednesday'
  );

-- ----------------------------------------------------------------------------
-- 2. CLASS ASSIGNMENTS: Align columns (category, max_score), RLS & notification
--    (Existing table uses `created_by` referencing `profiles.id`)
-- ----------------------------------------------------------------------------
ALTER TABLE public.class_assignments
  ADD COLUMN IF NOT EXISTS category text NOT NULL DEFAULT 'Assignment',
  ADD COLUMN IF NOT EXISTS max_score numeric;

CREATE INDEX IF NOT EXISTS class_assignments_class_due_idx
  ON public.class_assignments (class_id, due_at);

CREATE INDEX IF NOT EXISTS class_assignments_created_by_idx
  ON public.class_assignments (created_by);

ALTER TABLE public.class_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enrolled students can view class assignments" ON public.class_assignments;
DROP POLICY IF EXISTS "Instructors can manage their class assignments" ON public.class_assignments;
DROP POLICY IF EXISTS class_assignments_instructor_all ON public.class_assignments;
DROP POLICY IF EXISTS class_assignments_student_select ON public.class_assignments;

CREATE POLICY class_assignments_instructor_all
  ON public.class_assignments
  FOR ALL
  TO authenticated
  USING (public.is_class_instructor(class_id))
  WITH CHECK (
    created_by = (SELECT auth.uid())
    AND public.is_class_instructor(class_id)
  );

CREATE POLICY class_assignments_student_select
  ON public.class_assignments
  FOR SELECT
  TO authenticated
  USING (
    is_archived = false
    AND public.is_enrolled_student(class_id)
  );

CREATE OR REPLACE FUNCTION public.notify_class_assignment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_class_name text;
BEGIN
  SELECT class_name INTO v_class_name FROM public.classes WHERE id = NEW.class_id;

  INSERT INTO public.student_notifications (student_id, title, message, category)
  SELECT
    e.student_id,
    'New ' || COALESCE(NULLIF(trim(NEW.category), ''), 'Assignment') || ': ' || NEW.title,
    COALESCE(v_class_name, 'Class') ||
      CASE
        WHEN NEW.due_at IS NULL THEN ''
        ELSE ' · Due ' || to_char(NEW.due_at AT TIME ZONE 'UTC', 'Mon DD at HH12:MI AM')
      END,
    'Tasks'
  FROM public.enrollments e
  JOIN public.profiles p ON p.id = e.student_id
  WHERE e.class_id = NEW.class_id
    AND e.status = 'approved'
    AND lower(COALESCE(p.notification_preferences ->> 'tasks', 'true')) <> 'false';

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_class_assignment ON public.class_assignments;
CREATE TRIGGER trg_notify_class_assignment
  AFTER INSERT ON public.class_assignments
  FOR EACH ROW EXECUTE FUNCTION public.notify_class_assignment();

-- Re-point student_assignment_status FK from course_assignments to class_assignments
ALTER TABLE public.student_assignment_status
  DROP CONSTRAINT IF EXISTS student_assignment_status_assignment_id_fkey;

ALTER TABLE public.student_assignment_status
  ADD CONSTRAINT student_assignment_status_assignment_id_fkey
  FOREIGN KEY (assignment_id) REFERENCES public.class_assignments(id) ON DELETE CASCADE;

DROP POLICY IF EXISTS "Students manage their assignment status" ON public.student_assignment_status;
CREATE POLICY student_assignment_status_own
  ON public.student_assignment_status
  FOR ALL
  TO authenticated
  USING (
    student_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.class_assignments a
      WHERE a.id = student_assignment_status.assignment_id
        AND public.is_enrolled_student(a.class_id)
    )
  )
  WITH CHECK (
    student_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.class_assignments a
      WHERE a.id = student_assignment_status.assignment_id
        AND public.is_enrolled_student(a.class_id)
    )
  );

-- ----------------------------------------------------------------------------
-- 3. QUIZZES & LEARNING MATERIALS: Link to public.classes (class_id)
-- ----------------------------------------------------------------------------
ALTER TABLE public.quizzes
  ALTER COLUMN course_id DROP NOT NULL;

ALTER TABLE public.quizzes
  ADD COLUMN IF NOT EXISTS class_id uuid REFERENCES public.classes(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS is_archived boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS quizzes_class_id_idx
  ON public.quizzes (class_id);

DROP POLICY IF EXISTS "Course members read quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Instructors manage quizzes" ON public.quizzes;
DROP POLICY IF EXISTS quizzes_instructor_all ON public.quizzes;
DROP POLICY IF EXISTS quizzes_student_select ON public.quizzes;

CREATE POLICY quizzes_instructor_all
  ON public.quizzes
  FOR ALL
  TO authenticated
  USING (
    class_id IS NOT NULL
    AND public.is_class_instructor(class_id)
  )
  WITH CHECK (
    class_id IS NOT NULL
    AND instructor_id = (SELECT auth.uid())
    AND public.is_class_instructor(class_id)
  );

CREATE POLICY quizzes_student_select
  ON public.quizzes
  FOR SELECT
  TO authenticated
  USING (
    is_archived = false
    AND class_id IS NOT NULL
    AND public.is_enrolled_student(class_id)
  );

CREATE OR REPLACE FUNCTION public.validate_quiz_submission()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_class_id uuid;
  v_max_score numeric;
BEGIN
  SELECT q.class_id, q.max_score
  INTO v_class_id, v_max_score
  FROM public.quizzes q
  WHERE q.id = NEW.quiz_id;

  IF v_class_id IS NULL THEN
    RAISE EXCEPTION 'The quiz no longer exists or is not linked to a class.';
  END IF;
  IF NEW.score IS NOT NULL AND (NEW.score < 0 OR NEW.score > v_max_score) THEN
    RAISE EXCEPTION 'Score must be between 0 and the assessment maximum.';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.enrollments e
    WHERE e.class_id = v_class_id
      AND e.student_id = NEW.student_id
      AND e.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'The student is not enrolled in this class.';
  END IF;
  RETURN NEW;
END;
$$;

DROP POLICY IF EXISTS "Instructors manage quiz submissions" ON public.quiz_submissions;
DROP POLICY IF EXISTS "Students read own quiz submissions" ON public.quiz_submissions;

CREATE POLICY quiz_submissions_instructor_all
  ON public.quiz_submissions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quizzes q
      WHERE q.id = quiz_submissions.quiz_id
        AND q.class_id IS NOT NULL
        AND public.is_class_instructor(q.class_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.quizzes q
      WHERE q.id = quiz_submissions.quiz_id
        AND q.class_id IS NOT NULL
        AND public.is_class_instructor(q.class_id)
    )
  );

CREATE POLICY quiz_submissions_student_select_own
  ON public.quiz_submissions
  FOR SELECT
  TO authenticated
  USING (student_id = (SELECT auth.uid()));

-- Learning materials linked to classes
ALTER TABLE public.learning_materials
  ALTER COLUMN course_id DROP NOT NULL;

ALTER TABLE public.learning_materials
  ADD COLUMN IF NOT EXISTS class_id uuid REFERENCES public.classes(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS learning_materials_class_id_idx
  ON public.learning_materials (class_id);

DROP POLICY IF EXISTS "Course members read learning materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Instructors manage learning materials" ON public.learning_materials;

CREATE POLICY learning_materials_instructor_all
  ON public.learning_materials
  FOR ALL
  TO authenticated
  USING (class_id IS NOT NULL AND public.is_class_instructor(class_id))
  WITH CHECK (
    class_id IS NOT NULL
    AND instructor_id = (SELECT auth.uid())
    AND public.is_class_instructor(class_id)
  );

CREATE POLICY learning_materials_student_select
  ON public.learning_materials
  FOR SELECT
  TO authenticated
  USING (class_id IS NOT NULL AND public.is_enrolled_student(class_id));

-- ----------------------------------------------------------------------------
-- 4. ATTENDANCE SESSIONS & PER-MEETING ATTENDANCE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.attendance_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  class_id uuid NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  schedule_id uuid REFERENCES public.class_schedules(id) ON DELETE SET NULL,
  meeting_key text NOT NULL DEFAULT '',
  session_date date NOT NULL,
  meeting_label text NOT NULL DEFAULT '',
  room text NOT NULL DEFAULT '',
  instructor_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT attendance_sessions_pkey PRIMARY KEY (id)
);

CREATE UNIQUE INDEX IF NOT EXISTS attendance_sessions_unique_idx
  ON public.attendance_sessions (class_id, session_date, meeting_key);

ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS attendance_sessions_instructor_all ON public.attendance_sessions;
CREATE POLICY attendance_sessions_instructor_all
  ON public.attendance_sessions
  FOR ALL
  TO authenticated
  USING (public.is_class_instructor(class_id))
  WITH CHECK (
    instructor_id = (SELECT auth.uid())
    AND public.is_class_instructor(class_id)
  );

DROP POLICY IF EXISTS attendance_sessions_student_select ON public.attendance_sessions;
CREATE POLICY attendance_sessions_student_select
  ON public.attendance_sessions
  FOR SELECT
  TO authenticated
  USING (public.is_enrolled_student(class_id));

ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS session_id uuid REFERENCES public.attendance_sessions(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS schedule_id uuid REFERENCES public.class_schedules(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS meeting_key text NOT NULL DEFAULT '';

-- Drop legacy unique constraint/index so multiple meetings on the same date stay independent
ALTER TABLE public.attendance
  DROP CONSTRAINT IF EXISTS attendance_class_id_student_id_attendance_date_key;
DROP INDEX IF EXISTS public.attendance_class_id_student_id_attendance_date_key;
DROP INDEX IF EXISTS public.attendance_class_student_date_unique_idx;

CREATE UNIQUE INDEX IF NOT EXISTS attendance_class_student_date_meeting_unique_idx
  ON public.attendance (class_id, student_id, attendance_date, meeting_key);

CREATE INDEX IF NOT EXISTS attendance_class_date_meeting_idx
  ON public.attendance (class_id, attendance_date, meeting_key);

-- Atomic RPC for saving an attendance session and all student records in one transaction
CREATE OR REPLACE FUNCTION public.save_attendance_session(
  p_class_id uuid,
  p_attendance_date date,
  p_schedule_id uuid DEFAULT NULL,
  p_meeting_key text DEFAULT '',
  p_meeting_label text DEFAULT '',
  p_room text DEFAULT '',
  p_records jsonb DEFAULT '[]'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_session_id uuid;
  v_key text := COALESCE(p_meeting_key, '');
  v_item jsonb;
  v_student_id uuid;
  v_status text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not signed in.';
  END IF;

  IF NOT public.is_class_instructor(p_class_id) THEN
    RAISE EXCEPTION 'Only the class instructor can record attendance.';
  END IF;

  INSERT INTO public.attendance_sessions (
    class_id, schedule_id, meeting_key, session_date, meeting_label, room, instructor_id
  )
  VALUES (
    p_class_id, p_schedule_id, v_key, p_attendance_date,
    COALESCE(p_meeting_label, ''), COALESCE(p_room, ''), v_uid
  )
  ON CONFLICT (class_id, session_date, meeting_key)
  DO UPDATE SET
    schedule_id = COALESCE(EXCLUDED.schedule_id, public.attendance_sessions.schedule_id),
    meeting_label = CASE WHEN EXCLUDED.meeting_label <> '' THEN EXCLUDED.meeting_label ELSE public.attendance_sessions.meeting_label END,
    room = CASE WHEN EXCLUDED.room <> '' THEN EXCLUDED.room ELSE public.attendance_sessions.room END,
    instructor_id = v_uid,
    updated_at = now()
  RETURNING id INTO v_session_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(p_records, '[]'::jsonb))
  LOOP
    v_student_id := (v_item ->> 'student_id')::uuid;
    v_status := lower(COALESCE(v_item ->> 'status', 'present'));
    IF v_status NOT IN ('present', 'absent', 'late', 'excused') THEN
      RAISE EXCEPTION 'Invalid attendance status: %', v_status;
    END IF;

    INSERT INTO public.attendance (
      class_id, student_id, marked_by, attendance_date, status,
      schedule_id, meeting_key, session_id, updated_at
    )
    VALUES (
      p_class_id, v_student_id, v_uid, p_attendance_date, v_status,
      p_schedule_id, v_key, v_session_id, now()
    )
    ON CONFLICT (class_id, student_id, attendance_date, meeting_key)
    DO UPDATE SET
      status = EXCLUDED.status,
      marked_by = v_uid,
      schedule_id = COALESCE(EXCLUDED.schedule_id, public.attendance.schedule_id),
      session_id = v_session_id,
      updated_at = now();
  END LOOP;

  RETURN v_session_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. SCORES: Link to tasks (class_assignments) & quizzes, prevent duplicates
-- ----------------------------------------------------------------------------
ALTER TABLE public.scores
  ADD COLUMN IF NOT EXISTS assignment_id uuid REFERENCES public.class_assignments(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS quiz_id uuid REFERENCES public.quizzes(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'released';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'scores_status_check'
  ) THEN
    ALTER TABLE public.scores
      ADD CONSTRAINT scores_status_check
      CHECK (status = ANY (ARRAY['pending'::text, 'released'::text]));
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS scores_assignment_student_unique_idx
  ON public.scores (class_id, student_id, assignment_id)
  WHERE assignment_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS scores_quiz_student_unique_idx
  ON public.scores (class_id, student_id, quiz_id)
  WHERE quiz_id IS NOT NULL;

-- Atomic RPC for saving/updating scores per task or quiz without duplicates
CREATE OR REPLACE FUNCTION public.save_assessment_scores(
  p_class_id uuid,
  p_assessment_name text,
  p_category text,
  p_max_score numeric,
  p_assignment_id uuid DEFAULT NULL,
  p_quiz_id uuid DEFAULT NULL,
  p_status text DEFAULT 'released',
  p_scores jsonb DEFAULT '[]'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_item jsonb;
  v_student_id uuid;
  v_score numeric;
  v_cat text := lower(COALESCE(NULLIF(trim(p_category), ''), 'assignment'));
  v_name text := trim(COALESCE(p_assessment_name, ''));
  v_status text := lower(COALESCE(NULLIF(trim(p_status), ''), 'released'));
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not signed in.';
  END IF;
  IF NOT public.is_class_instructor(p_class_id) THEN
    RAISE EXCEPTION 'Only the class instructor can record scores.';
  END IF;
  IF p_assignment_id IS NULL AND p_quiz_id IS NULL THEN
    RAISE EXCEPTION 'Scores must be linked to an existing task or quiz.';
  END IF;
  IF p_max_score IS NULL OR p_max_score <= 0 THEN
    RAISE EXCEPTION 'Maximum score must be greater than 0.';
  END IF;
  IF v_name = '' THEN
    RAISE EXCEPTION 'Assessment name is required.';
  END IF;
  IF v_status NOT IN ('pending', 'released') THEN
    RAISE EXCEPTION 'Invalid score status.';
  END IF;

  IF p_assignment_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.class_assignments a
    WHERE a.id = p_assignment_id AND a.class_id = p_class_id
  ) THEN
    RAISE EXCEPTION 'The selected task does not belong to this class.';
  END IF;

  IF p_quiz_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.quizzes q
    WHERE q.id = p_quiz_id AND q.class_id = p_class_id
  ) THEN
    RAISE EXCEPTION 'The selected quiz does not belong to this class.';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(p_scores, '[]'::jsonb))
  LOOP
    v_student_id := (v_item ->> 'student_id')::uuid;
    v_score := (v_item ->> 'score')::numeric;

    IF v_score IS NULL OR v_score < 0 OR v_score > p_max_score THEN
      RAISE EXCEPTION 'Score must be between 0 and %.', p_max_score;
    END IF;

    IF p_assignment_id IS NOT NULL THEN
      INSERT INTO public.scores (
        class_id, student_id, instructor_id, assignment_id,
        assessment_name, category, score, max_score, status, updated_at
      )
      VALUES (
        p_class_id, v_student_id, v_uid, p_assignment_id,
        v_name, v_cat, v_score, p_max_score, v_status, now()
      )
      ON CONFLICT (class_id, student_id, assignment_id)
      WHERE assignment_id IS NOT NULL
      DO UPDATE SET
        assessment_name = EXCLUDED.assessment_name,
        category = EXCLUDED.category,
        score = EXCLUDED.score,
        max_score = EXCLUDED.max_score,
        status = EXCLUDED.status,
        instructor_id = v_uid,
        updated_at = now();
    ELSE
      INSERT INTO public.scores (
        class_id, student_id, instructor_id, quiz_id,
        assessment_name, category, score, max_score, status, updated_at
      )
      VALUES (
        p_class_id, v_student_id, v_uid, p_quiz_id,
        v_name, v_cat, v_score, p_max_score, v_status, now()
      )
      ON CONFLICT (class_id, student_id, quiz_id)
      WHERE quiz_id IS NOT NULL
      DO UPDATE SET
        assessment_name = EXCLUDED.assessment_name,
        category = EXCLUDED.category,
        score = EXCLUDED.score,
        max_score = EXCLUDED.max_score,
        status = EXCLUDED.status,
        instructor_id = v_uid,
        updated_at = now();
    END IF;
  END LOOP;
END;
$$;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
