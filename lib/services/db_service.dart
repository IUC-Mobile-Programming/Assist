/// Abstraction for a lightweight DB lifecycle manager. Implementations can be
/// backed by SQLite, Hive, or other persistent stores.
abstract class DbService {
  /// Initialize the DB and return once ready.
  Future<void> init();

  /// Close connections and free resources.
  Future<void> dispose();
}

/// A no-op in-memory DB service used for development and tests.
class InMemoryDbService implements DbService {
  @override
  Future<void> init() async {
    // nothing to init for in-memory
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> dispose() async {
    // no resources to dispose
  }
}

