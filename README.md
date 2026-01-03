# ASSIST AI — Proje README

Bu README, proje yapısını, mimariyi ve eksik parçaların (AI önerileri, push bildirimleri ve veritabanı yönetimi) nerede uygulanacağını açıklar.

Uygulayıcılar için kontrol listesi (yüksek seviye)
\- [ ] AI için backend stratejisi seç (bulut) ve `lib/services/ai_service.dart` + API anahtarı yönetimi ekle
\- [ ] Kalıcı `TaskRepository` & `CalendarRepository` uygula (sqflite/hive/isar/Firebase)
\- [ ] `NotificationService` uygula ve bildirimleri zamanla (flutter_local_notifications ve/veya firebase_messaging kullan)
\- [ ] AI önerilerini `HomeViewModel` içine bağla veya `AIRecommendationsViewModel` ekle (domain use-case'leri kullan)
\- [ ] Use-case ve repository davranışı için testler ekle

---

Proje Genel Bakış

\- Tip: Flutter uygulaması  
\- Dart SDK: >=3.0.0 <4.0.0 (bakınız `pubspec.yaml`)  
\- State yönetimi: Provider  
\- Mimari: MVVM + Clean-benzeri katmanlı yapı (data, domain, presentation)

Uygulama UI'si kısmen uygulanmış; data/repository katmanı şu an bellek içi mock implemantasyonlar kullanıyor. Bunları production seviyesinde uygulanmış halleriyle değiştirip AI ve bildirim servislerini eklemeniz gerekecek.

---

Depo / Klasör Haritası (önemli dosyalar)

\- `lib/`  
\- `main.dart` — uygulama giriş noktası ve global `Provider` kayıtları (`ServiceLocator` kullanılır)  
\- `injection_container.dart` — mevcut DI/service locator (singleton'lar burada oluşturulur)  
\- `app.dart` — root scaffold ve temel navigasyon  
\- `services/`  
\- `theme_service.dart` — tema için ChangeNotifier  
\- `localization_service.dart` — stringler ve locale haritası  
\- (ekle) `ai_service.dart` — AI backend ile haberleşen servis  
\- (ekle) `notification_service.dart` — bildirimi zamanlayan/gönderen servis  
\- (ekle) `db_service.dart` veya `persistence_service.dart` — veritabanı sarmalayıcısı  
\- `data/`  
\- `models/` — `task.dart`, `calendar_event.dart`, `ai_recommendation.dart`  
\- `repositories/` — `task_repository.dart`, `calendar_repository.dart` (şu an bellek içi impl)  
\- Bu `*RepositoryImpl` sınıflarını DB tabanlı implementasyonlarla değiştirin  
\- `domain/`  
\- `use_cases/` — iş mantığını yöneten use-case'ler  
\- AI önerileri veya bildirim planlama için yeni use-case'ler ekleyin  
\- `presentation/`  
\- `viewmodels/` — `HomeViewModel`, `CalendarViewModel`, `SettingsViewModel`  
\- Uygun viewmodel'lere AI ve bildirim tetiklerini bağlayın  
\- `pages/`, `widgets/` — UI bileşenleri (UI sizin sorumluluğunuz)

---

Yüksek seviye mimari ve özelliklerin nerede uygulanacağı

Uygulama katmanlı bir yaklaşımı takip eder:

\- Presentation (UI + ViewModels): `lib/presentation/`  
Sorumluluklar: UI render, kullanıcı etkileşimleri, intent'leri ViewModel'lere iletme  
Uygulama: UI öğelerini ViewModel metodlarına bağlayın. UI doğrudan repository veya servisleri çağırmamalıdır.

\- Domain (Use Cases): `lib/domain/use_cases/`  
Sorumluluklar: İş mantığı (adım dizileri) framework bağımsız olarak uygulanır  
Uygulama: `GetTasksUseCase`, `AddTaskUseCase` gibi use-case'ler ve yeni `GetAIRecommendationsUseCase`, `ScheduleNotificationUseCase`.

\- Data (Repositories + Models): `lib/data/`  
Sorumluluklar: Veri saklama ve alma (DB, uzak API). Repository arayüzlerini DB/remote ile implemente edin.  
Uygulama: `TaskRepositoryImpl`, `CalendarRepositoryImpl` yerine DB destekli implementasyonlar.

\- Services: `lib/services/`  
Sorumluluklar: Ağ, AI API client'ları, bildirimler, DB wrapper, auth gibi çapraz-kesit endişeler.  
Uygulama: `AIService`, `NotificationService`, `DBService` oluşturun.

\- Dependency Injection: `lib/injection_container.dart`  
Sorumluluklar: Singleton'ları oluşturma ve sunma (repository, servis, viewmodel).  
Uygulama: DB ve bildirim plugin'lerini burada başlatın (async olabilir — bootstrap `setupDependencies()` içinde `runApp` öncesinde çağrılmalı).

---

Detaylı uygulama rehberi (AI, Bildirimler, DB)

1) AI Önerileri

Amaç: Varolan `AIRecommendation` modelini kullanarak AI tabanlı öneriler sunmak.

\- Servis: `lib/services/ai_service.dart`  
\- Sorumluluk: Prompt göndermek ve yapılandırılmış yanıt almak.  
\- Metod örneği: `Future<List<AIRecommendation>> getRecommendationsForUser({List<Task> tasks, List<CalendarEvent> events, Locale locale})`  
\- Uygulama seçenekleri:  
\- Bulut (önerilen): OpenAI veya kendi inference sunucunuz. `http`/`dio` veya `openai` paketlerini kullanın. API anahtarlarını güvenli saklayın (`flutter_dotenv` vb.).  
\- Cihaz içi: TensorFlow Lite modeli entegre etmek mümkün; genelde daha karmaşık.

\- Domain: `lib/domain/use_cases/get_ai_recommendations_use_case.dart`  
\- `AIService.getRecommendationsForUser(...)` çağırır ve `AIRecommendation` objelerine map eder.

\- Data/Repository: Önerileri cache'lemek isterseniz opsiyonel `AIRepository` ekleyin.

\- Presentation: `HomeViewModel` use-case'i çağırmalı (`getAIRecommendationsUseCase`) ve `HomePage`'e `List<AIRecommendation>` sağlayacak şekilde expose etmelidir. Tetikleme: uygulama açılışında, görev değişikliğinde veya kullanıcı isteğiyle.

Notlar ve dikkat edilmesi gerekenler: API maliyetleri, rate limit, caching, gizlilik (duyarlı veriyi göndermeyin), yapılandırılmış JSON tercih edin.

2) Push Bildirimleri (ve Yerel Bildirimler)

