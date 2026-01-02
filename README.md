# ASSIST AI — Project README

This README explains the project structure, architecture, and where to implement missing pieces such as AI recommendations, push notifications, and database management. It is intended for implementers who will complete the remaining backend and integration work while you (the UI owner) will connect the UI elements.

---

Summary of what I'll deliver here
- A clear project overview and architecture explanation
- File / folder map and responsibilities
- Specific instructions (what to implement, where, and why) for:
  - AI recommendations (service + domain + UI wiring)
  - Push notifications (firebase + local scheduling)
  - Database persistence (local DB + repository wiring)
- Recommended packages and platform/permission notes
- Example integration flow(s), testing & verification commands

---

Checklist for implementers (high-level)
- [ ] Choose backend strategy for AI (cloud or on-device) and add `lib/services/ai_service.dart` + API key management
- [ ] Implement persistent `TaskRepository` & `CalendarRepository` backed by a DB (sqflite/hive/isar/Firebase)
- [ ] Implement `NotificationService` to schedule and deliver notifications (use flutter_local_notifications and/or firebase_messaging)
- [ ] Wire AI suggestions into `HomeViewModel` or provide an `AIRecommendationsViewModel` (use domain use-cases)
- [ ] Add tests for use-cases and repository behavior

---

Project Overview

- Type: Flutter application
- Dart SDK: >=3.0.0 <4.0.0 (see `pubspec.yaml`)
- State management: Provider
- Architecture: MVVM + Clean-like layered structure (data, domain, presentation)

The app UI is partially implemented; the data/repository layer currently uses in-memory mock implementations. You'll need to replace those with production-ready implementations and add services for AI and notifications.

---

Repository / Folder Map (important files)

- `lib/`
  - `main.dart` — app entrypoint and global `Provider` registration (uses `ServiceLocator`)
  - `injection_container.dart` — current DI/service locator (singletons created here)
  - `app.dart` — root scaffold and primary navigation
  - `services/`
    - `theme_service.dart` — ChangeNotifier for theme
    - `localization_service.dart` — strings and locale map
    - (add) `ai_service.dart` — service to talk to AI backend
    - (add) `notification_service.dart` — service to schedule/send notifications
    - (add) `db_service.dart` or `persistence_service.dart` — database wrapper
  - `data/`
    - `models/` — `task.dart`, `calendar_event.dart`, `ai_recommendation.dart`
    - `repositories/` — `task_repository.dart`, `calendar_repository.dart` (currently in-memory impl)
      - Replace these `*RepositoryImpl` classes with DB-backed implementations
  - `domain/`
    - `use_cases/` — business use-cases that orchestrate repositories
      - Add new use-cases for AI recommendations or notification scheduling if needed
  - `presentation/`
    - `viewmodels/` — `HomeViewModel`, `CalendarViewModel`, `SettingsViewModel`
      - Hook AI + notification triggers into the appropriate viewmodels
    - `pages/`, `widgets/` — UI components (you own UI work)

---

High-level architecture and where to implement features

The app follows a layered approach:

- Presentation (UI + ViewModels): In `lib/presentation/`
  - Responsibilities: UI rendering, user interactions, forwarding user intents to ViewModels
  - Implement: Wire UI elements (dialogs, forms) to call ViewModel methods. The UI should not call repositories or services directly.

- Domain (Use Cases): In `lib/domain/use_cases/`
  - Responsibilities: Implement business logic (sequence of steps) independent of frameworks
  - Implement: Use cases like `GetTasksUseCase`, `AddTaskUseCase`, and new ones such as `GetAIRecommendationsUseCase`, `ScheduleNotificationUseCase`.

- Data (Repositories + Models): In `lib/data/`
  - Responsibilities: Persist and fetch data (DB, remote APIs). Implement repository interfaces used by use cases.
  - Implement: Database-backed `TaskRepositoryImpl`, `CalendarRepositoryImpl`, and an optional `AIRepository` if recommendations come from a 3rd-party API.

- Services: In `lib/services/`
  - Responsibilities: Cross-cutting concerns like networking, AI API clients, notifications, DB wrappers, auth.
  - Implement: `AIService`, `NotificationService`, `DBService` as described below.

