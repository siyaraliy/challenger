-- ============================================
-- FIX RLS INFINITE RECURSION
-- Run this in Supabase SQL Editor
-- ============================================

-- First, drop the problematic policies
DROP POLICY IF EXISTS "Users can view their chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can view participants of their rooms" ON chat_participants;
DROP POLICY IF EXISTS "Approved participants can view messages" ON chat_messages;
DROP POLICY IF EXISTS "Approved participants can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Admins can update participant status" ON chat_participants;

-- ============================================
-- NEW POLICIES (without self-referencing)
-- ============================================

-- Chat Rooms: Users can see rooms they're IN
CREATE POLICY "Users can view their chat rooms"
  ON chat_rooms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_participants 
      WHERE chat_participants.room_id = chat_rooms.id 
      AND chat_participants.participant_id = auth.uid() 
      AND chat_participants.status = 'approved'
    )
  );

-- Chat Participants: Users can see their own participation or rooms they're approved in
CREATE POLICY "Users can view participants"
  ON chat_participants FOR SELECT
  USING (
    participant_id = auth.uid()  -- Can always see own records
    OR EXISTS (
      SELECT 1 FROM chat_participants AS cp
      WHERE cp.room_id = chat_participants.room_id 
      AND cp.participant_id = auth.uid() 
      AND cp.status = 'approved'
    )
  );

-- Chat Participants: Users can insert themselves
CREATE POLICY "Users can join rooms"
  ON chat_participants FOR INSERT
  WITH CHECK (participant_id = auth.uid());

-- Chat Participants: Admins can update
CREATE POLICY "Admins can update participants"
  ON chat_participants FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM chat_participants AS cp
      WHERE cp.room_id = chat_participants.room_id 
      AND cp.participant_id = auth.uid() 
      AND cp.role = 'admin' 
      AND cp.status = 'approved'
    )
  );

-- Chat Messages: Approved users can read
CREATE POLICY "Approved can view messages"
  ON chat_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_participants 
      WHERE chat_participants.room_id = chat_messages.room_id 
      AND chat_participants.participant_id = auth.uid() 
      AND chat_participants.status = 'approved'
    )
  );

-- Chat Messages: Approved users can send
CREATE POLICY "Approved can send messages"
  ON chat_messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM chat_participants 
      WHERE chat_participants.room_id = chat_messages.room_id 
      AND chat_participants.participant_id = auth.uid() 
      AND chat_participants.status = 'approved'
    )
  );

-- ============================================
-- DONE!
-- ============================================
