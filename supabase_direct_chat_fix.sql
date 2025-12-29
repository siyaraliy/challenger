-- ============================================
-- FIX DIRECT CHAT CREATION
-- Bu SQL'i Supabase SQL Editor'da çalıştırın
-- ============================================

-- 1. Chat room oluşturma politikası (direct + team_group)
DROP POLICY IF EXISTS "Users can create direct chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can create chat rooms" ON chat_rooms;
CREATE POLICY "Users can create chat rooms"
  ON chat_rooms FOR INSERT
  WITH CHECK (
    -- Direct chat veya team_group oluşturabilir
    (type = 'direct' AND created_by = auth.uid())
    OR
    (type = 'team_group' AND created_by = auth.uid())
  );

-- 2. Participant ekleme politikası (direct chat için her iki tarafı da ekleyebilmeli)
DROP POLICY IF EXISTS "Users can join rooms" ON chat_participants;
DROP POLICY IF EXISTS "Users can add participants" ON chat_participants;
CREATE POLICY "Users can add participants"
  ON chat_participants FOR INSERT
  WITH CHECK (
    -- Kendi kendini ekleyebilir
    (participant_type = 'user' AND participant_id = auth.uid())
    OR
    -- Direct chat oluştururken diğer kullanıcıyı ekleyebilir (odayı oluşturan kişi)
    (
      room_id IN (
        SELECT id FROM chat_rooms 
        WHERE created_by = auth.uid() 
          AND type = 'direct'
      )
    )
    OR
    -- Takım sohbeti için takım üyelerini ekleyebilir (kaptan olarak)
    (
      room_id IN (
        SELECT cr.id FROM chat_rooms cr
        INNER JOIN teams t ON t.id = cr.team_id
        WHERE t.captain_id = auth.uid()
          AND cr.type = 'team_group'
      )
    )
  );

-- ============================================
-- DONE!
-- ============================================