- Dependency Injection: `lib/injection_container.dart`
  - Responsibilities: Compose and expose singletons (repositories, services, viewmodels).
  - Implement: Add initialization for DB and notification plugins here (may be async — put bootstrapping in `setupDependencies()` called before `runApp`).


Detailed implementation guidance (AI, Notifications, DB)

1) AI Recommendations

Goal: Provide AI-driven suggestions (the existing `AIRecommendation` model exists). The recommended structure:

- Service: `lib/services/ai_service.dart` — single class responsible for sending prompts and receiving structured responses from your chosen AI backend.
  - Methods: `Future<List<AIRecommendation>> getRecommendationsForUser({List<Task> tasks, List<CalendarEvent> events, Locale locale})`
  - Implementation options:
    - Cloud (recommended): Use OpenAI or your own inference server. Add HTTP client, use streaming or batch responses.
      - Packages: `http`, `dio`, or a dedicated OpenAI client such as `openai`.
      - Secure keys: store API keys in CI or environment, do NOT hardcode into repo. Use `flutter_dotenv` or platform secret managers.
    - On-device (if small model): integrate TensorFlow Lite model; usually harder and less flexible.

- Domain: `lib/domain/use_cases/get_ai_recommendations_use_case.dart`
  - Calls `AIService.getRecommendationsForUser(...)` and maps the response to `AIRecommendation` objects.
  - Returns: `Future<List<AIRecommendation>>`

- Data/Repository: Optional `AIRepository` if you need to cache suggestions to DB.

- Presentation: `HomeViewModel` should call the use case (e.g., `getAIRecommendationsUseCase`) to fetch recommendations and expose `List<AIRecommendation>` to `HomePage`.
  - Trigger points: on app launch, when tasks change, or on user request (pull-to-refresh or a button).

- UI: `lib/presentation/widgets/recommendation_item.dart` already exists — ensure it consumes fields from `AIRecommendation` returned by `HomeViewModel`.

Notes and pitfalls
- API cost and rate limits: implement caching and rate-limiting. Consider caching recommendations in DB with timestamps.
- Privacy: do not send sensitive user data unless privacy policy allows it. Consider anonymizing text before sending.
- Prompts: design prompts to return structured JSON if possible (makes parsing easy). Validate and sanitize API responses.


2) Push Notifications (and Local Notifications)

Goal: Notify users about upcoming tasks/events. Two common modes:
- Remote push notifications (Firebase Cloud Messaging) — for remote server-driven alerts
- Local scheduled notifications (flutter_local_notifications) — for device-based scheduled alerts

Recommended approach
- Use both: local notifications for scheduled reminders created on-device; FCM for server-initiated notifications and cross-device sync.

Services and files to add
- `lib/services/notification_service.dart`
  - Wrap both `firebase_messaging` and `flutter_local_notifications` with a unified interface:
    - `Future<void> init()` – initialize plugins and request permissions
    - `Future<void> scheduleNotification({id, title, body, DateTime when})` – schedule local notifications
    - `Future<void> cancelNotification(int id)`
    - `Stream<RemoteMessage> onRemoteMessage` — broadcast FCM messages to UI if needed

- `lib/domain/use_cases/schedule_notification_use_case.dart` — optional use-case called by `AddTaskUseCase` or by viewmodels when a task with reminder is added.

- Integration points:
  - When a task is created/updated (in `AddTaskUseCase` or `HomeViewModel.addTask()`), call `ScheduleNotificationUseCase` to schedule or reschedule a notification.
  - When a task is deleted, cancel scheduled notifications.

Packages and setup
- Add to `pubspec.yaml`:
  - `firebase_core`, `firebase_messaging` — for remote push
  - `flutter_local_notifications` — for scheduled local notifications
  - `flutter_local_notifications_platform_interface` as needed
  - `permission_handler` — for runtime permission handling

