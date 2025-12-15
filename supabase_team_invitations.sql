-- =====================================================
-- Team Invitations Migration
-- Challenger App - Supabase
-- Tarih: 15 Aralık 2025
-- =====================================================

-- Team davetleri tablosu
CREATE TABLE IF NOT EXISTS team_invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  invite_code VARCHAR(8) UNIQUE NOT NULL,
  invited_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  status VARCHAR(20) DEFAULT 'pending' 
    CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_invitations_code ON team_invitations(invite_code);
CREATE INDEX IF NOT EXISTS idx_invitations_team ON team_invitations(team_id, status);
CREATE INDEX IF NOT EXISTS idx_invitations_user ON team_invitations(invited_user_id, status);
CREATE INDEX IF NOT EXISTS idx_invitations_expires ON team_invitations(expires_at);

-- Enable RLS
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Herkes davet kodunu kullanarak davet bilgisini görebilir (join için)
CREATE POLICY "Anyone can view invite by code"
  ON team_invitations FOR SELECT
  USING (true);

-- Takım üyeleri (kaptan dahil) davet oluşturabilir
CREATE POLICY "Team members can create invites"
  ON team_invitations FOR INSERT
  WITH CHECK (
    team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
  );

-- Kaptan davetleri güncelleyebilir
CREATE POLICY "Captains can update invites"
  ON team_invitations FOR UPDATE
  USING (
    team_id IN (SELECT id FROM teams WHERE captain_id = auth.uid())
  );

-- Kaptan davetleri silebilir
CREATE POLICY "Captains can delete invites"
  ON team_invitations FOR DELETE
  USING (
    team_id IN (SELECT id FROM teams WHERE captain_id = auth.uid())
  );

-- Function: Rastgele davet kodu üret
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  i INTEGER;
BEGIN
  LOOP
    code := '';
    FOR i IN 1..8 LOOP
      code := code || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    -- Benzersiz olduğundan emin ol
    EXIT WHEN NOT EXISTS (SELECT 1 FROM team_invitations WHERE invite_code = code);
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Function: Süresi dolan davetleri expired yap
CREATE OR REPLACE FUNCTION expire_old_invitations()
RETURNS void AS $$
BEGIN
  UPDATE team_invitations 
  SET status = 'expired', updated_at = NOW()
  WHERE status = 'pending' AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Trigger: updated_at otomatik güncelleme
CREATE OR REPLACE FUNCTION update_invitation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invitation_timestamp
  BEFORE UPDATE ON team_invitations
  FOR EACH ROW
  EXECUTE FUNCTION update_invitation_timestamp();

-- =====================================================
-- KULLANIM ÖRNEKLERİ
-- =====================================================

-- Davet oluştur:
-- INSERT INTO team_invitations (team_id, invite_code, created_by)
-- VALUES ('team-uuid', generate_invite_code(), 'user-uuid');

-- Daveti kabul et:
-- UPDATE team_invitations SET status = 'accepted' WHERE invite_code = 'ABC12345';
-- INSERT INTO team_members (team_id, user_id) VALUES ('team-uuid', 'user-uuid');

-- Süresi dolan davetleri temizle (cron job ile):
-- SELECT expire_old_invitations();
