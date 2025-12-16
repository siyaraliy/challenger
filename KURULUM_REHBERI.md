# 🚀 CHALLENGER - Kurulum Rehberi

**Son Güncelleme:** 15 Aralık 2025  
**Hedef Kitle:** Takım Arkadaşları

Bu rehber, Challenger projesini sıfırdan kendi bilgisayarınızda çalıştırmanız için gereken tüm adımları içerir.

---

## 📋 İçindekiler

1. [Gereksinimler](#1-gereksinimler)
2. [Projeyi Klonlama](#2-projeyi-klonlama)
3. [Backend Kurulumu](#3-backend-kurulumu)
4. [Mobile Kurulumu](#4-mobile-kurulumu)
5. [Supabase Konfigürasyonu](#5-supabase-konfigürasyonu)
6. [Uygulamayı Çalıştırma](#6-uygulamayı-çalıştırma)
7. [Sorun Giderme](#7-sorun-giderme)

---

## 1. Gereksinimler

### 1.1 Zorunlu Yazılımlar

| Yazılım | Minimum Versiyon | İndirme Linki |
|---------|------------------|---------------|
| **Git** | 2.40+ | [git-scm.com](https://git-scm.com/downloads) |
| **Node.js** | 18.x veya 20.x | [nodejs.org](https://nodejs.org/) |
| **Flutter** | 3.10+ | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| **Docker Desktop** | 4.20+ | [docker.com](https://www.docker.com/products/docker-desktop/) |
| **VS Code** veya **Android Studio** | En güncel | [code.visualstudio.com](https://code.visualstudio.com/) |

### 1.2 Versiyon Kontrolü

Terminalde bu komutları çalıştırarak versiyonlarınızı kontrol edin:

```bash
# Git versiyonu
git --version

# Node.js versiyonu
node --version

# npm versiyonu
npm --version

# Flutter versiyonu
flutter --version

# Docker versiyonu
docker --version
```

### 1.3 Flutter Kurulum Doğrulaması

```bash
flutter doctor
```

**Beklenen Çıktı:**
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Windows Version
[✓] Android toolchain
[✓] Chrome - develop for the web
[✓] Visual Studio - develop Windows apps
[✓] Android Studio
[✓] VS Code
[✓] Connected device
```

> ⚠️ **Önemli:** Tüm satırların `[✓]` ile başlaması gerekir. `[✗]` veya `[!]` görürseniz, Flutter'ın önerdiği düzeltmeleri yapın.

---

## 2. Projeyi Klonlama

### 2.1 Git Clone

```bash
# İstediğiniz klasöre gidin
cd C:\Users\KULLANICI_ADINIZ\Documents

# Projeyi klonlayın
git clone https://github.com/REPO_URL/challenger.git

# Proje klasörüne girin
cd challenger
```

### 2.2 Branch Kontrolü

```bash
# Mevcut branch'i kontrol edin
git branch

# Main branch'e geçin (gerekirse)
git checkout main

# En son değişiklikleri çekin
git pull origin main
```

---

## 3. Backend Kurulumu

### 3.1 Docker Servislerini Başlatma

> ⚠️ **Önce Docker Desktop'ı açın ve çalıştığından emin olun!**

```bash
# Proje ana dizininde
cd challenger

# PostgreSQL ve Redis container'larını başlatın
docker-compose up -d
```

**Başarılı çıktı:**
```
[+] Running 3/3
 ✔ Network challenger_net       Created
 ✔ Container challenger_redis   Started
 ✔ Container challenger_postgres Started
```

### 3.2 Container Durumunu Kontrol Etme

```bash
docker ps
```

**Beklenen çıktı:**
```
CONTAINER ID   IMAGE              STATUS          PORTS
xxxx           postgres:16-alpine Up 5 minutes    0.0.0.0:5432->5432/tcp
xxxx           redis:7-alpine     Up 5 minutes    0.0.0.0:6379->6379/tcp
```

### 3.3 Backend Bağımlılıklarını Yükleme

```bash
# Backend klasörüne gidin
cd backend

# npm paketlerini yükleyin
npm install
```

> 💡 Bu işlem 2-5 dakika sürebilir.

### 3.4 Environment Dosyasını Oluşturma

```bash
# .env.example dosyasını kopyalayın
copy .env.example .env
```

**Veya manuel olarak `backend/.env` dosyası oluşturun:**

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=challenger_user
DB_PASSWORD=challenger_password
DB_NAME=challenger_db

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# Supabase Configuration (Dynamic DB)
SUPABASE_URL=https://qzbmodnznfdtjyietjie.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6Ym1vZG56bmZkdGp5aWV0amllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0ODIwNTEsImV4cCI6MjA4MTA1ODA1MX0.pX9yRNZxVmvskG9YjlBePKqkmOQMKLtLz1ThG5fZsDI
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# JWT Configuration
JWT_SECRET=challenger-secret-key-2025
JWT_EXPIRATION=7d
```

### 3.5 Backend'i Başlatma

```bash
# Development modunda başlat
npm run start:dev
```

**Başarılı çıktı:**
```
[Nest] LOG [NestFactory] Starting Nest application...
[Nest] LOG [InstanceLoader] AppModule dependencies initialized +xxms
[Nest] LOG [RoutesResolver] AppController {/}: +xxms
[Nest] LOG [NestApplication] Nest application successfully started +xxms
```

> ✅ Backend şu adreste çalışacak: `http://localhost:3000`

### 3.6 Backend Test

Tarayıcınızda açın:
- `http://localhost:3000` → "Hello World!" görmelisiniz
- `http://localhost:3000/static/all` → Statik verileri görmelisiniz

---

## 4. Mobile Kurulumu

### 4.1 Flutter Bağımlılıklarını Yükleme

```bash
# Mobile klasörüne gidin
cd mobile

# Flutter paketlerini yükleyin
flutter pub get
```

### 4.2 Hive Code Generation

```bash
# Hive adapters için kod üretin
dart run build_runner build --delete-conflicting-outputs
```

> 💡 Bu işlem 1-2 dakika sürebilir.

### 4.3 Android Emülatör Hazırlama

**Android Studio üzerinden:**
1. Android Studio'yu açın
2. `Tools` → `Device Manager`
3. `Create Device` → Bir telefon seçin (örn: Pixel 7)
4. Bir sistem imajı indirin (önerilen: API 34)
5. Emülatörü başlatın

**Komut satırından:**
```bash
# Mevcut emülatörleri listele
flutter emulators

# Emülatörü başlat
flutter emulators --launch <emulator_id>
```

### 4.4 Bağlı Cihazları Kontrol Etme

```bash
flutter devices
```

**Beklenen çıktı:**
```
2 connected devices:

sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • Android 14 (API 34)
Chrome (web)                 • chrome         • web-javascript • Google Chrome
```

---

## 5. Supabase Konfigürasyonu

> ✅ **İyi haber:** Supabase zaten yapılandırılmış durumda! Takım için ortak bir Supabase projesi kullanıyoruz.

### 5.1 Mevcut Konfigürasyon

Supabase bilgileri `mobile/lib/core/config/supabase_config.dart` dosyasında tanımlı:

```dart
static const String supabaseUrl = 'https://qzbmodnznfdtjyietjie.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIs...';
```

**Bu bilgileri DEĞİŞTİRMEYİN!** Ortak veritabanını kullanmak için bu şekilde kalmalı.

### 5.2 Supabase Dashboard (Opsiyonel)

Veritabanını görüntülemek isterseniz:
1. [app.supabase.com](https://app.supabase.com/) adresine gidin
2. Mahmut'tan erişim isteyin

---

## 6. Uygulamayı Çalıştırma

### 6.1 Tam Çalıştırma Sırası

**1. Docker servislerini başlat:**
```bash
cd challenger
docker-compose up -d
```

**2. Backend'i başlat (yeni terminal):**
```bash
cd challenger/backend
npm run start:dev
```

**3. Mobile'ı başlat (yeni terminal):**
```bash
cd challenger/mobile
flutter run
```

### 6.2 Hızlı Başlatma (Sadece Mobile)

Backend'e ihtiyaç duymadan sadece mobile'ı test etmek için:

```bash
cd challenger/mobile
flutter run
```

> 💡 Backend olmadan da uygulama çalışır (Supabase üzerinden veriler gelir).

### 6.3 Web'de Çalıştırma

```bash
flutter run -d chrome
```

### 6.4 Hot Reload

Uygulama çalışırken:
- **`r`** tuşu → Hot Reload (hızlı yenileme)
- **`R`** tuşu → Hot Restart (tam yeniden başlatma)
- **`q`** tuşu → Çıkış

---

## 7. Sorun Giderme

### 7.1 Docker Sorunları

**Sorun:** Docker Desktop başlamıyor
```
error during connect: This error may indicate that the docker daemon is not running
```

**Çözüm:**
1. Docker Desktop'ı yeniden başlatın
2. Windows Özelliklerinde "WSL 2" ve "Hyper-V" aktif olduğundan emin olun

---

**Sorun:** Port zaten kullanımda
```
Bind for 0.0.0.0:5432 failed: port is already allocated
```

**Çözüm:**
```bash
# Çakışan container'ları durdurun
docker stop $(docker ps -q)

# Yeniden başlatın
docker-compose up -d
```

---

### 7.2 Flutter Sorunları

**Sorun:** Paket bulunamadı hatası
```
Error: Could not find package "xxx"
```

**Çözüm:**
```bash
flutter clean
flutter pub get
```

---

**Sorun:** Hive adapters bulunamadı
```
HiveError: Cannot find adapter for type 'Position'
```

**Çözüm:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

**Sorun:** Android emülatör başlamıyor
```
Error launching application on Android Emulator
```

**Çözüm:**
1. Android Studio → SDK Manager → SDK Tools → Android Emulator güncelleyin
2. Device Manager → Wipe Data
3. Emülatörü yeniden oluşturun

---

### 7.3 Backend Sorunları

**Sorun:** npm install başarısız
```
npm ERR! code ERESOLVE
```

**Çözüm:**
```bash
npm cache clean --force
rm -rf node_modules
npm install --legacy-peer-deps
```

---

**Sorun:** Redis bağlantı hatası
```
Error: connect ECONNREFUSED 127.0.0.1:6379
```

**Çözüm:**
```bash
docker-compose up -d redis
```

---

### 7.4 Supabase Sorunları

**Sorun:** Auth hatası
```
AuthException: Invalid login credentials
```

**Çözüm:** Normal davranış, yanlış email/şifre girdiniz. "Misafir Olarak Devam Et" ile giriş yapabilirsiniz.

---

## 📱 Günlük Geliştirme Akışı

Her gün çalışmaya başlarken:

```bash
# 1. En son değişiklikleri çekin
cd challenger
git pull origin main

# 2. Docker'ı başlatın (zaten çalışıyorsa atla)
docker-compose up -d

# 3. Backend'i başlatın (ayrı terminal)
cd backend
npm run start:dev

# 4. Mobile'ı başlatın (ayrı terminal)
cd mobile
flutter run
```

---

## 📞 Yardım

Sorun yaşarsanız:
1. Önce bu rehberdeki "Sorun Giderme" bölümüne bakın
2. Hala çözülmediyse Mahmut'a ulaşın

---

**İyi çalışmalar! 🚀**
