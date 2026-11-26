ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_path text;

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'instructor-profile-photos',
  'instructor-profile-photos',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/png']
)
ON CONFLICT (id) DO UPDATE
SET public = false,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "instructor_profile_photos_select_own"
  ON storage.objects;
CREATE POLICY "instructor_profile_photos_select_own"
  ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'instructor-profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND lower(p.role) = 'instructor'
    )
  );

DROP POLICY IF EXISTS "instructor_profile_photos_insert_own"
  ON storage.objects;
CREATE POLICY "instructor_profile_photos_insert_own"
  ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'instructor-profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND lower(p.role) = 'instructor'
    )
  );

DROP POLICY IF EXISTS "instructor_profile_photos_update_own"
  ON storage.objects;
CREATE POLICY "instructor_profile_photos_update_own"
  ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'instructor-profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND lower(p.role) = 'instructor'
    )
  )
  WITH CHECK (
    bucket_id = 'instructor-profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND lower(p.role) = 'instructor'
    )
  );

DROP POLICY IF EXISTS "instructor_profile_photos_delete_own"
  ON storage.objects;
CREATE POLICY "instructor_profile_photos_delete_own"
  ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'instructor-profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND lower(p.role) = 'instructor'
    )
  );
