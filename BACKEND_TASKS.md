# Challenger - Backend Implementation Tasks

**Hazırlanma Tarihi:** 12 Aralık 2024  
**Hedef:** Backend ekibi için görev listesi  
**Frontend Durumu:** ✅ UI hazır (mock data ile)

---

## 🎯 Öncelik Sıralaması

### 🔴 Yüksek Öncelik (2-3 hafta)
1. Team Authentication System
2. Post Feed System
3. Challenge System

### 🟡 Orta Öncelik (1-2 hafta)
4. Team Invitations
5. Leaderboard & Stats

### 🟢 Düşük Öncelik (1 hafta)
6. Chat System (Supabase Realtime)

---

## 1. Team Authentication System (🔴 2 hafta)

### Gereksinimler
- Takımın kendi email/şifresi olacak
- Birden fazla kullanıcı aynı takım credential ile login yapabilecek
- Her kullanıcı kendi user hesabı ile login olduktan sonra, takım hesabına geçebilecek

### Backend Tasks

#### 1.1 Database Schema (Supabase)
```sql
-- Team credentials
CREATE TABLE team_credentials (
  team_id UUID PRIMARY KEY REFERENCES teams(id) ON DELETE CASCADE,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Team sessions (hangi user hangi takıma login olmuş)
CREATE TABLE team_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  active BOOLEAN DEFAULT TRUE,
  logged_in_at TIMESTAMPTZ DEFAULT NOW(),
  last_activity TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(team_id, user_id)
);

-- team_members güncelleme
ALTER TABLE team_members 
ADD COLUMN can_login BOOLEAN DEFAULT TRUE;

-- RLS Policies
CREATE POLICY "Captains manage credentials"
  ON team_credentials FOR ALL
  USING (team_id IN (
    SELECT id FROM teams WHERE captain_id = auth.uid()
  ));

CREATE POLICY "Members view sessions"
  ON team_sessions FOR SELECT
  USING (
    team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
  );
```

#### 1.2 API Endpoints (NestJS)
```typescript
POST /auth/team/register
  Body: { teamName, email, password }
  Headers: { Authorization: "Bearer <user_token>" }
  Response: { team, credentials }

POST /auth/team/login
  Body: { email, password }
  Headers: { Authorization: "Bearer <user_token>" }
  Response: { teamToken, team }
  
  // teamToken JWT içeriği:
  {
    sub: userId,
    contextType: 'team',
    contextId: teamId
  }

POST /auth/team/logout
  Headers: { Authorization: "Bearer <team_token>" }
  Response: { success: true }

GET /auth/team/sessions/:teamId
  // Takımın aktif sessionlarını listele
  Response: [{ userId, userName, loggedInAt }]
```

#### 1.3 Frontend Integration (Notlar)
- Frontend hazır (UI mevcut)
- API endpointleri implement edildikten sonra bağlanacak
- Mock data yerine gerçek API çağrıları yapılacak

---

## 2. Post Feed System (🔴 1 hafta)

### Gereksinimler
- Kullanıcılar ve takımlar gönderi atabilecek (text + resim + video)
- Like, yorum özelliği
- Ana sayfada feed görüntülenecek
- **Video max 60 saniye, max 50MB**
- **Resim max 10MB**

### Backend Tasks

#### 2.1 Database Schema
```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_type VARCHAR(10) CHECK (author_type IN ('user', 'team')),
  author_id UUID NOT NULL,
  content TEXT NOT NULL CHECK (length(content) <= 500),
  media_type VARCHAR(10) CHECK (media_type IN ('image', 'video', 'none')),
  media_url TEXT,  -- Supabase Storage URL
  media_thumbnail_url TEXT,  -- Video thumbnail
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE post_likes (
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (post_id, user_id)
);

CREATE TABLE post_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (length(content) <= 200),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_posts_author ON posts(author_type, author_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_post_likes_post ON post_likes(post_id);
```