Amaç: Kullanıcılara yaklaşan görev/etkinlikler hakkında bildirim göndermek.

Modlar:  
\- Uzaktan push (Firebase Cloud Messaging) — sunucu kaynaklı uyarılar için  
\- Yerel zamanlanan bildirimler (`flutter_local_notifications`) — cihaz üzerinde planlanan alarmlar için

Önerilen yapı: Her iki yöntemi birlikte kullanın: Yerel bildirimler cihaz-temelli hatırlatmalar için; FCM uzak ve çapraz-cihaz senkronizasyon için.

Eklenmesi gereken dosyalar:  
\- `lib/services/notification_service.dart` — `firebase_messaging` ve `flutter_local_notifications` için sarmalayıcı. Metod örnekleri:  
\- `Future<void> init()`  
\- `Future<void> scheduleNotification({id, title, body, DateTime when})`  
\- `Future<void> cancelNotification(int id)`  
\- `Stream<RemoteMessage> onRemoteMessage`

\- Domain: `lib/domain/use_cases/schedule_notification_use_case.dart` — `AddTaskUseCase` veya viewmodel tarafından çağrılabilir.

Entegrasyon:  
\- Görev oluşturma/güncelleme sırasında `ScheduleNotificationUseCase` çağrısı yapın.  
\- Silme sırasında planlı bildirimleri iptal edin.

Paketler ve platform ayarları: `firebase_core`, `firebase_messaging`, `flutter_local_notifications`, `permission_handler`. Android ve iOS platform ayarlarını Firebase dokümanlarına göre yapın. Zaman çizelgesi için `timezone` paketi ile timezone-aware planlama yapın.

3) Veritabanı / Kalıcılık (SQLite)

Amaç: Bellek içi mock implementasyonları kalıcı SQLite depolamasıyla değiştirerek verilerin uygulama yeniden başlatmalarında korunmasını sağlamak.

