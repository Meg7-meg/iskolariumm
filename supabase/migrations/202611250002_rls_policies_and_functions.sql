-- ============================================================================
-- ISKOLARIUM MIGRATION 002: Triggers, RPCs, and Row Level Security (RLS)
-- ============================================================================

-- 1. Non-recursive SECURITY DEFINER helpers
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT lower(role) FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_class_instructor(p_class_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.classes c
    WHERE c.id = p_class_id
      AND c.instructor_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_enrolled_student(p_class_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.enrollments e
    WHERE e.class_id = p_class_id
      AND e.student_id = auth.uid()
      AND e.status = 'approved'
  );
$$;

-- 2. Auto-create profile on auth.users signup (works even with email confirmation)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
  v_name text;
BEGIN
  v_role := lower(COALESCE(new.raw_user_meta_data->>'role', 'student'));
  IF v_role NOT IN ('student', 'instructor') THEN
    v_role := 'student';
  END IF;

  v_name := COALESCE(NULLIF(trim(new.raw_user_meta_data->>'full_name'), ''), '');

  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (new.id, v_name, new.email, v_role)
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        full_name = CASE
          WHEN public.profiles.full_name = '' THEN EXCLUDED.full_name
          ELSE public.profiles.full_name
        END;

  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Prevent users from changing their own role via ordinary profile updates
CREATE OR REPLACE FUNCTION public.prevent_profile_role_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role AND auth.uid() IS NOT NULL THEN
    RAISE EXCEPTION 'Role cannot be modified.';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_profile_role_change ON public.profiles;
CREATE TRIGGER trg_prevent_profile_role_change
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_profile_role_change();

-- 4. Student join class by enrollment code RPC
CREATE OR REPLACE FUNCTION public.join_class_by_code(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_role text;
  v_class record;
  v_existing record;
  v_enrollment_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT lower(role) INTO v_role FROM public.profiles WHERE id = v_uid;
  IF v_role IS DISTINCT FROM 'student' THEN
    RAISE EXCEPTION 'Only student accounts can join classes with a code.';
  END IF;

  SELECT c.*, p.full_name AS instructor_name
  INTO v_class
  FROM public.classes c
  JOIN public.profiles p ON p.id = c.instructor_id
  WHERE upper(trim(c.enrollment_code)) = upper(trim(p_code))
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No class found with that enrollment code.';
  END IF;

  IF v_class.is_archived THEN
    RAISE EXCEPTION 'This class is archived and no longer accepting enrollments.';
  END IF;

  SELECT id, status INTO v_existing
  FROM public.enrollments
  WHERE class_id = v_class.id AND student_id = v_uid;

  IF FOUND THEN
    IF v_existing.status = 'approved' THEN
      RAISE EXCEPTION 'You are already enrolled in this class.';
    ELSIF v_existing.status = 'pending' THEN
      RAISE EXCEPTION 'Your enrollment request for this class is already pending approval.';
    ELSE
      UPDATE public.enrollments
      SET status = 'pending', updated_at = now()
      WHERE id = v_existing.id
      RETURNING id INTO v_enrollment_id;
    END IF;
  ELSE
    INSERT INTO public.enrollments (class_id, student_id, status)
    VALUES (v_class.id, v_uid, 'pending')
    RETURNING id INTO v_enrollment_id;
  END IF;

  INSERT INTO public.student_notifications (student_id, title, message, category)
  VALUES (
    v_uid,
    'Enrollment Request Sent',
    'Your request to join ' || v_class.class_name || ' (' || COALESCE(v_class.subject_code, '') || ') is pending instructor approval.',
    'Classes'
  );

  RETURN jsonb_build_object(
    'enrollment_id', v_enrollment_id,
    'class_id', v_class.id,
    'class_name', v_class.class_name,
    'subject_code', v_class.subject_code,
    'section', v_class.section,
    'status', 'pending'
  );
END;
$$;

-- 5. Instructor manual enrollment by student email RPC
CREATE OR REPLACE FUNCTION public.instructor_enroll_student_by_email(
  p_class_id uuid,
  p_student_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_class record;
  v_student record;
  v_existing record;
  v_enrollment_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_class
  FROM public.classes
  WHERE id = p_class_id AND instructor_id = v_uid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'You are not authorized to manage enrollments for this class.';
  END IF;

  SELECT id, full_name, email, lower(role) AS role
  INTO v_student
  FROM public.profiles
  WHERE lower(email) = lower(trim(p_student_email))
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No user found with that email address.';
  END IF;

  IF v_student.role IS DISTINCT FROM 'student' THEN
    RAISE EXCEPTION 'Only student accounts can be enrolled in a class.';
  END IF;

  SELECT id, status INTO v_existing
  FROM public.enrollments
  WHERE class_id = p_class_id AND student_id = v_student.id;

  IF FOUND THEN
    IF v_existing.status = 'approved' THEN
      RAISE EXCEPTION 'This student is already enrolled in the class.';
    END IF;
    UPDATE public.enrollments
    SET status = 'approved', updated_at = now()
    WHERE id = v_existing.id
    RETURNING id INTO v_enrollment_id;
  ELSE
    INSERT INTO public.enrollments (class_id, student_id, status)
    VALUES (p_class_id, v_student.id, 'approved')
    RETURNING id INTO v_enrollment_id;
  END IF;

  INSERT INTO public.student_notifications (student_id, title, message, category)
  VALUES (
    v_student.id,
    'Enrolled in Class',
    'You have been enrolled in ' || v_class.class_name || ' (' || v_class.section || ').',
    'Classes'
  );

  RETURN jsonb_build_object(
    'enrollment_id', v_enrollment_id,
    'student_id', v_student.id,
    'student_name', v_student.full_name,
    'student_email', v_student.email,
    'status', 'approved'
  );
END;
$$;

-- 6. Notification triggers for enrollment approval/rejection & announcements
CREATE OR REPLACE FUNCTION public.notify_enrollment_decision()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_class_name text;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status IN ('approved', 'rejected') THEN
    SELECT class_name INTO v_class_name FROM public.classes WHERE id = NEW.class_id;
    INSERT INTO public.student_notifications (student_id, title, message, category)
    VALUES (
      NEW.student_id,
      CASE WHEN NEW.status = 'approved' THEN 'Enrollment Approved' ELSE 'Enrollment Declined' END,
      CASE WHEN NEW.status = 'approved'
        THEN 'Your enrollment in ' || COALESCE(v_class_name, 'the class') || ' has been approved.'
        ELSE 'Your enrollment request for ' || COALESCE(v_class_name, 'the class') || ' was declined.'
      END,
      'Classes'
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_enrollment_decision ON public.enrollments;
CREATE TRIGGER trg_notify_enrollment_decision
  AFTER UPDATE ON public.enrollments
  FOR EACH ROW EXECUTE FUNCTION public.notify_enrollment_decision();

CREATE OR REPLACE FUNCTION public.notify_class_announcement()
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
    COALESCE(v_class_name, 'Class') || ': ' || NEW.title,
    NEW.content,
    'Classes'
  FROM public.enrollments e
  WHERE e.class_id = NEW.class_id
    AND e.status = 'approved';

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_class_announcement ON public.announcements;
CREATE TRIGGER trg_notify_class_announcement
  AFTER INSERT ON public.announcements
  FOR EACH ROW EXECUTE FUNCTION public.notify_class_announcement();

-- 7. Enable RLS across all application tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_personal_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_notes ENABLE ROW LEVEL SECURITY;

-- PROFILES policies
DROP POLICY IF EXISTS "profiles_select_own_or_class_relation" ON public.profiles;
CREATE POLICY "profiles_select_own_or_class_relation" ON public.profiles
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.classes c ON c.id = e.class_id
      WHERE e.student_id = public.profiles.id
        AND c.instructor_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.classes c ON c.id = e.class_id
      WHERE c.instructor_id = public.profiles.id
        AND e.student_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "profiles_insert_self" ON public.profiles;
CREATE POLICY "profiles_insert_self" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "profiles_update_self" ON public.profiles;
CREATE POLICY "profiles_update_self" ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- CLASSES policies
DROP POLICY IF EXISTS "classes_select_authorized" ON public.classes;
CREATE POLICY "classes_select_authorized" ON public.classes
  FOR SELECT TO authenticated
  USING (
    instructor_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.enrollments e
      WHERE e.class_id = public.classes.id
        AND e.student_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "classes_insert_instructor" ON public.classes;
CREATE POLICY "classes_insert_instructor" ON public.classes
  FOR INSERT TO authenticated
  WITH CHECK (
    instructor_id = auth.uid()
    AND public.current_user_role() = 'instructor'
  );

DROP POLICY IF EXISTS "classes_update_instructor" ON public.classes;
CREATE POLICY "classes_update_instructor" ON public.classes
  FOR UPDATE TO authenticated
  USING (instructor_id = auth.uid())
  WITH CHECK (instructor_id = auth.uid());

DROP POLICY IF EXISTS "classes_delete_instructor" ON public.classes;
CREATE POLICY "classes_delete_instructor" ON public.classes
  FOR DELETE TO authenticated
  USING (instructor_id = auth.uid());

-- ENROLLMENTS policies
DROP POLICY IF EXISTS "enrollments_select_authorized" ON public.enrollments;
CREATE POLICY "enrollments_select_authorized" ON public.enrollments
  FOR SELECT TO authenticated
  USING (
    student_id = auth.uid()
    OR public.is_class_instructor(class_id)
  );

DROP POLICY IF EXISTS "enrollments_insert_authorized" ON public.enrollments;
CREATE POLICY "enrollments_insert_authorized" ON public.enrollments
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_class_instructor(class_id)
    OR (student_id = auth.uid() AND status = 'pending')
  );

DROP POLICY IF EXISTS "enrollments_update_instructor" ON public.enrollments;
CREATE POLICY "enrollments_update_instructor" ON public.enrollments
  FOR UPDATE TO authenticated
  USING (public.is_class_instructor(class_id))
  WITH CHECK (public.is_class_instructor(class_id));

DROP POLICY IF EXISTS "enrollments_delete_authorized" ON public.enrollments;
CREATE POLICY "enrollments_delete_authorized" ON public.enrollments
  FOR DELETE TO authenticated
  USING (
    public.is_class_instructor(class_id)
    OR (student_id = auth.uid() AND status = 'pending')
  );

-- ANNOUNCEMENTS policies
DROP POLICY IF EXISTS "announcements_select_authorized" ON public.announcements;
CREATE POLICY "announcements_select_authorized" ON public.announcements
  FOR SELECT TO authenticated
  USING (
    public.is_class_instructor(class_id)
    OR (NOT is_archived AND public.is_enrolled_student(class_id))
  );

DROP POLICY IF EXISTS "announcements_insert_instructor" ON public.announcements;
CREATE POLICY "announcements_insert_instructor" ON public.announcements
  FOR INSERT TO authenticated
  WITH CHECK (
    instructor_id = auth.uid()
    AND public.is_class_instructor(class_id)
  );

DROP POLICY IF EXISTS "announcements_update_instructor" ON public.announcements;
CREATE POLICY "announcements_update_instructor" ON public.announcements
  FOR UPDATE TO authenticated
  USING (public.is_class_instructor(class_id))
  WITH CHECK (public.is_class_instructor(class_id));

DROP POLICY IF EXISTS "announcements_delete_instructor" ON public.announcements;
CREATE POLICY "announcements_delete_instructor" ON public.announcements
  FOR DELETE TO authenticated
  USING (public.is_class_instructor(class_id));

-- ATTENDANCE policies
DROP POLICY IF EXISTS "attendance_select_authorized" ON public.attendance;
CREATE POLICY "attendance_select_authorized" ON public.attendance
  FOR SELECT TO authenticated
  USING (
    student_id = auth.uid()
    OR public.is_class_instructor(class_id)
  );

DROP POLICY IF EXISTS "attendance_insert_instructor" ON public.attendance;
CREATE POLICY "attendance_insert_instructor" ON public.attendance
  FOR INSERT TO authenticated
  WITH CHECK (
    marked_by = auth.uid()
    AND public.is_class_instructor(class_id)
  );

DROP POLICY IF EXISTS "attendance_update_instructor" ON public.attendance;
CREATE POLICY "attendance_update_instructor" ON public.attendance
  FOR UPDATE TO authenticated
  USING (public.is_class_instructor(class_id))
  WITH CHECK (public.is_class_instructor(class_id));

DROP POLICY IF EXISTS "attendance_delete_instructor" ON public.attendance;
CREATE POLICY "attendance_delete_instructor" ON public.attendance
  FOR DELETE TO authenticated
  USING (public.is_class_instructor(class_id));

-- SCORES policies
DROP POLICY IF EXISTS "scores_select_authorized" ON public.scores;
CREATE POLICY "scores_select_authorized" ON public.scores
  FOR SELECT TO authenticated
  USING (
    student_id = auth.uid()
    OR public.is_class_instructor(class_id)
  );

DROP POLICY IF EXISTS "scores_insert_instructor" ON public.scores;
CREATE POLICY "scores_insert_instructor" ON public.scores
  FOR INSERT TO authenticated
  WITH CHECK (
    instructor_id = auth.uid()
    AND public.is_class_instructor(class_id)
  );

DROP POLICY IF EXISTS "scores_update_instructor" ON public.scores;
CREATE POLICY "scores_update_instructor" ON public.scores
  FOR UPDATE TO authenticated
  USING (public.is_class_instructor(class_id))
  WITH CHECK (public.is_class_instructor(class_id));

DROP POLICY IF EXISTS "scores_delete_instructor" ON public.scores;
CREATE POLICY "scores_delete_instructor" ON public.scores
  FOR DELETE TO authenticated
  USING (public.is_class_instructor(class_id));

-- STUDENT-PRIVATE TABLES policies
DROP POLICY IF EXISTS "student_tasks_own" ON public.student_tasks;
CREATE POLICY "student_tasks_own" ON public.student_tasks
  FOR ALL TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "student_events_own" ON public.student_events;
CREATE POLICY "student_events_own" ON public.student_events
  FOR ALL TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "student_notifications_own" ON public.student_notifications;
CREATE POLICY "student_notifications_own" ON public.student_notifications
  FOR ALL TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "student_personal_classes_own" ON public.student_personal_classes;
CREATE POLICY "student_personal_classes_own" ON public.student_personal_classes
  FOR ALL TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "study_sessions_own" ON public.study_sessions;
CREATE POLICY "study_sessions_own" ON public.study_sessions
  FOR ALL TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "student_notes_own" ON public.student_notes;
CREATE POLICY "student_notes_own" ON public.student_notes
  FOR ALL TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());
