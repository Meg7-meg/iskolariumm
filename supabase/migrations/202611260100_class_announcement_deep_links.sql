-- ISKOLARIUM MIGRATION 009: Class announcement deep-link metadata
ALTER TABLE public.student_notifications
  ADD COLUMN IF NOT EXISTS class_id uuid,
  ADD COLUMN IF NOT EXISTS announcement_id uuid;

CREATE INDEX IF NOT EXISTS student_notifications_class_idx
  ON public.student_notifications (class_id);

CREATE INDEX IF NOT EXISTS student_notifications_announcement_idx
  ON public.student_notifications (announcement_id);

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

  INSERT INTO public.student_notifications (
    student_id,
    title,
    message,
    category,
    class_id,
    announcement_id
  )
  SELECT
    e.student_id,
    COALESCE(v_class_name, 'Class') || ': ' || NEW.title,
    NEW.content,
    'Classes',
    NEW.class_id,
    NEW.id
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

-- Announcements are editable and removable only by their publishing instructor.
DROP POLICY IF EXISTS "announcements_update_instructor" ON public.announcements;
CREATE POLICY "announcements_update_instructor" ON public.announcements
  FOR UPDATE TO authenticated
  USING (
    instructor_id = auth.uid()
    AND public.is_class_instructor(class_id)
  )
  WITH CHECK (
    instructor_id = auth.uid()
    AND public.is_class_instructor(class_id)
  );

DROP POLICY IF EXISTS "announcements_delete_instructor" ON public.announcements;
CREATE POLICY "announcements_delete_instructor" ON public.announcements
  FOR DELETE TO authenticated
  USING (
    instructor_id = auth.uid()
    AND public.is_class_instructor(class_id)
  );
