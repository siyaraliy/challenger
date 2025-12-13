-- Post Feed System Migration
-- Date: 2024-12-13
-- Description: Posts, likes, comments tables with RLS

-- =============================================
-- 1. POSTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_type VARCHAR(10) NOT NULL CHECK (author_type IN ('user', 'team')),
  author_id UUID NOT NULL,
  content TEXT NOT NULL CHECK (length(content) <= 500),
  media_type VARCHAR(10) CHECK (media_type IN ('image', 'video', 'none')),
  media_url TEXT,
  media_thumbnail_url TEXT,
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 2. POST LIKES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS post_likes (
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (post_id, user_id)
);

-- =============================================
-- 3. POST COMMENTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS post_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (length(content) <= 200),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 4. INDEXES
-- =============================================
CREATE INDEX IF NOT EXISTS idx_posts_author ON posts(author_type, author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_likes_post ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_post ON post_comments(post_id);

-- =============================================
-- 5. ENABLE RLS
-- =============================================
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 6. RLS POLICIES FOR POSTS
-- =============================================

-- Everyone can read posts (public feed)
CREATE POLICY "Posts are viewable by everyone"
  ON posts FOR SELECT
  USING (true);

-- Users can create their own posts
CREATE POLICY "Users can create their own posts"
  ON posts FOR INSERT
  WITH CHECK (
    (author_type = 'user' AND author_id = auth.uid())
    OR
    (author_type = 'team' AND author_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid()
    ))
  );

-- Users can update their own posts
CREATE POLICY "Users can update their own posts"
  ON posts FOR UPDATE
  USING (
    (author_type = 'user' AND author_id = auth.uid())
    OR
    (author_type = 'team' AND author_id IN (
      SELECT id FROM teams WHERE captain_id = auth.uid()
    ))
  );

-- Users can delete their own posts
CREATE POLICY "Users can delete their own posts"
  ON posts FOR DELETE
  USING (
    (author_type = 'user' AND author_id = auth.uid())
    OR
    (author_type = 'team' AND author_id IN (
      SELECT id FROM teams WHERE captain_id = auth.uid()
    ))
  );

-- =============================================
-- 7. RLS POLICIES FOR POST LIKES
-- =============================================

-- Everyone can see likes
CREATE POLICY "Likes are viewable by everyone"
  ON post_likes FOR SELECT
  USING (true);

-- Users can like posts
CREATE POLICY "Users can like posts"
  ON post_likes FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can unlike their own likes
CREATE POLICY "Users can unlike posts"
  ON post_likes FOR DELETE
  USING (user_id = auth.uid());

-- =============================================
-- 8. RLS POLICIES FOR POST COMMENTS
-- =============================================

-- Everyone can see comments
CREATE POLICY "Comments are viewable by everyone"
  ON post_comments FOR SELECT
  USING (true);

-- Users can create comments
CREATE POLICY "Users can create comments"
  ON post_comments FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own comments
CREATE POLICY "Users can delete their own comments"
  ON post_comments FOR DELETE
  USING (user_id = auth.uid());

-- =============================================
-- 9. FUNCTIONS FOR LIKE/COMMENT COUNTS
-- =============================================

-- Function to increment likes count
CREATE OR REPLACE FUNCTION increment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement likes count
CREATE OR REPLACE FUNCTION decrement_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment comments count
CREATE OR REPLACE FUNCTION increment_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement comments count
CREATE OR REPLACE FUNCTION decrement_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 10. TRIGGERS
-- =============================================

CREATE TRIGGER on_like_added
  AFTER INSERT ON post_likes
  FOR EACH ROW
  EXECUTE FUNCTION increment_likes_count();

CREATE TRIGGER on_like_removed
  AFTER DELETE ON post_likes
  FOR EACH ROW
  EXECUTE FUNCTION decrement_likes_count();

CREATE TRIGGER on_comment_added
  AFTER INSERT ON post_comments
  FOR EACH ROW
  EXECUTE FUNCTION increment_comments_count();

CREATE TRIGGER on_comment_removed
  AFTER DELETE ON post_comments
  FOR EACH ROW
  EXECUTE FUNCTION decrement_comments_count();

-- =============================================
-- 11. UPDATED_AT TRIGGER FOR POSTS
-- =============================================

CREATE OR REPLACE FUNCTION update_posts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_posts_updated_at_trigger
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_posts_updated_at();

-- =============================================
-- COMMENTS
-- =============================================
COMMENT ON TABLE posts IS 'User and team posts for the feed';
COMMENT ON TABLE post_likes IS 'Likes on posts';
COMMENT ON TABLE post_comments IS 'Comments on posts';
COMMENT ON COLUMN posts.author_type IS 'user or team';
COMMENT ON COLUMN posts.media_type IS 'image, video, or none';
