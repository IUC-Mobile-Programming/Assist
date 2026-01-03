# ASSIST AI — Proje README

Bu README, proje yapısını, mimariyi ve eksik parçaların (AI önerileri, push bildirimleri ve veritabanı yönetimi) nerede uygulanacağını açıklar. UI öğelerini siz (UI sahibi) uygulayacaksınız; bu doküman, backend ve entegrasyon işlerini tamamlayacak implementerlere yöneliktir.

---

Teslim edeceğim özet
\- Net bir proje genel bakışı ve mimari açıklaması
\- Dosya / klasör haritası ve sorumluluklar
\- Özel talimatlar (ne uygulanmalı, nerede ve neden) için:
\- AI önerileri (servis + domain + UI bağlantısı)
\- Push bildirimleri (firebase + yerel zamanlama)
\- Veritabanı kalıcılığı (yerel DB + repository bağlantısı)
\- Önerilen paketler ve platform/izin notları
\- Örnek entegrasyon akışları, test ve doğrulama komutları

---

Uygulayıcılar için kontrol listesi (yüksek seviye)
\- [ ] AI için backend stratejisi seç (bulut veya cihaz içi) ve `lib/services/ai_service.dart` + API anahtarı yönetimi ekle
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

3) Veritabanı / Kalıcılık

Amaç: Bellek içi mock implementasyonları, kalıcı depolama ile değiştirerek verilerin uygulama yeniden başlatmalarında korunmasını sağlamak.

DB Seçenekleri:  
\- SQLite (`sqflite`) — ilişkisel, karmaşık sorgular için iyi.  
\- Hive — hızlı, NoSQL-benzeri objeye dönük depolama.  
\- Isar — yüksek performanslı, reaktif sorgular.  
\- Firebase Firestore — çoklu cihaz senkronizasyonu gerekiyorsa bulut.

Öneri: Lokal-only için `sqflite` veya `hive`. Çoklu cihaz sync gerekiyorsa Firestore veya özel backend ekleyin.

Repository implementasyonu:  
\- `TaskRepositoryImpl` yerine `TaskRepositorySqlite` veya `TaskRepositoryHive` ekleyin. `TaskRepository` soyut arayüzünü sabit tutun. Implement edin: `getTasks()`, `addTask(task)`, `updateTask(task)`, `deleteTask(id)`, `toggleTaskCompletion(id)`, `getUpcomingTasks()`.

DB servis: `lib/services/db_service.dart` — DB başlatma ve migrationları merkezi hale getirin. `injection_container.dart` içindeki `setupDependencies()` async olmalı ve burada DB init çağrılmalı.

Şema & modeller: Mevcut modelleri (`Task`, `CalendarEvent`) kullanın. `toMap()`/`fromMap()` metotlarını sqflite ile eşleyin veya Hive için `TypeAdapter` kaydedin.

Migration & sync: Uzak senkronizasyon planlıyorsanız `createdAt` / `updatedAt` timestamp'leri kullanın.

---

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

İsterseniz ben başlangıç için şu scaffold'ları oluşturabilirim:
\- `AIService`, `NotificationService`, `DBService` için temel dosyalar  
\- `sqflite` tabanlı örnek `TaskRepository` ve `setupDependencies()` async başlangıcı  
\- `HomeViewModel` için örnek birim test (fake repository ile)