#### 2.2 API Endpoints
```typescript
GET /posts/feed
  Query: { limit: 20, offset: 0, mode: 'user' | 'team', contextId?: string }
  Response: [{ 
    id, 
    authorType, 
    authorId, 
    content, 
    mediaType,
    mediaUrl, 
    mediaThumbnailUrl,
    likesCount, 
    commentsCount, 
    createdAt 
  }]

POST /posts
  Body: FormData { 
    content: string, 
    mediaFile?: File,  // image OR video
    mediaType?: 'image' | 'video'
  }
  Headers: { Authorization, X-Context-Type, X-Context-Id }
  // Validations:
  // - Image: max 10MB, formats: jpg, png, gif
  // - Video: max 50MB, max 60 seconds, formats: mp4, mov
  Response: { post }

POST /posts/:id/like
  Response: { success, liked: boolean }

DELETE /posts/:id/like
  Response: { success }

GET /posts/:id/comments
  Query: { limit, offset }
  Response: [{ id, userId, userName, content, createdAt }]

POST /posts/:id/comments
  Body: { content }
  Response: { comment }
```

#### 2.3 Storage
```
Supabase Storage bucket: posts/
  ├── images/[author_type]/[author_id]/[timestamp].jpg
  ├── videos/[author_type]/[author_id]/[timestamp].mp4
  └── thumbnails/[author_type]/[author_id]/[timestamp]_thumb.jpg
```

#### 2.4 Video Processing
```typescript
// Video yüklendiğinde:
1. Validate: max 60 saniye, max 50MB
2. Upload to Supabase Storage
3. Generate thumbnail (first frame)
4. Save thumbnail URL to media_thumbnail_url
```

---

## 3. Challenge System (🔴 1 hafta)

### Gereksinimler
- Takımlar birbirine meydan okuma gönderebilecek
- Maç yapılınca otomatik puan eklenecek (skor girilmeyecek!)
- Challenge status: pending, accepted, rejected, completed

### Backend Tasks

#### 3.1 Database Schema
```sql
CREATE TABLE challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  challenger_team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  challenged_team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending' 
    CHECK (status IN ('pending', 'accepted', 'rejected', 'completed')),
  match_date TIMESTAMPTZ,
  location TEXT,
  points_awarded INT DEFAULT 0,  -- Maç tamamlandığında puan
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Team points table
CREATE TABLE team_points (
  team_id UUID PRIMARY KEY REFERENCES teams(id) ON DELETE CASCADE,
  total_points INT DEFAULT 0,
  matches_played INT DEFAULT 0,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_challenges_challenger ON challenges(challenger_team_id, status);
CREATE INDEX idx_challenges_challenged ON challenges(challenged_team_id, status);
```

#### 3.2 API Endpoints
```typescript
POST /challenges
  Body: { challengedTeamId, matchDate, location }
  Headers: { Authorization (team context) }
  Response: { challenge }

GET /challenges/incoming
  // Takıma gelen challengelar
  Response: [{ id, challengerTeamId, matchDate, location, status }]

GET /challenges/outgoing
  // Takımın gönderdiği challengelar
  Response: [{ id, challengedTeamId, matchDate, location, status }]

PATCH /challenges/:id/accept
  Response: { challenge }

PATCH /challenges/:id/reject
  Response: { challenge }

PATCH /challenges/:id/complete
  // Maç tamamlandı, otomatik puan ekle
  // İKİ TAKIMA DA 100 PUAN EKLENECEK (skor yok!)
  Response: { challenge, pointsAwarded: 100 }
```

#### 3.3 Business Logic
```typescript
// Maç tamamlandığında:
async completeChallenge(challengeId) {
  const challenge = await findChallenge(challengeId);
  
  // Her iki takıma da otomatik puan ekle
  await addPoints(challenge.challengerTeamId, 100);
  await addPoints(challenge.challengedTeamId, 100);
  
  // Challenge'ı completed yap
  await updateChallengeStatus(challengeId, 'completed', 100);
}
```

---

## 4. Team Invitations (🟡 4 gün)

### Backend Tasks

#### 4.1 Database Schema
```sql
CREATE TABLE team_invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  invite_code VARCHAR(8) UNIQUE NOT NULL,
  invited_user_id UUID REFERENCES profiles(id),  -- Opsiyonel
  status VARCHAR(20) DEFAULT 'pending',
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_invitations_code ON team_invitations(invite_code);
CREATE INDEX idx_invitations_user ON team_invitations(invited_user_id, status);
```

