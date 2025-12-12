-- ============================================
-- CHALLENGER - SUPABASE DATABASE SCHEMA (CLEAN)
-- ============================================
-- Mevcut tabloları silip sıfırdan oluşturur
-- UYARI: Tüm veriler silinecek!
-- ============================================

-- ============================================
-- ÖNCE MEVCUT TABLOLARI VE POLİTİKALARI SİL
-- ============================================

-- Triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
DROP TRIGGER IF EXISTS update_teams_updated_at ON public.teams;

-- Functions
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.handle_updated_at();

-- Storage Policies
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars" ON storage.objects;

-- Table Policies
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;

DROP POLICY IF EXISTS "Teams are viewable by everyone" ON public.teams;
DROP POLICY IF EXISTS "Authenticated users can create teams" ON public.teams;
DROP POLICY IF EXISTS "Captains can update their team" ON public.teams;
DROP POLICY IF EXISTS "Captains can delete their team" ON public.teams;

DROP POLICY IF EXISTS "Team members are viewable by everyone" ON public.team_members;
DROP POLICY IF EXISTS "Captains can add members to their team" ON public.team_members;
DROP POLICY IF EXISTS "Captains can remove members from their team" ON public.team_members;
DROP POLICY IF EXISTS "Users can leave teams" ON public.team_members;

-- Tables (ORDER MATTERS - child tables first)
DROP TABLE IF EXISTS public.team_members CASCADE;
DROP TABLE IF EXISTS public.teams CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- ============================================
-- ŞİMDİ YENİDEN OLUŞTUR
-- ============================================

-- ============================================
-- 1. PROFILES (Kullanıcı Profilleri)
-- ============================================
CREATE TABLE public.profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  full_name text,
  avatar_url text,
  position text CHECK (position IN ('goalkeeper', 'defender', 'midfielder', 'forward')),
  bio text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Profil güncellendiğinde updated_at'i otomatik güncelle
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON public.profiles 
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_updated_at();

-- ============================================
-- 2. TEAMS (Takımlar)
-- ============================================
CREATE TABLE public.teams (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name text NOT NULL,
  captain_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  logo_url text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT team_name_not_empty CHECK (length(trim(name)) > 0)
);

CREATE TRIGGER update_teams_updated_at 
  BEFORE UPDATE ON public.teams 
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_updated_at();

-- ============================================
-- 3. TEAM_MEMBERS (Takım Üyeleri)
-- ============================================
CREATE TABLE public.team_members (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  team_id uuid REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  joined_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(team_id, user_id)
);

-- ============================================
-- ROW LEVEL SECURITY POLİTİKALARI
-- ============================================

-- PROFILES RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by everyone" 
  ON public.profiles FOR SELECT 
  USING (true);

CREATE POLICY "Users can insert their own profile" 
  ON public.profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Users can delete own profile" 
  ON public.profiles FOR DELETE 
  USING (auth.uid() = id);

-- TEAMS RLS
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teams are viewable by everyone" 
  ON public.teams FOR SELECT 
  USING (true);

CREATE POLICY "Authenticated users can create teams" 
  ON public.teams FOR INSERT 
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Captains can update their team" 
  ON public.teams FOR UPDATE 
  USING (auth.uid() = captain_id);

CREATE POLICY "Captains can delete their team" 
  ON public.teams FOR DELETE 
  USING (auth.uid() = captain_id);

-- TEAM_MEMBERS RLS
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Team members are viewable by everyone" 
  ON public.team_members FOR SELECT 
  USING (true);

CREATE POLICY "Captains can add members to their team" 
  ON public.team_members FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.teams 
      WHERE id = team_id AND captain_id = auth.uid()
    )
  );

CREATE POLICY "Captains can remove members from their team" 
  ON public.team_members FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.teams 
      WHERE id = team_id AND captain_id = auth.uid()
    )
  );

CREATE POLICY "Users can leave teams" 
  ON public.team_members FOR DELETE 
  USING (auth.uid() = user_id);

-- ============================================
-- STORAGE BUCKET
-- ============================================
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Avatar images are publicly accessible" 
  ON storage.objects FOR SELECT 
  USING (bucket_id = 'avatars');

CREATE POLICY "Authenticated users can upload avatars" 
  ON storage.objects FOR INSERT 
  WITH CHECK (
    bucket_id = 'avatars' AND 
    auth.role() = 'authenticated'
  );

CREATE POLICY "Users can update their own avatars" 
  ON storage.objects FOR UPDATE 
  USING (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own avatars" 
  ON storage.objects FOR DELETE 
  USING (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id, 
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_teams_captain_id ON public.teams(captain_id);
CREATE INDEX idx_team_members_team_id ON public.team_members(team_id);
CREATE INDEX idx_team_members_user_id ON public.team_members(user_id);
CREATE INDEX idx_profiles_position ON public.profiles(position);

-- ============================================
-- BAŞARILI! ✅
-- ============================================