Önerilen yaklaşım:
- Lokal DB: `sqflite` + `path_provider` kullanın.
- Merkezi DB sarmalayıcısı: `lib/services/db_service.dart` oluşturun ve tüm repository'ler bu servisi kullanarak DB işlemlerini gerçekleştirsin.
- Repository'ler: `TaskRepositorySqlite` ve `CalendarRepositorySqlite` gibi SQLite tabanlı implementasyonlar ekleyin. Mevcut `TaskRepository` arayüzünü koruyun ve implementasyonları değiştirin.

`DBService` sorumlulukları:
- Veritabanını başlatma ve migration yönetimi (`openDatabase`, `onCreate`, `onUpgrade`).
- Temel CRUD yardımcı metodları: `insert`, `update`, `delete`, `query`, `transaction`.
- Tekil örnek (singleton) olarak çalışmalı; `await DBService.instance.init()` benzeri bir başlangıç metodu `setupDependencies()` içinde çağrılmalı.

Örnek tablo şeması (ilk versiyon):
- `tasks`:
    - `id INTEGER PRIMARY KEY AUTOINCREMENT`
    - `title TEXT NOT NULL`
    - `description TEXT`
    - `dueDate INTEGER` (millisecondsSinceEpoch)
    - `isCompleted INTEGER NOT NULL DEFAULT 0`
    - `reminderAt INTEGER`
    - `createdAt INTEGER NOT NULL`
    - `updatedAt INTEGER`
- `calendar_events`:
    - `id INTEGER PRIMARY KEY AUTOINCREMENT`
    - `title TEXT NOT NULL`
    - `description TEXT`
    - `startAt INTEGER`
    - `endAt INTEGER`
    - `createdAt INTEGER NOT NULL`
    - `updatedAt INTEGER`
- `ai_recommendations` (opsiyonel cache):
    - `id INTEGER PRIMARY KEY AUTOINCREMENT`
    - `source TEXT`
    - `payload TEXT`
    - `createdAt INTEGER NOT NULL`

Model gereksinimleri:
- `Task` ve `CalendarEvent` modelleri `toMap()` ve `fromMap(Map<String, dynamic>)` metotlarını implement etmeli.
- Zaman damgaları millis cinsinden saklanmalı (`DateTime.millisecondsSinceEpoch`).

Repository örnekleri:
- `lib/data/repositories/task_repository_sqlite.dart` — `TaskRepository` arayüzünü kullanır ve `DBService` üzerinden SQL işlemlerini yapar.
- Metotlar: `getTasks()`, `addTask()`, `updateTask()`, `deleteTask()`, `toggleTaskCompletion()`, `getUpcomingTasks()` — SQL filtreleri ve sıralama ile uygulanmalı.

Başlatma / DI:
- `lib/injection_container.dart` içindeki `setupDependencies()` async olmalı.
- `await DBService.instance.init()` çağrısını `setupDependencies()` içinde yapın ve sonra repository'leri register edin.

Migration & versiyonlama:
- `DBService` içinde bir `_dbVersion` kullanın; `onUpgrade` içinde migration sorgularını ekleyin.
- Şema değişikliklerinde versiyon numarasını artırın ve gerekli `ALTER`/migrate adımlarını yönetin.

Senaryolar:
- Lokal-only uygulama: `sqflite` yeterli ve önerilir.
- Çoklu cihaz senkronizasyonu gerekiyorsa, SQLite + sunucu senkronizasyonu ya da Firestore düşünün (mimariye ek entegrasyon gerekir).

Ek dosyalar önerisi:
- `lib/services/db_service.dart` (SQLite wrapper)
- `lib/data/repositories/task_repository_sqlite.dart`
- `lib/data/repositories/calendar_repository_sqlite.dart`

Notlar:
- `pubspec.yaml` içinde `sqflite` ve `path_provider` paketlerini eklemeyi unutmayın.
- DB init asenkron olduğundan `runApp` öncesinde DI setup'ını tamamlayın.


Wiring örneği (kod yerleri)

\- `lib/injection_container.dart` — `setupDependencies()` içinde DB ve Notification plugin başlatma; DB örneğini repository constructor'larına verin. `setupDependencies()` async olmalı ve `runApp` öncesi çağrılmalı.

