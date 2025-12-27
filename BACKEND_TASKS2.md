# Challenger - Backend Implementation Tasks (FAZ 4)

**Hazırlanma Tarihi:** 27 Aralık 2024  
**Hedef:** Backend ekibi için FAZ 4 görev listesi  
**Frontend Durumu:** 🔄 UI hazır (bazı özellikler aktive edilmeli)

---

## 🎯 Öncelik Sıralaması (Kullanıcı Sırasına Göre)

### 🔴 Yüksek Öncelik - Gönderi Özellikleri (1 hafta)
1. Post Yorumları Aktif Hale Getirme
2. Gönderi Paylaşma (Share Posts)
3. Video Auto-Play & Sınırlamalar

### 🟡 Orta Öncelik (1 hafta)
4. Takım Üyelik Limitleri
5. Takım Mesajlaşma Genişletme

### 🟢 Düşük Öncelik (3 gün)
6. Takip (Follow) Sistemi

---

## 1. Post Yorumları Aktif Hale Getirme (🔴 2 gün)

### Mevcut Durum
- ✅ `post_comments` tablosu Supabase'de mevcut
- ❌ Frontend'de yorum butonu tıklanınca modal/sayfa açılmıyor
- ❌ Yorum atma işlemi aktif değil

### Backend Tasks

#### 1.1 Mevcut API Kontrol/Düzelt
```typescript
// API Endpoints Kontrol Et (NestJS)
GET /posts/:id/comments
  Query: { limit: 20, offset: 0 }
  Response: [{ 
    id, 
    userId, 
    userName, 
    userAvatar,
    content, 
    createdAt 
  }]

POST /posts/:id/comments
  Body: { content: string }
  Headers: { Authorization }
  Response: { 
    comment: { id, userId, content, createdAt }
  }

DELETE /posts/:id/comments/:commentId
  Response: { success: true }
```

#### 1.2 RLS Politikaları (Mevcut, Kontrol Et)
```sql
-- post_comments tablosu için mevcut politikaları kontrol et
-- Yorumlar herkes tarafından okunabilir
-- Kullanıcılar yorum ekleyebilir
-- Kullanıcılar kendi yorumlarını silebilir
```

#### 1.3 Frontend Integration (Notlar)
- `PostCard` widget'ında yorum butonuna tıklanınca `CommentsBottomSheet` veya `CommentsScreen` açılmalı
- Yorumlar lazy-load ile yüklenmeli (pagination)
- Real-time yorum güncellemesi için Supabase Realtime kullanılabilir (opsiyonel)

---

## 2. Gönderi Paylaşma (Share Posts) (🔴 2 gün)

### Gereksinimler
- Kullanıcılar başkalarının gönderilerini paylaşabilir
- Paylaşma butonuna basınca kişi/takım seçim ekranı açılır
- Paylaşım uygulama içi mesaj olarak gönderilir

### Backend Tasks

#### 2.1 Share as Message
```typescript
POST /posts/:id/share
  Body: { 
    recipientType: 'user' | 'team',
    recipientId: UUID 
  }
  Headers: { Authorization }
  
  // Logic:
  // 1. Alıcı ile mevcut sohbet odasını bul veya oluştur
  // 2. Özel mesaj tipi ile gönderi paylaş
  
  Response: { 
    success: true, 
    messageId: UUID,
    roomId: UUID 
  }
```

#### 2.2 Message Type için Genişletme
```sql
-- chat_messages tablosuna shared_post_id ekle
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS shared_post_id UUID REFERENCES posts(id) ON DELETE SET NULL;

-- Message type'a 'post_share' ekle
-- (mevcut check constraint güncellenmeli)
ALTER TABLE chat_messages 
DROP CONSTRAINT IF EXISTS chat_messages_message_type_check;

ALTER TABLE chat_messages 
ADD CONSTRAINT chat_messages_message_type_check 
CHECK (message_type IN ('text', 'image', 'video', 'system', 'post_share'));
```

