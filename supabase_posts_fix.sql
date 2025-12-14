-- Post Feed System - Fix/Reset Policies
-- Run this if you get "policy already exists" errors

-- Drop existing policies first
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON posts;
DROP POLICY IF EXISTS "Users can create their own posts" ON posts;
DROP POLICY IF EXISTS "Users can update their own posts" ON posts;
DROP POLICY IF EXISTS "Users can delete their own posts" ON posts;
DROP POLICY IF EXISTS "Likes are viewable by everyone" ON post_likes;
DROP POLICY IF EXISTS "Users can like posts" ON post_likes;
DROP POLICY IF EXISTS "Users can unlike posts" ON post_likes;
DROP POLICY IF EXISTS "Comments are viewable by everyone" ON post_comments;
DROP POLICY IF EXISTS "Users can create comments" ON post_comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON post_comments;

-- Now recreate policies

-- Posts policies
CREATE POLICY "Posts are viewable by everyone"
  ON posts FOR SELECT
  USING (true);

CREATE POLICY "Users can create their own posts"
  ON posts FOR INSERT
  WITH CHECK (
    (author_type = 'user' AND author_id = auth.uid())
    OR
    (author_type = 'team' AND author_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid()
    ))
  );

CREATE POLICY "Users can update their own posts"
  ON posts FOR UPDATE
  USING (
    (author_type = 'user' AND author_id = auth.uid())
    OR
    (author_type = 'team' AND author_id IN (
      SELECT id FROM teams WHERE captain_id = auth.uid()
    ))
  );

CREATE POLICY "Users can delete their own posts"
  ON posts FOR DELETE
  USING (
    (author_type = 'user' AND author_id = auth.uid())
    OR
    (author_type = 'team' AND author_id IN (
      SELECT id FROM teams WHERE captain_id = auth.uid()
    ))
  );

-- Post likes policies
CREATE POLICY "Likes are viewable by everyone"
  ON post_likes FOR SELECT
  USING (true);

CREATE POLICY "Users can like posts"
  ON post_likes FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can unlike posts"
  ON post_likes FOR DELETE
  USING (user_id = auth.uid());

-- Post comments policies
CREATE POLICY "Comments are viewable by everyone"
  ON post_comments FOR SELECT
  USING (true);

CREATE POLICY "Users can create comments"
  ON post_comments FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own comments"
  ON post_comments FOR DELETE
  USING (user_id = auth.uid());
