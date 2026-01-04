# ASSIST AI 🤖

**Assist AI**, görev yönetimi ve takvim etkinliklerini yapay zeka destekli önerilerle birleştiren, MVVM mimarisi ve Clean Architecture prensipleriyle geliştirilmiş bir Flutter uygulamasıdır.

Bu README, proje yapısını, mimari kararları ve (şu an mock olan) veri katmanının production seviyesine nasıl taşınacağını açıklar.

## 📋 Geliştirici Kontrol Listesi (Yüksek Seviye)

Projeyi devralan geliştiriciler için öncelikli yapılması gerekenler:

- [ ] **AI Backend:** `lib/services/ai_service.dart` oluştur, backend stratejisini seç (OpenAI/Cloud) ve API anahtarı yönetimini ekle.
- [ ] **Veritabanı:** `TaskRepository` & `CalendarRepository` için kalıcı depolama (SQLite/Hive) uygula.
- [ ] **Bildirimler:** `NotificationService` ile yerel ve uzak (push) bildirimleri entegre et.
- [ ] **AI Entegrasyonu:** AI önerilerini `HomeViewModel` veya `AIRecommendationsViewModel` içerisine bağla.
- [ ] **Test:** Kritik use-case ve repository davranışları için birim testleri yaz.

---

## 🛠 Proje Genel Bakış

| Özellik | Detay |
| :--- | :--- |
| **Tip** | Flutter Uygulaması |
| **SDK** | Dart >=3.0.0 <4.0.0 |
| **State Yönetimi** | Provider |
| **Mimari** | MVVM + Clean Architecture (Data, Domain, Presentation) |
| **Durum** | UI kısmen hazır. Data katmanı şu an **In-Memory Mock** kullanıyor. |

---

## 📂 Klasör Yapısı ve Önemli Dosyalar

Proje, sorumlulukların ayrıldığı katmanlı bir yapıya sahiptir:

```text
lib/
├── main.dart                  # Uygulama giriş noktası, Provider kayıtları
├── injection_container.dart   # Dependency Injection (Service Locator) kurulumu
├── app.dart                   # Root Scaffold ve Navigasyon
├── services/                  # Harici servisler ve sarmalayıcılar
│   ├── theme_service.dart
│   ├── localization_service.dart
│   ├── ai_service.dart        # [EKLENECEK] AI API haberleşmesi
│   ├── notification_service.dart # [EKLENECEK] Bildirim yönetimi
│   └── db_service.dart        # [EKLENECEK] Veritabanı sarmalayıcısı
├── data/                      # Veri katmanı (Repositories + Models)
│   ├── models/                # task.dart, calendar_event.dart, ai_recommendation.dart
│   └── repositories/          # Repository Implementasyonları (Şu an Mock)
├── domain/                    # İş Mantığı (Framework bağımsız)
│   └── use_cases/             # GetTasks, AddTask, ScheduleNotification vb.
└── presentation/              # UI Katmanı
    ├── viewmodels/            # HomeViewModel, CalendarViewModel
    ├── pages/                 # Ekranlar
    └── widgets/               # Yeniden kullanılabilir bileşenler

```

---

## 🏗 Mimari Yaklaşım

Uygulama **Clean Architecture** prensiplerini takip eder:

1. **Presentation (UI + ViewModels):** Kullanıcı etkileşimlerini yönetir. UI asla doğrudan Repository veya Service çağırmaz; ViewModel kullanır.
2. **Domain (Use Cases):** İş mantığını barındırır (Örn: `GetTasksUseCase`).
3. **Data (Repositories):** Verinin nereden geleceğine karar verir (DB, API, Mock).
4. **Services:** Çapraz kesit endişelerini (AI, Auth, DB Connection) yönetir.
5. **DI (`injection_container.dart`):** Uygulama başlatılmadan önce tüm bağımlılıkları (singleton) hazırlar.

---

## 🚀 Uygulama Rehberi: Eksik Parçalar

### 1. Veritabanı / Kalıcılık (SQLite)

Mevcut bellek içi (mock) yapıyı `sqflite` ile kalıcı hale getirin.

* **Servis:** `lib/services/db_service.dart` (Singleton wrapper).
* **Repository:** `TaskRepositorySqlite` sınıfını oluşturun ve SQL sorgularını buraya yazın.
* **Schema (Örnek):**
* `tasks`: id, title, description, dueDate, isCompleted, reminderAt
* `calendar_events`: id, title, startAt, endAt



### 2. AI Önerileri

Kullanıcının görevlerine göre akıllı öneriler sunmak için.

* **Servis:** `lib/services/ai_service.dart`.
* **Yöntem:** OpenAI API veya benzeri bir LLM servisine prompt gönderimi.
* **Akış:**
  `ViewModel` -> `GetAIRecommendationsUseCase` -> `AIService` -> `API`

### 3. Bildirimler (Push & Local)

Zamanlanmış hatırlatıcılar için.

* **Servis:** `lib/services/notification_service.dart`.
* **Teknolojiler:** `flutter_local_notifications` (yerel zamanlama) ve `firebase_messaging` (uzak sunucu).
* **Entegrasyon:** `AddTaskUseCase` içinde görev kaydedilirken, eğer hatırlatıcı varsa `ScheduleNotificationUseCase` çağrılmalıdır.

---

## 📦 Önerilen Paketler (`pubspec.yaml`)

Aşağıdaki paketlerin uyumlu sürümlerini projeye dahil etmeniz önerilir:

```yaml
dependencies:
  # Ağ & AI
  http: ^1.x.x
  # Veya openai_dart paketi

  # Veritabanı
  sqflite: ^2.x.x
  path_provider: ^2.x.x

  # Bildirimler
  flutter_local_notifications: ^17.x.x
  firebase_messaging: ^14.x.x
  timezone: ^0.9.x

  # Yardımcılar
  flutter_dotenv: ^5.x.x  # API Key güvenliği için
  provider: ^6.x.x
  intl: ^0.18.x

```

---

## 🔒 Güvenlik Notları

* ⚠️ **API Anahtarları:** `.env` dosyası kullanın ve bu dosyayı `.gitignore`'a ekleyin. Repo'ya asla API key pushlamayın.
* **Hassas Veri:** AI servisine veri gönderirken kullanıcı gizliliğine dikkat edin. Sadece gerekli veri parçalarını gönderin.

---

## 🧪 Test ve Çalıştırma

Geliştirme ortamını hazırlamak ve test etmek için:

```bash
# Bağımlılıkları yükle
flutter pub get

# Hataları denetle
flutter analyze

# Testleri çalıştır
flutter test

# Uygulamayı başlat
flutter run

```

---

## 💡 Katkı Sağlama İpuçları

1. **Dependency Injection:** Yeni bir servis veya repository eklediğinizde `injection_container.dart` içindeki `setupDependencies()` metoduna kaydetmeyi unutmayın.
2. **Migration:** Veritabanı şemasında değişiklik yaparken versiyonlamayı (`onUpgrade`) yönetin.
3. **Code Style:** Repository arayüzlerini (`interface`) değiştirmemeye özen gösterin, sadece implementasyonları güncelleyin.

```

```