#### 2.3 Frontend Integration (Notlar)
- Share butonuna tıklayınca `ShareBottomSheet` açılır
- Son mesajlaşılan kişiler listesi görünür
- Arama ile kullanıcı/takım bulunabilir
- Paylaşınca chat ekranına yönlendirme opsiyonel

---

## 3. Video Auto-Play & Sınırlamalar (🔴 3 gün)

### Gereksinimler
- Videolar Instagram gibi görünür görünmez otomatik oynasın (ses kapalı)
- Video max **60 saniye** (1 dakika)
- Video max **500MB** (Supabase Free Plan limiti)
- Kullanıcı videoya tıklamak zorunda kalmasın

### Backend Tasks

#### 3.1 Video Upload Validasyonu
```typescript
// Backend Video Validation (NestJS)
POST /posts
  Body: FormData { 
    content: string, 
    mediaFile: File,
    mediaType: 'video'
  }
  
  // Server-side Validations:
  // 1. Max file size: 500MB (Supabase free plan storage limit için optimum)
  // 2. Max duration: 60 seconds
  // 3. Allowed formats: mp4, mov, webm
  
  // Validation Logic:
  async validateVideo(file: File) {
    const MAX_SIZE_MB = 500;
    const MAX_DURATION_SECONDS = 60;
    
    // Check file size
    if (file.size > MAX_SIZE_MB * 1024 * 1024) {
      throw new BadRequestException('Video boyutu maksimum 500MB olmalı');
    }
    
    // Check duration (requires ffprobe or similar)
    const duration = await getVideoDuration(file);
    if (duration > MAX_DURATION_SECONDS) {
      throw new BadRequestException('Video süresi maksimum 60 saniye olmalı');
    }
  }
```

#### 3.2 Video Metadata Extraction
```typescript
// Video duration kontrolü için
import * as ffprobe from 'ffprobe';
import * as ffprobeStatic from 'ffprobe-static';

async getVideoDuration(filePath: string): Promise<number> {
  const info = await ffprobe(filePath, { path: ffprobeStatic.path });
  const videoStream = info.streams.find(s => s.codec_type === 'video');
  return parseFloat(videoStream.duration);
}
```

#### 3.3 Frontend Integration (Notlar)
- `video_player` paketi ile auto-play implementasyonu
- `visibility_detector` paketi ile görünürlük takibi
- Ses varsayılan olarak kapalı başlamalı
- Kullanıcı videoya tıklayınca tam ekran + ses açık

```dart
// Video Player Configuration (Flutter - Referans)
VideoPlayerController.network(mediaUrl)
  ..initialize()
  ..setVolume(0) // Ses kapalı
  ..setLooping(true) // Loop
  ..play(); // Auto-play
```

---

## 4. Takım Üyelik Limitleri (� 1 gün)

### Gereksinimler
- Bir kullanıcı **maksimum 1 takımın kaptanı** olabilir
- Bir kullanıcı **maksimum 2 takıma üye** olabilir

### Backend Tasks

#### 4.1 Database Constraints - Kaptan Limiti
```sql
-- Kaptan limiti için constraint
CREATE OR REPLACE FUNCTION check_captain_limit()
RETURNS TRIGGER AS $$
DECLARE
  captain_count INT;
BEGIN
  SELECT COUNT(*) INTO captain_count
  FROM teams
  WHERE captain_id = NEW.captain_id;
  
  IF captain_count >= 1 AND TG_OP = 'INSERT' THEN
    RAISE EXCEPTION 'Kullanıcı maksimum 1 takımın kaptanı olabilir';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_captain_limit_trigger
  BEFORE INSERT ON teams
  FOR EACH ROW
  EXECUTE FUNCTION check_captain_limit();
```

#### 4.2 Database Constraints - Üyelik Limiti
```sql
-- Üyelik limiti için constraint
CREATE OR REPLACE FUNCTION check_membership_limit()
RETURNS TRIGGER AS $$
DECLARE
  membership_count INT;
BEGIN
  SELECT COUNT(*) INTO membership_count
  FROM team_members
  WHERE user_id = NEW.user_id;
  
  IF membership_count >= 2 THEN
    RAISE EXCEPTION 'Kullanıcı maksimum 2 takıma üye olabilir';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_membership_limit_trigger
  BEFORE INSERT ON team_members
  FOR EACH ROW
  EXECUTE FUNCTION check_membership_limit();
```