\- `lib/domain/use_cases/*` — soyut repository arayüzlerini kullanmaya devam eder.

\- `lib/presentation/viewmodels/home_viewmodel.dart` — Görev yüklendiğinde veya değiştiğinde `getAIRecommendationsUseCase` çağırın. Göreve `reminder` eklendiğinde `ScheduleNotificationUseCase` çağırın.

\- `lib/presentation/pages/*` ve `widgets/*` — UI, ViewModel metodlarını çağırmalı ve Provider üzerinden dinlemeli.

---

Güvenlik & gizli anahtarlar

\- API anahtarlarını repo'ya kesinlikle eklemeyin. `flutter_dotenv` veya CI secret'ları kullanın. Lokal anahtar dosyalarını `.gitignore`'a ekleyin.  
\- Sunucu tabanlı AI ise token'ları mümkünse sunucu tarafında saklayın. Eğer doğrudan uygulamadan çağırıyorsanız kullanıcı onayı ve limitleri düşünün.

---

Önerilen paketler (örnek, `pubspec.yaml` güncellemesi)

\- Ağ: `http` veya `dio`  
\- AI: `openai` veya doğrudan `http`  
\- DB: `sqflite` / `path_provider` veya `hive` / `hive_flutter` veya `isar`  
\- Bildirimler: `flutter_local_notifications`, `firebase_messaging`, `timezone`  
\- Çevre: `flutter_dotenv`  
\- Diğer: `provider`, `intl`

(Flutter SDK ile uyumluluk için sürümleri ayarlayın.)

---

Test & doğrulama

\- Unit testler: use-case ve repository testleri ekleyin (mock repository kullanarak).  
\- Integration testler: UI hazırsa `flutter_test` ve `integration_test` kullanın.  
\- Manuel doğrulama:

\`\`\`bash
flutter pub get
flutter analyze
flutter test
flutter run
\`\`\`

---

Geliştirme ipuçları ve merge öncesi kontrol

\- AI ve push özelliklerini feature flag ile koruyun.  
\- Analytics ve hata raporlama (ör. Sentry) ekleyin.  
\- Repository değişimi yaparken migrate planı hazırlayın.  
\- Mimari kararları kod yorumları ve README içinde belgeleyin.

---

Örnek entegrasyon akışları (kısa)

\- Görev ekleme ve hatırlatıcı
1. UI, `reminder` alanıyla birlikte görev bilgilerini toplar ve `HomeViewModel.addTask(task)` çağırır.
2. `HomeViewModel.addTask` `AddTaskUseCase` çağırır.
3. `AddTaskUseCase` görev verisini `TaskRepository.addTask(task)` ile kalıcıya yazar.
4. Eğer `task.reminder` doluysa `ScheduleNotificationUseCase` çağrılarak yerel bildirim zamanlanır.

\- AI önerileri üretimi
1. `HomeViewModel` veya `AIRecommendationsViewModel` `GetAIRecommendationsUseCase` çağırır.
2. Use-case `AIService.getRecommendationsForUser(tasks, events)` çağrır.
3. `AIService` seçilen AI sağlayıcısına prompt gönderir ve yapılandırılmış yanıtı parse eder.
4. Use-case `List<AIRecommendation>` döndürür; UI bunları gösterir.

---

Katkıda bulunanlara notlar

\- `TaskRepository` arayüzünü stabil tutun; yeni ihtiyaçlar için arayüze metod ekleyin, mevcut imzaları değiştirmeyin.  
\- Ayarları (`language`, `theme`) saklamak için `SharedPreferences` veya DB kullanmayı düşünün.  
\- Kritik başlatmayı `setupDependencies()` içinde toplayın; rastgele dosyalarda global state oluşturmayın.

---

Ek: Hangi dosyaları eklemelisiniz (kısa harita)

\- `lib/services/ai_service.dart`  
\- `lib/services/notification_service.dart`  
\- `lib/services/db_service.dart`  
\- `lib/data/repositories/task_repository_sqlite.dart`  
\- `lib/data/repositories/calendar_repository_sqlite.dart`  
\- `lib/domain/use_cases/get_ai_recommendations_use_case.dart`  
\- `lib/domain/use_cases/schedule_notification_use_case.dart`  
\- `lib/presentation/viewmodels/ai_viewmodel.dart`

---
