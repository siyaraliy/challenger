# Mobile App - Clean Architecture Setup

## 📦 Paketler

### State Management & DI
- `flutter_bloc` → State management
- `get_it` → Dependency injection
- `equatable` → Value equality

### Navigation
- `go_router` → Declarative routing

### Database & Cache
- `hive` & `hive_flutter` → Local NoSQL database (Offline-first)
- `supabase_flutter` → Backend-as-a-Service (Dynamic data, Realtime)

### Network & Security
- `dio` → HTTP client
- `flutter_secure_storage` → Secure storage

### UI
- `google_fonts` → Typography

---

## 🏗️ Clean Architecture Yapısı

```
lib/
├── core/
│   ├── bloc/           # Global Bloc Observer
│   ├── cache/          # Static Data Cache (Hive)
│   ├── config/         # Supabase Config
│   ├── di/             # Dependency Injection (GetIt)
│   ├── models/         # Shared Models (Static Data)
│   ├── router/         # App Router (GoRouter)
│   └── theme/          # App Theme
│
└── features/
    ├── auth/           # Authentication feature
    ├── home/           # Home feature
    ├── chat/           # Chat feature
    ├── profile/        # Profile feature
    ├── discover/       # Discover feature
    └── ranking/        # Ranking feature
```

---

## 🎯 Polyglot Persistence (Mobile)

### 1. **Hive** (Local Static Data Cache)
**Kullanım:** Backend'den gelen statik verileri cache'ler
```dart
// Positions, Match Types, Report Reasons
final cache = StaticDataCache();
await cache.cachePositions(positions);
final cachedPositions = cache.getPositions(); // Offline çalışır
```

**Avantajlar:**
- ✅ Offline-first
- ✅ Çok hızlı okuma
- ✅ Değişmeyen veriler için ideal

### 2. **Supabase** (Dynamic Data)
**Kullanım:** Gerçek zamanlı mesajlar, meydan okumalar
```dart
final supabase = Supabase.instance.client;
await supabase.from('messages').select();
```

**Avantajlar:**
- ✅ Realtime subscriptions
- ✅ Auto-sync
- ✅ Built-in auth

### 3. **Flutter Secure Storage** (Sensitive Data)
**Kullanım:** Auth tokens, secrets
```dart
await storage.write(key: 'token', value: token);
```

---

## 🚀 Başlatma

### 1. Paketleri Yükle
```bash
flutter pub get
```

### 2. Hive Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Supabase Konfigürasyonu (Opsiyonel)
`lib/core/config/supabase_config.dart` dosyasını düzenle:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

Veya environment variable kullan:
```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

### 4. Çalıştır
```bash
flutter run
```

---

## 📝 Static Data Cache Kullanımı

### Backend'den Veri Çekme ve Cache'leme
```dart
// 1. Backend'den statik verileri çek
final response = await dio.get('http://localhost:3000/static/all');

// 2. Parse et
final positions = (response.data['data']['positions'] as List)
    .map((e) => Position.fromJson(e))
    .toList();

// 3. Cache'le
await staticDataCache.cachePositions(positions);

// 4. Offline kullan
final cachedPositions = staticDataCache.getPositions();
```

### Offline-First Strateji
```dart
// Önce cache'den oku
if (staticDataCache.hasPositions()) {
  return staticDataCache.getPositions();
}

// Cache yoksa backend'den çek
final positions = await fetchFromBackend();
await staticDataCache.cachePositions(positions);
return positions;
```

---

## 🧪 Test

```bash
# Widget tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart
```

---

## 📊 Veri Akışı

```
Backend (NestJS)
    ↓
Static Data API (/static/*)
    ↓
Mobile App (HTTP Request)
    ↓
StaticDataCache (Hive)
    ↓
UI (Offline-First)
```

---

## ✅ Tamamlanan Setup

- ✅ Clean Architecture klasör yapısı
- ✅ Hive adapters ve models
- ✅ StaticDataCache servisi
- ✅ Supabase initialization
- ✅ Offline-first cache stratejisi
- ✅ Environment-based configuration

---

## 🔜 Sonraki Adımlar

1. Static data sync servisi oluştur
2. Network layer ekle (Dio interceptors)
3. Error handling middleware
4. Auth flow'u Supabase ile entegre et