Platform setup (short):
- Android: update `AndroidManifest.xml` with FCM and background permission intents; add Firebase config (`google-services.json`) and Gradle plugin configuration (see Firebase setup docs).
- iOS: add `GoogleService-Info.plist`, enable push capabilities and background modes in Xcode, request permissions from `UNUserNotificationCenter`.

Important details
- Background handlers: register an FCM background handler early in `main()` and set up message handling callback per platform docs.
- Notifications on schedule: schedule local notifications using timezone-aware timestamps (use `flutter_local_notifications` + `timezone` package for correct behavior across DST and timezones).


3) Database / Persistence

Goal: Replace the in-memory repository implementations with persistent storage so tasks, events, preferences, and cached AI recommendations persist across app restarts.

Which DB to pick (options)
- SQLite (`sqflite`) — relational, robust, single-file DB. Good if you need complex queries and relations.
- Hive — lightweight, fast, NoSQL-like, great for storing Dart objects with adapters, good for mobile.
- Isar — high-performance native DB with reactive queries.
- Firebase Firestore / Realtime Database — cloud-hosted if you need cross-device syncing and server backend.

Suggested approach for this project
- If you want local-only (owner of UI): use `sqflite` or `hive`.
  - `sqflite` for relational needs and complex queries (e.g., recurring events).
  - `hive` if you prefer simpler object persistence and speed.
- If multi-device sync or server-driven pushes are needed, add remote sync with Firestore or your own backend.

Repository implementation
- Replace `TaskRepositoryImpl` in `lib/data/repositories/task_repository.dart` with a DB-backed implementation (e.g., `TaskRepositorySqlite` or `TaskRepositoryHive`).
  - Keep the `TaskRepository` abstract interface unchanged so use-cases don't break.
  - Implement methods: `getTasks()`, `addTask(task)`, `updateTask(task)`, `deleteTask(id)`, `toggleTaskCompletion(id)`, `getUpcomingTasks()`.
- Replace `CalendarRepositoryImpl` in `lib/data/repositories/calendar_repository.dart` similarly.
- Add a `lib/services/db_service.dart` to centralize DB initialization and migrations. Use `setupDependencies()` in `injection_container.dart` to async initialize DB and pass the DB instance to repository constructors.

Schema & models
- Use existing models: `Task`, `CalendarEvent`.
- Choose schema mapping (for sqflite): convert `Task.toMap()` and `Task.fromMap()` (already present) for persistence.
- For Hive: register TypeAdapters for `Task` and `CalendarEvent`.

Migration and sync
- If implementing remote sync, keep a local change log (last-updated timestamps) on models to resolve conflicts.
- Use timestamps `createdAt` and `updatedAt` (the models already contain these fields) to help with synchronization.


Wiring example (where to place code)

- `lib/injection_container.dart` (ServiceLocator)
  - Initialize DB and Notification plugin in `setupDependencies()`. Example:
    - Make `setupDependencies()` async, initialize DBService, call `await DBService.init()`, then create DB-backed repositories and replace the `*RepositoryImpl` instances.

- `lib/domain/use_cases/*` (existing) should continue to use abstract repository interfaces; they do not need to change.

- `lib/presentation/viewmodels/home_viewmodel.dart`
  - Replace mock `HomeViewModel.create()` usage at UI with provider-backed instance (already done). Add calls to `getAIRecommendationsUseCase` when tasks are loaded or changed.
  - On adding a task with a `reminder` field set, call `ScheduleNotificationUseCase` (which talks to `NotificationService`).

- `lib/presentation/pages/*` and `widgets/*`
  - The UI should call ViewModel methods (e.g., `viewModel.addTask(...)`) and observe changes via Provider.


Security & secrets
- Never check API keys into the repo. Use `flutter_dotenv` or CI secrets. Add instructions to your environment docs and `.gitignore` any local key files.
- For server-based AI, tokens should be stored and used server-side where possible. If calling AI directly from app, ensure key usage limits and user-consent policies are adhered to.


