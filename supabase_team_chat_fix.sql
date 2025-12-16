-- ============================================
-- FIX TEAM CHAT ROOM CREATION
-- Run this in Supabase SQL Editor
-- ============================================

-- Allow users to create chat rooms (for team chats and direct chats)
DROP POLICY IF EXISTS "Users can create chat rooms" ON chat_rooms;
CREATE POLICY "Users can create chat rooms"
  ON chat_rooms FOR INSERT
  WITH CHECK (created_by = auth.uid());

-- Allow users to create participants when creating rooms
DROP POLICY IF EXISTS "Users can add participants" ON chat_participants;
CREATE POLICY "Users can add participants"
  ON chat_participants FOR INSERT
  WITH CHECK (true);  -- Allow all inserts, we control this in application logic

-- ============================================
-- DONE!
-- ============================================