#### 4.3 API Validation
```typescript
// POST /teams (Takım oluşturma)
async createTeam(userId: string, data: CreateTeamDto) {
  // Backend'de de kontrol
  const captainCount = await this.teamsRepo.count({
    where: { captain_id: userId }
  });
  
  if (captainCount >= 1) {
    throw new BadRequestException('Maksimum 1 takımın kaptanı olabilirsiniz');
  }
}

// POST /teams/:id/join (Takıma katılma)
async joinTeam(userId: string, teamId: string) {
  const membershipCount = await this.teamMembersRepo.count({
    where: { user_id: userId }
  });
  
  if (membershipCount >= 2) {
    throw new BadRequestException('Maksimum 2 takıma üye olabilirsiniz');
  }
}
```

---

## 5. Takım Mesajlaşma Genişletme (🟡 3 gün)

### Mevcut Durum
- ✅ Takım sohbeti (team_group chat) çalışıyor
- ❌ Takım hesabı sadece takım sohbetinde konuşabiliyor
- ❌ Takım hesabından başka kullanıcı/takımlara mesaj atılamıyor

### Gereksinimler
- Takım hesabı ile direct message atılabilmeli
- Takım hesabı ile başka takımlara mesaj atılabilmeli

### Backend Tasks

#### 5.1 Takım Direct Chat Desteği
```typescript
POST /chats/direct
  Body: { 
    targetType: 'user' | 'team',
    targetId: UUID 
  }
  Headers: { 
    Authorization: "Bearer <token>",
    "X-Context-Type": "team",  // Takım modunda ise
    "X-Context-Id": "<team_id>"
  }
  
  // Logic:
  // 1. Context'e göre sender belirle (user veya team)
  // 2. Direct chat room oluştur veya mevcut olanı bul
  // 3. Katılımcıları ekle
  
  Response: { roomId: UUID }
```

#### 5.2 Chat Participants Güncellemesi
```sql
-- Mevcut chat_participants tablosu zaten participant_type destekliyor
-- 'user' veya 'team' olabilir

-- Takımın başka takıma mesaj atması için:
-- room oluşturulurken her iki takım da participant olarak eklenir
-- type: 'direct' (takım-takım için de direct kullanılacak)
```

#### 5.3 RLS Policy Güncellemesi
```sql
-- Takım üyeleri takım adına chat işlemleri yapabilsin
CREATE POLICY "Team members can send as team"
  ON chat_messages FOR INSERT
  WITH CHECK (
    (sender_type = 'user' AND sender_id = auth.uid())
    OR
    (sender_type = 'team' AND sender_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid()
    ))
  );

-- Takım chat'lerini görüntüleme
CREATE POLICY "Team members can view team chats"
  ON chat_rooms FOR SELECT
  USING (
    id IN (
      SELECT room_id FROM chat_participants 
      WHERE 
        (participant_type = 'user' AND participant_id = auth.uid())
        OR
        (participant_type = 'team' AND participant_id IN (
          SELECT team_id FROM team_members WHERE user_id = auth.uid()
        ))
    )
  );
```

---

## 6. Takip (Follow) Sistemi (🟢 3 gün)

### Gereksinimler
- Kullanıcılar birbirini takip edebilir
- Takipçi/Takip sayıları profilte görünür
- Feed'de takip edilen kişilerin gönderileri öncelikli

### Backend Tasks

#### 6.1 Database Schema (Yeni Tablo)
```sql
-- =============================================
-- FOLLOWS TABLE (Yeni Oluşturulacak)
-- =============================================
CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)  -- Kendi kendini takip edemez
);

-- Indexes
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- RLS Enable
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Follows are viewable by everyone"
  ON follows FOR SELECT
  USING (true);

CREATE POLICY "Users can follow others"
  ON follows FOR INSERT
  WITH CHECK (follower_id = auth.uid());

CREATE POLICY "Users can unfollow"
  ON follows FOR DELETE
  USING (follower_id = auth.uid());
```