#### 4.2 API Endpoints
```typescript
POST /teams/:id/invites/generate
  Response: { inviteCode, expiresAt }

POST /teams/join/:inviteCode
  Headers: { Authorization (user) }
  Response: { team, member }

GET /invites/my
  // Kullanıcıya gelen davetler
  Response: [{ id, teamId, teamName, expiresAt }]

PATCH /invites/:id/accept
  Response: { team }

PATCH /invites/:id/reject
  Response: { success }
```

---

## 5. Leaderboard & Stats (🟡 3 gün)

### Backend Tasks

#### 5.1 Database Views
```sql
CREATE VIEW team_rankings AS
SELECT 
  t.id,
  t.name,
  t.logo_url,
  tp.total_points,
  tp.matches_played,
  tp.wins,
  tp.losses,
  COUNT(DISTINCT tm.user_id) as member_count,
  ROW_NUMBER() OVER (ORDER BY tp.total_points DESC) as rank
FROM teams t
LEFT JOIN team_points tp ON t.id = tp.team_id
LEFT JOIN team_members tm ON t.id = tm.team_id
GROUP BY t.id, t.name, t.logo_url, tp.total_points, tp.matches_played, tp.wins, tp.losses
ORDER BY tp.total_points DESC;
```

#### 5.2 API Endpoints
```typescript
GET /leaderboard/teams
  Query: { limit: 50 }
  Response: [{ rank, teamId, name, points, matchesPlayed, wins, losses, memberCount }]

GET /stats/team/:id
  Response: { 
    points, 
    matchesPlayed, 
    wins, 
    losses, 
    rank,
    recentChallenges: [...] 
  }
```

---

## 6. Chat System (🟢 1 hafta) - Supabase Realtime

### Backend Tasks

#### 6.1 Database Schema
```sql
CREATE TABLE chat_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type VARCHAR(20) CHECK (type IN ('direct', 'team_group')),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,  -- team_group ise
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE chat_participants (
  room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
  participant_type VARCHAR(10) CHECK (participant_type IN ('user', 'team')),
  participant_id UUID,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (room_id, participant_type, participant_id)
);

CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_type VARCHAR(10),
  sender_id UUID,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
```

#### 6.2 API Endpoints
```typescript
GET /chats/my
  Response: [{ roomId, type, lastMessage, participants }]

POST /chats/direct
  Body: { userId }
  Response: { room }

POST /chats/:roomId/messages
  Body: { content }
  Response: { message }

GET /chats/:roomId/messages
  Query: { limit, offset }
  Response: [{ id, senderId, content, createdAt }]
```

#### 6.3 Realtime Setup
Frontend Supabase Realtime ile dinleyecek:
```dart
supabase
  .from('chat_messages')
  .stream(primaryKey: ['id'])
  .eq('room_id', roomId)
  .listen((messages) { ... });
```

---

## 🔧 Genel Gereksinimler

### Context Middleware
```typescript
@Injectable()
export class ContextMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const token = req.headers.authorization;
    const payload = verifyJWT(token);
    
    req.context = {
      type: payload.contextType || 'user',
      id: payload.contextId || payload.sub,
      userId: payload.sub
    };
    
    next();
  }
}
```

### Environment Variables
```env
SUPABASE_URL=https://qzbmodnznfdtjyietjie.supabase.co
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_KEY=...
JWT_SECRET=...
```

---

## ✅ Teslim Kriterleri

### Her Feature İçin:
1. ✅ Database migration çalıştırıldı
2. ✅ API endpointleri test edildi (Postman/Insomnia)
3. ✅ RLS policies aktif
4. ✅ Error handling mevcut
5. ✅ API documentation (Swagger)

---

## 📝 Notlar

- **Frontend hazır:** Tüm UI mocklar ile çalışıyor
- **Supabase kullanılacak:** PostgreSQL + Realtime + Storage
- **Puan sistemi:** Maç tamamlandığında otomatik puan (skor yok!)
- **Team authentication:** Öncelik 1, diğer featurelar buna bağımlı

---

## 📞 İletişim

**Frontend Lead:** Mahmut  
**Backend Team:** TBD  
**Database:** Supabase (qzbmodnznfdtjyietjie)

---

**Son Güncelleme:** 12 Aralık 2024
