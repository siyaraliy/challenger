-- Posts Storage Bucket Policies
-- Run this in Supabase SQL Editor

-- Allow authenticated users to upload files
CREATE POLICY "Users can upload to posts bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'posts');

-- Allow authenticated users to update their files
CREATE POLICY "Users can update their files in posts bucket"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[3]);

-- Allow authenticated users to delete their files
CREATE POLICY "Users can delete their files in posts bucket"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[3]);

-- Allow public to read files (since bucket is public)
CREATE POLICY "Public can read posts bucket"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'posts');
