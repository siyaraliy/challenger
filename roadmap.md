# Challenger Projesi Yol Haritası (Roadmap)

Bu belge, **Challenger** projesinin SRS dökümanına dayalı geliştirme planını içerir. Proje, "Offline-First" mobil uygulama ve gerçek zamanlı backend servislerinden oluşmaktadır.

## Faz 1: Proje Kurulumu ve Altyapı (Hafta 1-2)
**Hedef:** Geliştirme ortamının hazırlanması ve temel mimarinin kurulması.

### Backend (NestJS)
- [ ] NestJS projesinin oluşturulması (Modular Architecture).
- [ ] Docker & Docker Compose kurulumu (PostgreSQL, Redis).
- [ ] Veritabanı şemasının tasarlanması (ER Diagram) ve ORM (TypeORM/Prisma) konfigürasyonu.
- [ ] Global Exception Filter ve Logging yapısının kurulması.
- [ ] CI/CD pipeline taslağının oluşturulması.

### Mobile (Flutter)
- [ ] Flutter projesinin oluşturulması.
- [ ] Klasör yapısının (Clean Architecture) ve State Management (BLoC) kurulumu.
- [ ] Temel UI Kit (Renkler, Fontlar, Ortak Widget'lar) oluşturulması.
- [ ] Navigation yapısının (GoRouter) kurulması.
- [ ] Yerel Veritabanı (Hive) entegrasyonu.

---

## Faz 2: Kimlik Doğrulama ve Profil Yönetimi (Hafta 3)
**Hedef:** Kullanıcıların sisteme güvenli giriş yapabilmesi ve profil oluşturması.

### Backend
- [ ] Auth Modülü: Login, Register, Refresh Token (JWT).
- [ ] OAuth Entegrasyonu (Google, Apple).
- [ ] User Modülü: Profil oluşturma, güncelleme, avatar yükleme (AWS S3).

### Mobile
- [ ] Login / Register ekranlarının tasarımı ve entegrasyonu.
- [ ] Profil ekranı ve düzenleme akışları.
- [ ] Güvenli Token saklama (Flutter Secure Storage).

---

## Faz 3: Takım Yönetimi ve Sosyal Ağ (Hafta 4-5)
**Hedef:** Takım kurma, oyuncu bulma ve sosyal etkileşim (Navigasyon Yapısı).

### Backend
- [ ] Team Modülü: Takım oluşturma, oyuncu davet etme, kaptan atama.
- [ ] Feed Modülü: Takip edilenlerin içerikleri (Anasayfa).
- [ ] Recommendation Modülü: Önerilen takımlar/oyuncular (Keşfet).
- [ ] Search Modülü: Konum tabanlı arama.

### Mobile
- [ ] **Bottom Navigation Bar** Kurulumu (5 Sekme):
    1.  **Anasayfa:** Takip edilen içerikler.
    2.  **Keşfet:** Öneriler ve Arama.
    3.  **Sıralama:** Liderlik Tablosu.
    4.  **Mesajlar:** Sohbetler.
    5.  **Profil:** Hesap yönetimi ve paylaşım.
- [ ] Takım profili ve yönetim ekranları.

---

## Faz 4: İletişim Çekirdeği (Chat Core) (Hafta 6-7)
**Hedef:** Gerçek zamanlı mesajlaşma altyapısının kurulması.

### Backend
- [ ] Socket.IO Gateway kurulumu.
- [ ] Chat Modülü: Oda oluşturma (DM, Team, Negotiation).
- [ ] Mesajlaşma API'leri (Gönder, Sil, Raporla).
- [ ] Offline Queue için Redis entegrasyonu.

### Mobile
- [ ] Sohbet listesi ve mesajlaşma ekranı UI.
- [ ] Socket bağlantısı ve olay dinleyicileri.
- [ ] Yerel mesaj önbellekleme (Local Cache) ve senkronizasyon.

---

## Faz 5: Meydan Okuma ve Müzakere (Hafta 8-9)
**Hedef:** Projenin kalbi olan maç ayarlama döngüsü.

### Backend
- [ ] Challenge Modülü: İstek gönderme, kabul/red.
- [ ] Negotiation Modülü: Müzakere odası mantığı, sistem mesajları.
- [ ] Maç parametrelerini (Saat, Saha) güncelleme ve kilitleme mantığı.

### Mobile
- [ ] Meydan okuma akışları ve UI.
- [ ] Müzakere Odası (Negotiation Room) özel ekranı.
- [ ] "Sticky Header" maç özeti kartı ve düzenleme modalları.
- [ ] Google Maps entegrasyonu (Saha seçimi).

---

## Faz 6: Puanlama, Liderlik ve Finalizasyon (Hafta 10)
**Hedef:** Oyunlaştırma öğeleri ve yayın hazırlığı.

### Backend
- [ ] Match Result Modülü: Skor girişi ve onaylama.
- [ ] Leaderboard Modülü: Puan hesaplama ve sıralama (Redis Sorted Sets).
- [ ] Admin paneli API'leri (Raporlanan içerikler).

### Mobile
- [ ] Maç sonucu giriş ekranları.
- [ ] Liderlik tablosu ekranı.
- [ ] Performans optimizasyonları ve testler.

---

## Faz 7: Test ve Dağıtım (Hafta 11)
- [ ] UAT (Kullanıcı Kabul Testleri).
- [ ] Mağaza (App Store / Play Store) görsellerinin ve metinlerinin hazırlanması.
- [ ] Production ortamına deploy.
