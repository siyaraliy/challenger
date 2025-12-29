-- ============================================
-- FIX TEAM CHAT RLS POLICIES
-- Bu SQL'i Supabase SQL Editor'da çalıştırın
-- ============================================

-- 1. MEVCUT POLİTİKALARI KALDIR
DROP POLICY IF EXISTS "Users can view their chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Approved participants can view messages" ON chat_messages;
DROP POLICY IF EXISTS "Approved participants can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can view participants of their rooms" ON chat_participants;
DROP POLICY IF EXISTS "Team members can send as team" ON chat_messages;
DROP POLICY IF EXISTS "Team members can view team chats" ON chat_rooms;

-- ============================================
-- 2. CHAT_ROOMS ERİŞİM POLİTİKALARI
-- ============================================

-- Kullanıcı kendi chats'lerini ve takım chats'lerini görebilsin
CREATE POLICY "Users and teams can view their chat rooms"
  ON chat_rooms FOR SELECT
  USING (
    -- Kullanıcı direkt katılımcı ise
    id IN (
      SELECT room_id FROM chat_participants 
      WHERE participant_type = 'user' 
        AND participant_id = auth.uid() 
        AND status = 'approved'
    )
    OR
    -- Kullanıcının takımı katılımcı ise
    id IN (
      SELECT cp.room_id FROM chat_participants cp
      INNER JOIN team_members tm ON tm.team_id = cp.participant_id
      WHERE cp.participant_type = 'team'
        AND tm.user_id = auth.uid()
        AND cp.status = 'approved'
    )
  );

-- ============================================
-- 3. CHAT_PARTICIPANTS ERİŞİM POLİTİKALARI
-- ============================================

-- Kullanıcı kendi odalarının ve takım odalarının katılımcılarını görebilsin
DROP POLICY IF EXISTS "Users can view participants of their rooms" ON chat_participants;
CREATE POLICY "Users can view participants of their rooms"
  ON chat_participants FOR SELECT
  USING (
    -- Kullanıcı odanın katılımcısı ise
    room_id IN (
      SELECT room_id FROM chat_participants 
      WHERE participant_type = 'user' 
        AND participant_id = auth.uid() 
        AND status = 'approved'
    )
    OR
    -- Kullanıcının takımı odanın katılımcısı ise
    room_id IN (
      SELECT cp.room_id FROM chat_participants cp
      INNER JOIN team_members tm ON tm.team_id = cp.participant_id
      WHERE cp.participant_type = 'team'
        AND tm.user_id = auth.uid()
        AND cp.status = 'approved'
    )
    OR
    -- Kendi bekleyen isteklerini görebilsin
    (participant_type = 'user' AND participant_id = auth.uid())
  );

-- ============================================
-- 4. CHAT_MESSAGES OKUMA POLİTİKASI
-- ============================================

-- Kullanıcı kendi ve takım odalarındaki mesajları görebilsin
CREATE POLICY "Users and teams can view messages"
  ON chat_messages FOR SELECT
  USING (
    -- Kullanıcı odanın direkt katılımcısı ise
    room_id IN (
      SELECT room_id FROM chat_participants 
      WHERE participant_type = 'user' 
        AND participant_id = auth.uid() 
        AND status = 'approved'
    )
    OR
    -- Kullanıcının takımı odanın katılımcısı ise
    room_id IN (
      SELECT cp.room_id FROM chat_participants cp
      INNER JOIN team_members tm ON tm.team_id = cp.participant_id
      WHERE cp.participant_type = 'team'
        AND tm.user_id = auth.uid()
        AND cp.status = 'approved'
    )
  );

-- ============================================
-- 5. CHAT_MESSAGES YAZMA POLİTİKASI
-- ============================================

-- Kullanıcı kendi olarak veya takım olarak mesaj atabilsin
CREATE POLICY "Users and teams can send messages"
  ON chat_messages FOR INSERT
  WITH CHECK (
    -- Kullanıcı kendi adına mesaj atıyor
    (
      sender_type = 'user' 
      AND sender_id = auth.uid()
      AND room_id IN (
        SELECT room_id FROM chat_participants 
        WHERE participant_type = 'user' 
          AND participant_id = auth.uid() 
          AND status = 'approved'
      )
    )
    OR
    -- Kullanıcı takım adına mesaj atıyor
    (
      sender_type = 'team'
      AND sender_id IN (
        SELECT team_id FROM team_members WHERE user_id = auth.uid()
      )
      AND room_id IN (
        SELECT room_id FROM chat_participants 
        WHERE participant_type = 'team' 
          AND participant_id = sender_id 
          AND status = 'approved'
      )
    )
  );

-- ============================================
-- 6. MESAJ OKUMA İŞARETLEME (UPDATE)
-- ============================================

DROP POLICY IF EXISTS "Users can mark messages as read" ON chat_messages;
CREATE POLICY "Users can mark messages as read"
  ON chat_messages FOR UPDATE
  USING (
    -- Kullanıcı odanın katılımcısı ise
    room_id IN (
      SELECT room_id FROM chat_participants 
      WHERE participant_type = 'user' 
        AND participant_id = auth.uid() 
        AND status = 'approved'
    )
    OR
    -- Kullanıcının takımı odanın katılımcısı ise
    room_id IN (
      SELECT cp.room_id FROM chat_participants cp
      INNER JOIN team_members tm ON tm.team_id = cp.participant_id
      WHERE cp.participant_type = 'team'
        AND tm.user_id = auth.uid()
        AND cp.status = 'approved'
    )
  )
  WITH CHECK (
    -- Sadece is_read alanı güncellenebilir
    is_read = true
  );

-- ============================================
-- DONE! Test için:
-- 1. Takım hesabı ile bir odaya girin
-- 2. Eskı mesajların görünüp görünmediğini kontrol edin
-- 3. Yeni mesaj atmayı deneyin
-- ============================================
