-- Attendance is limited to the stored weekly schedule. Historical corrections
-- use dedicated RPCs and retain an immutable audit record.

ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS remarks text NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS public.attendance_correction_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attendance_id uuid NOT NULL
    REFERENCES public.attendance(id) ON DELETE CASCADE,
  session_id uuid NOT NULL
    REFERENCES public.attendance_sessions(id) ON DELETE CASCADE,
  class_id uuid NOT NULL
    REFERENCES public.classes(id) ON DELETE CASCADE,
  student_id uuid NOT NULL
    REFERENCES public.profiles(id) ON DELETE CASCADE,
  action text NOT NULL
    CHECK (action IN ('corrected', 'missed_meeting')),
  old_status text,
  new_status text NOT NULL
    CHECK (new_status IN ('present', 'absent', 'late', 'excused')),
  old_remarks text NOT NULL DEFAULT '',
  new_remarks text NOT NULL DEFAULT '',
  correction_reason text NOT NULL
    CHECK (length(trim(correction_reason)) > 0),
  corrected_by uuid NOT NULL
    REFERENCES public.profiles(id) ON DELETE CASCADE,
  corrected_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS attendance_correction_audit_session_idx
  ON public.attendance_correction_audit (session_id, corrected_at DESC);

CREATE INDEX IF NOT EXISTS attendance_correction_audit_record_idx
  ON public.attendance_correction_audit (attendance_id, corrected_at DESC);

-- Preserve legacy attendance rows by giving them a session before enabling
-- session-based history and per-session student uniqueness.
INSERT INTO public.attendance_sessions (
  class_id, session_date, meeting_key, instructor_id
)
SELECT
  a.class_id,
  a.attendance_date,
  COALESCE(a.meeting_key, ''),
  c.instructor_id
FROM public.attendance a
JOIN public.classes c ON c.id = a.class_id
WHERE NOT EXISTS (
  SELECT 1
  FROM public.attendance_sessions s
  WHERE s.class_id = a.class_id
    AND s.session_date = a.attendance_date
    AND s.meeting_key = COALESCE(a.meeting_key, '')
)
GROUP BY
  a.class_id,
  a.attendance_date,
  COALESCE(a.meeting_key, ''),
  c.instructor_id
ON CONFLICT (class_id, session_date, meeting_key) DO NOTHING;

UPDATE public.attendance a
SET session_id = s.id
FROM public.attendance_sessions s
WHERE a.session_id IS NULL
  AND s.class_id = a.class_id
  AND s.session_date = a.attendance_date
  AND s.meeting_key = COALESCE(a.meeting_key, '');

CREATE UNIQUE INDEX IF NOT EXISTS attendance_session_student_unique_idx
  ON public.attendance (session_id, student_id)
  WHERE session_id IS NOT NULL;

ALTER TABLE public.attendance_correction_audit ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS attendance_correction_audit_instructor_select
  ON public.attendance_correction_audit;
CREATE POLICY attendance_correction_audit_instructor_select
  ON public.attendance_correction_audit
  FOR SELECT
  TO authenticated
  USING (public.is_class_instructor(class_id));

GRANT SELECT ON public.attendance_correction_audit TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.attendance_correction_audit
  FROM authenticated;

-- Session inserts and record changes must go through the checked RPCs below.
DROP POLICY IF EXISTS attendance_sessions_instructor_all
  ON public.attendance_sessions;
DROP POLICY IF EXISTS attendance_sessions_instructor_select
  ON public.attendance_sessions;
CREATE POLICY attendance_sessions_instructor_select
  ON public.attendance_sessions
  FOR SELECT
  TO authenticated
  USING (public.is_class_instructor(class_id));

DROP POLICY IF EXISTS attendance_insert_instructor ON public.attendance;
DROP POLICY IF EXISTS attendance_update_instructor ON public.attendance;
DROP POLICY IF EXISTS attendance_delete_instructor ON public.attendance;