Suggested packages (add to `pubspec.yaml` as needed)
- Networking: `http` or `dio`
- AI: `openai` (community package) or direct `http` calls to your provider
- DB: `sqflite` / `path_provider` or `hive` / `hive_flutter` or `isar`
- Notifications: `flutter_local_notifications`, `firebase_messaging`, `timezone`
- Voice / Speech: `speech_to_text`, `flutter_tts` (if you implement voice input/output on-device)
- Env: `flutter_dotenv` for API key management
- Others: `provider` (already present), `intl` (already present) for formatting

Example `pubspec.yaml` additions (illustrative)

```yaml
dependencies:
  http: ^0.13.6
  flutter_dotenv: ^5.0.2
  firebase_core: ^2.10.0
  firebase_messaging: ^14.0.3
  flutter_local_notifications: ^13.0.0
  sqflite: ^2.2.5+1
  path_provider: ^2.0.13
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  speech_to_text: ^5.9.0
  flutter_tts: ^4.3.2
```

(Adjust versions according to compatibility with your Flutter SDK.)


Testing and verification

- Unit tests (Dart) for use-cases and repositories. Example tests to add:
  - `test/domain/use_cases/get_tasks_use_case_test.dart` — mock `TaskRepository` and assert `GetTasksUseCase` returns expected tasks.
  - `test/presentation/viewmodels/home_viewmodel_test.dart` — use a fake repository to verify `loadTasks()` and `addTask()` behaviors.

- Integration tests for Flutter pages if the UI is ready (use `flutter_test` and `integration_test`).

- Manual verification steps (run locally):

```bash
# fetch packages
flutter pub get

# static analysis
flutter analyze

# run tests
flutter test

# run app on connected device
flutter run
```


Development tips and checklist before merging

- Implement features behind feature flags or toggles so you can enable/disable AI or push features in QA.
- Add Analytics and error reporting (Sentry) if you plan to monitor production behavior.
- Add a migration plan if you switch the repository implementation (migrate existing users or provide export/import).
- Document any architectural decisions in code comments and in this README.


Example integration flows (concise)

- Adding a Task with reminder
  1. UI dialog collects task fields including `reminder` (hour/minute) and calls `HomeViewModel.addTask(task)`.
  2. `HomeViewModel.addTask` calls `AddTaskUseCase`.
  3. `AddTaskUseCase` persists task using `TaskRepository.addTask(task)` (DB-backed impl).
  4. If `task.reminder` != null, `AddTaskUseCase` calls `ScheduleNotificationUseCase` to schedule a local notification.

- AI recommendations generation
  1. `HomeViewModel` (or `AIRecommendationsViewModel`) calls `GetAIRecommendationsUseCase`.
  2. The use-case calls `AIService.getRecommendationsForUser(tasks, events)`.
  3. `AIService` sends a prompt to the chosen AI provider and parses the structured result.
  4. Use-case returns `List<AIRecommendation>` to the ViewModel. UI displays them in `HomePage`.


Contributor notes

- Keep the `TaskRepository` interface stable. Prefer adding new methods to the interface instead of changing signatures.
- If you need to persist settings (like language and theme), consider using `SharedPreferences` or the DB.
- Expose critical initialization in `setupDependencies()` and avoid creating global state in random files.


Appendix: Where to add files (quick map)

- `lib/services/ai_service.dart` — AI client & parsing
- `lib/services/notification_service.dart` — FCM and local notification wrapper
- `lib/services/db_service.dart` — DB initialization + helpers
- `lib/data/repositories/task_repository_sqlite.dart` — new DB-backed repository
- `lib/data/repositories/calendar_repository_sqlite.dart` — new DB-backed repository
- `lib/domain/use_cases/get_ai_recommendations_use_case.dart` — new use case
- `lib/domain/use_cases/schedule_notification_use_case.dart` — new use case
- `lib/presentation/viewmodels/ai_viewmodel.dart` — optional specialized ViewModel for AI suggestions


If you want, I can:
- Scaffold basic implementations for `AIService`, `NotificationService`, and `DBService` (small starter files)
- Generate example sqlite-backed `TaskRepository` using `sqflite` and show how to wire `setupDependencies()` (async initialization)
- Add example unit tests for `HomeViewModel` using a fake repository

Tell me which of the scaffold tasks you want me to implement next and I'll create the files and wire them into the project.