#### 6.2 Profiles Tablosuna Sayaç Ekleme
```sql
-- Profil tablosuna sayaçlar ekle
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS followers_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS following_count INT DEFAULT 0;

-- Trigger: Takip edildiğinde sayaçları güncelle
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Takipçi sayısını artır
    UPDATE profiles SET followers_count = followers_count + 1 
    WHERE id = NEW.following_id;
    -- Takip sayısını artır
    UPDATE profiles SET following_count = following_count + 1 
    WHERE id = NEW.follower_id;
  ELSIF TG_OP = 'DELETE' THEN
    -- Takipçi sayısını azalt
    UPDATE profiles SET followers_count = GREATEST(followers_count - 1, 0) 
    WHERE id = OLD.following_id;
    -- Takip sayısını azalt
    UPDATE profiles SET following_count = GREATEST(following_count - 1, 0) 
    WHERE id = OLD.follower_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_update_follow_counts
  AFTER INSERT OR DELETE ON follows
  FOR EACH ROW
  EXECUTE FUNCTION update_follow_counts();
```

#### 6.3 API Endpoints
```typescript
POST /users/:id/follow
  Headers: { Authorization }
  Response: { success: true, following: true }

DELETE /users/:id/follow
  Headers: { Authorization }
  Response: { success: true, following: false }

GET /users/:id/followers
  Query: { limit: 20, offset: 0 }
  Response: [{ id, fullName, avatarUrl, isFollowing }]

GET /users/:id/following
  Query: { limit: 20, offset: 0 }
  Response: [{ id, fullName, avatarUrl, isFollowing }]

GET /users/:id/follow-status
  // Mevcut kullanıcının bu kişiyi takip edip etmediği
  Response: { isFollowing: boolean }
```

---

## 🔧 Genel Gereksinimler

### Video Processing Dependency (FFmpeg)
```bash
# Backend için video süre kontrolü gerekli
npm install fluent-ffmpeg @ffprobe-installer/ffprobe

# Veya Docker container'da:
RUN apt-get update && apt-get install -y ffmpeg
```

### Storage Limits (Supabase Free Plan)
- **Toplam Storage:** 1GB
- **Bandwidth:** 2GB/ay
- **Önerilen Video Boyutu:** Max 500MB (tek video için güvenli sınır)
- **Önerilen Resim Boyutu:** Max 10MB

---

## ✅ Teslim Kriterleri

### Her Feature İçin:
1. ✅ Database migration SQL dosyası hazır
2. ✅ API endpointleri test edildi (Postman/Insomnia)
3. ✅ RLS policies aktif ve test edildi
4. ✅ Error handling mevcut (Türkçe hata mesajları)
5. ✅ Frontend'e bilgi verildi

---

## 📋 Özet Checklist

| # | Özellik | Öncelik | Süre | Durum |
|---|---------|---------|------|-------|
| 1 | Post Yorumları Aktifleştirme | 🔴 | 2 gün | ⬜ |
| 2 | Gönderi Paylaşma | 🔴 | 2 gün | ⬜ |
| 3 | Video Auto-Play & Limits | 🔴 | 3 gün | ⬜ |
| 4 | Takım Üyelik Limitleri | 🟡 | 1 gün | ⬜ |
| 5 | Takım Mesajlaşma Genişletme | 🟡 | 3 gün | ⬜ |
| 6 | Takip (Follow) Sistemi | 🟢 | 3 gün | ⬜ |

**Toplam Tahmini Süre:** 2 hafta

---

## 📞 İletişim

**Frontend Lead:** Mahmut  
**Backend Team:** TBD  
**Database:** Supabase (qzbmodnznfdtjyietjie)

---

**Son Güncelleme:** 27 Aralık 2024