CREATE OR REPLACE FUNCTION public.is_class_meeting_date(
  p_class_id uuid,
  p_meeting_date date,
  p_schedule_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_weekday integer;
  v_day_name text;
  v_legacy_days text;
  v_legacy_compact text;
  v_legacy_match boolean := false;
BEGIN
  v_weekday := EXTRACT(ISODOW FROM p_meeting_date)::integer;
  v_day_name := (ARRAY[
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ])[v_weekday];

  IF p_schedule_id IS NOT NULL THEN
    RETURN EXISTS (
      SELECT 1
      FROM public.class_schedules cs
      WHERE cs.id = p_schedule_id
        AND cs.class_id = p_class_id
        AND cs.day_of_week = v_day_name
    );
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.class_schedules cs
    WHERE cs.class_id = p_class_id
      AND cs.day_of_week = v_day_name
  ) THEN
    RETURN true;
  END IF;

  SELECT lower(COALESCE(c.schedule_day, ''))
  INTO v_legacy_days
  FROM public.classes c
  WHERE c.id = p_class_id;

  IF v_legacy_days IS NULL THEN
    RETURN false;
  END IF;
  v_legacy_compact := regexp_replace(v_legacy_days, '[^a-z]', '', 'g');

  CASE v_weekday
    WHEN 1 THEN
      v_legacy_match := v_legacy_days ~ '(^|[^a-z])(monday|mon)([^a-z]|$)'
        OR v_legacy_compact = 'mwf';
    WHEN 2 THEN
      v_legacy_match := v_legacy_days ~ '(^|[^a-z])(tuesday|tue)([^a-z]|$)'
        OR v_legacy_compact = 'tth';
    WHEN 3 THEN
      v_legacy_match := v_legacy_days ~ '(^|[^a-z])(wednesday|wed)([^a-z]|$)'
        OR v_legacy_compact = 'mwf';
    WHEN 4 THEN
      v_legacy_match := v_legacy_days ~ '(^|[^a-z])(thursday|thu)([^a-z]|$)'
        OR v_legacy_compact = 'tth';
    WHEN 5 THEN
      v_legacy_match := v_legacy_days ~ '(^|[^a-z])(friday|fri)([^a-z]|$)'
        OR v_legacy_compact = 'mwf';
    WHEN 6 THEN
      v_legacy_match := v_legacy_days ~ '(^|[^a-z])(saturday|sat)([^a-z]|$)';
    WHEN 7 THEN
      v_legacy_match := v_legacy_days ~ '(^|[^a-z])(sunday|sun)([^a-z]|$)';
  END CASE;

  RETURN v_legacy_match;
