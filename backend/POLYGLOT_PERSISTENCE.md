# Polyglot Persistence Architecture

Bu projede **Çoklu Veritabanı (Polyglot Persistence)** mimarisi kullanılmaktadır. Her veri tipi için en uygun depolama çözümü seçilmiştir:

## 📊 Veritabanı Mimarisi

### 1. **PostgreSQL** (İlişkisel Veri)
- **Kullanım:** Kullanıcı profilleri, takım bilgileri (TypeORM ile)
- **Avantaj:** ACID uyumlu, karmaşık sorgular, veri bütünlüğü
- **Lokasyon:** `src/users/`, `src/teams/`

### 2. **Supabase** (Dinamik Veri)
- **Kullanım:** Gerçek zamanlı mesajlar, meydan okumalar, canlı veri
- **Avantaj:** Realtime subscriptions, otomatik API, storage
- **Servis:** `SupabaseService` (`src/supabase/`)

**Kullanım Örneği:**
```typescript
constructor(private readonly supabaseService: SupabaseService) {}

async getMessages() {
  const { data } = await this.supabaseService.messages
    .select('*')
    .order('created_at', { ascending: false });
  return data;
}
```

### 3. **Redis** (Geçici/Cache Veri)
- **Kullanım:** Session, meydan okuma sayaçları (TTL), cache
- **Avantaj:** Çok hızlı, TTL desteği, pub/sub
- **Servis:** `RedisService` (`src/redis/`)

**Kullanım Örneği:**
```typescript
// Meydan okuma süresi (1 saat)
await this.redisService.set('challenge:123', 'active', 3600);
```

### 4. **JSON Dosyası** (Statik Veri)
- **Kullanım:** Pozisyonlar, maç tipleri, şikayet sebepleri
- **Avantaj:** Değişmez veriler, hızlı okuma, deployment kolay
- **Servis:** `StaticDataService` (`src/static-data/`)
- **Dosya:** `src/data/constants.json`

**Kullanım Örneği:**
```typescript
const positions = this.staticDataService.getAllPositions();
// [{ id: 'goalkeeper', name: 'Kaleci', ... }]
```

---

## 🧪 Test Endpoint'leri

### Static Data (JSON)
```bash
# Tüm pozisyonlar
GET http://localhost:3000/static/positions

# Tüm maç tipleri
GET http://localhost:3000/static/match-types

# Şikayet sebepleri
GET http://localhost:3000/static/report-reasons

# Tüm statik veriler
GET http://localhost:3000/static/all
```

---

## 🔧 Environment Değişkenleri

`.env` dosyanıza şunları ekleyin:

```env
# Supabase (Dynamic DB)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key
```

---

## 📁 Proje Yapısı

```
src/
├── supabase/           # Supabase module (Dynamic DB)
│   ├── supabase.service.ts
│   └── supabase.module.ts
├── static-data/        # Static data module
│   ├── static-data.service.ts
│   └── static-data.module.ts
├── data/
│   └── constants.json  # Statik veriler
├── redis/              # Redis module
└── users/              # PostgreSQL entities
```

---

## 🎯 Veri Seçim Rehberi

| Veri Tipi | Veritabanı | Sebep |
|-----------|------------|-------|
| Kullanıcı profilleri | PostgreSQL | İlişkisel, ACID |
| Mesajlar | Supabase | Realtime, dinamik |
| Challenge sayaçlar | Redis | TTL, hız |
| Pozisyonlar | JSON | Statik, deployment |
| Match history | PostgreSQL | Analiz, sorgulama |
| Session | Redis | Geçici, hızlı |

---

## 🚀 Başlatma

```bash
# PostgreSQL ve Redis
docker-compose up -d

# Backend
npm run start:dev
```

Logları kontrol et:
- `[RedisService] Redis connected successfully`
- `[SupabaseService] Supabase client initialized successfully`