END;
$$;

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
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_session_id uuid;
  v_key text := COALESCE(p_meeting_key, '');
  v_item jsonb;
  v_student_id uuid;
  v_status text;
  v_remarks text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not signed in.';
  END IF;
  IF NOT public.is_class_instructor(p_class_id) THEN
    RAISE EXCEPTION 'Only the class instructor can record attendance.';
  END IF;
  IF p_attendance_date <> (now() AT TIME ZONE 'Asia/Manila')::date THEN
    RAISE EXCEPTION 'Attendance can only be recorded for the current Manila date.';
  END IF;
  IF NOT public.is_class_meeting_date(
    p_class_id, p_attendance_date, p_schedule_id
  ) THEN
    RAISE EXCEPTION 'This class has no scheduled meeting on that date.';
  END IF;
  IF jsonb_typeof(COALESCE(p_records, 'null'::jsonb)) <> 'array' THEN
    RAISE EXCEPTION 'Attendance records must be an array.';
  END IF;
  IF jsonb_array_length(p_records) = 0 THEN
    RAISE EXCEPTION 'Attendance must include at least one student.';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(p_class_id::text || ':' || p_attendance_date::text, 0)
  );
  IF EXISTS (
    SELECT 1
    FROM public.attendance_sessions s
    WHERE s.class_id = p_class_id
      AND s.session_date = p_attendance_date
      AND s.meeting_key = v_key
  ) THEN
    RAISE EXCEPTION 'Attendance has already been saved for this class meeting date.';
  END IF;

  INSERT INTO public.attendance_sessions (
    class_id, schedule_id, meeting_key, session_date,
    meeting_label, room, instructor_id
  )
  VALUES (
    p_class_id, p_schedule_id, v_key, p_attendance_date,
    COALESCE(p_meeting_label, ''), COALESCE(p_room, ''), v_uid
  )
  RETURNING id INTO v_session_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_records)
  LOOP
    v_student_id := (v_item ->> 'student_id')::uuid;
    v_status := lower(COALESCE(v_item ->> 'status', ''));
    v_remarks := COALESCE(v_item ->> 'remarks', '');
    IF v_status NOT IN ('present', 'absent', 'late', 'excused') THEN
      RAISE EXCEPTION 'Invalid attendance status: %', v_status;
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM public.enrollments e
      WHERE e.class_id = p_class_id
        AND e.student_id = v_student_id
        AND e.status = 'approved'
    ) THEN
      RAISE EXCEPTION 'Student is not enrolled in this class.';
    END IF;

    INSERT INTO public.attendance (
      class_id, student_id, marked_by, attendance_date, status,
      schedule_id, meeting_key, session_id, remarks, updated_at
    )
    VALUES (
      p_class_id, v_student_id, v_uid, p_attendance_date, v_status,
      p_schedule_id, v_key, v_session_id, v_remarks, now()
    );
  END LOOP;

  RETURN v_session_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.correct_attendance_session(
  p_session_id uuid,
  p_correction_reason text,
  p_records jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_session public.attendance_sessions%ROWTYPE;
  v_item jsonb;
  v_student_id uuid;
  v_status text;
  v_remarks text;
  v_record public.attendance%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not signed in.';
  END IF;
  IF length(trim(COALESCE(p_correction_reason, ''))) = 0 THEN
    RAISE EXCEPTION 'A correction reason is required.';
  END IF;
  SELECT * INTO v_session
  FROM public.attendance_sessions
  WHERE id = p_session_id
  FOR UPDATE;
  IF NOT FOUND OR NOT public.is_class_instructor(v_session.class_id) THEN
    RAISE EXCEPTION 'Attendance session not found or not authorized.';
  END IF;
  IF jsonb_typeof(COALESCE(p_records, 'null'::jsonb)) <> 'array' THEN
    RAISE EXCEPTION 'Attendance correction records must be an array.';
  END IF;
  IF jsonb_array_length(p_records) = 0 THEN
    RAISE EXCEPTION 'Attendance correction records must be a non-empty array.';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(p_records, '[]'::jsonb))
  LOOP
    v_student_id := (v_item ->> 'student_id')::uuid;
    v_status := lower(COALESCE(v_item ->> 'status', ''));
    v_remarks := COALESCE(v_item ->> 'remarks', '');
    IF v_status NOT IN ('present', 'absent', 'late', 'excused') THEN
      RAISE EXCEPTION 'Invalid attendance status: %', v_status;
    END IF;

    SELECT * INTO v_record
    FROM public.attendance a
    WHERE a.session_id = v_session.id
      AND a.class_id = v_session.class_id
      AND a.student_id = v_student_id
    FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Attendance record not found for student %.', v_student_id;
    END IF;

    IF v_record.status IS DISTINCT FROM v_status
       OR COALESCE(v_record.remarks, '') IS DISTINCT FROM v_remarks THEN
      INSERT INTO public.attendance_correction_audit (
        attendance_id, session_id, class_id, student_id, action,
        old_status, new_status, old_remarks, new_remarks,
        correction_reason, corrected_by
      )
      VALUES (
        v_record.id, v_session.id, v_session.class_id, v_student_id,
        'corrected', v_record.status, v_status,
        COALESCE(v_record.remarks, ''), v_remarks,
        trim(p_correction_reason), v_uid
      );

      UPDATE public.attendance
      SET status = v_status,
          remarks = v_remarks,
          marked_by = v_uid,
          updated_at = now()
      WHERE id = v_record.id;
    END IF;
  END LOOP;

  UPDATE public.attendance_sessions
  SET updated_at = now()
  WHERE id = v_session.id;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_missed_attendance_session(
  p_class_id uuid,
  p_attendance_date date,
  p_schedule_id uuid,
  p_meeting_key text,
  p_meeting_label text,
  p_room text,
  p_correction_reason text,
  p_records jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_session_id uuid;
  v_key text := COALESCE(p_meeting_key, '');
  v_item jsonb;
  v_student_id uuid;
  v_status text;
  v_remarks text;
  v_attendance_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not signed in.';
  END IF;
  IF NOT public.is_class_instructor(p_class_id) THEN
    RAISE EXCEPTION 'Only the class instructor can correct attendance.';
  END IF;
  IF length(trim(COALESCE(p_correction_reason, ''))) = 0 THEN
    RAISE EXCEPTION 'A correction reason is required.';
  END IF;
  IF p_attendance_date >= (now() AT TIME ZONE 'Asia/Manila')::date THEN
    RAISE EXCEPTION 'A missed meeting correction must be for a past date.';
  END IF;
  IF NOT public.is_class_meeting_date(
    p_class_id, p_attendance_date, p_schedule_id
  ) THEN
    RAISE EXCEPTION 'This class had no scheduled meeting on that date.';
  END IF;
  IF jsonb_typeof(COALESCE(p_records, 'null'::jsonb)) <> 'array' THEN
    RAISE EXCEPTION 'Attendance records must be an array.';
  END IF;
  IF jsonb_array_length(p_records) = 0 THEN
    RAISE EXCEPTION 'Attendance must include at least one student.';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(p_class_id::text || ':' || p_attendance_date::text, 0)
  );
  IF EXISTS (
    SELECT 1
    FROM public.attendance_sessions s
    WHERE s.class_id = p_class_id
      AND s.session_date = p_attendance_date
      AND s.meeting_key = v_key
  ) THEN
    RAISE EXCEPTION 'An attendance session already exists for this class meeting date.';
  END IF;

  INSERT INTO public.attendance_sessions (
    class_id, schedule_id, meeting_key, session_date,
    meeting_label, room, instructor_id
  )
  VALUES (
    p_class_id, p_schedule_id, v_key, p_attendance_date,
    COALESCE(p_meeting_label, ''), COALESCE(p_room, ''), v_uid
  )
  RETURNING id INTO v_session_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_records)
  LOOP
    v_student_id := (v_item ->> 'student_id')::uuid;
    v_status := lower(COALESCE(v_item ->> 'status', ''));
    v_remarks := COALESCE(v_item ->> 'remarks', '');
    IF v_status NOT IN ('present', 'absent', 'late', 'excused') THEN
      RAISE EXCEPTION 'Invalid attendance status: %', v_status;
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM public.enrollments e
      WHERE e.class_id = p_class_id
        AND e.student_id = v_student_id
        AND e.status = 'approved'
    ) THEN
      RAISE EXCEPTION 'Student is not enrolled in this class.';
    END IF;

    INSERT INTO public.attendance (
      class_id, student_id, marked_by, attendance_date, status,
      schedule_id, meeting_key, session_id, remarks, updated_at
    )
    VALUES (
      p_class_id, v_student_id, v_uid, p_attendance_date, v_status,
      p_schedule_id, v_key, v_session_id, v_remarks, now()
    )
    RETURNING id INTO v_attendance_id;

    INSERT INTO public.attendance_correction_audit (
      attendance_id, session_id, class_id, student_id, action,
      old_status, new_status, old_remarks, new_remarks,
      correction_reason, corrected_by
    )
    VALUES (
      v_attendance_id, v_session_id, p_class_id, v_student_id,
      'missed_meeting', NULL, v_status, '', v_remarks,
      trim(p_correction_reason), v_uid
    );
  END LOOP;

  RETURN v_session_id;
END;
$$;

REVOKE ALL ON FUNCTION public.is_class_meeting_date(uuid, date, uuid)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.save_attendance_session(
  uuid, date, uuid, text, text, text, jsonb
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.correct_attendance_session(uuid, text, jsonb)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.record_missed_attendance_session(
  uuid, date, uuid, text, text, text, text, jsonb
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.save_attendance_session(
  uuid, date, uuid, text, text, text, jsonb
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.correct_attendance_session(
  uuid, text, jsonb
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_missed_attendance_session(
  uuid, date, uuid, text, text, text, text, jsonb
) TO authenticated;
