import '../../models/burger.dart';
import '../db/app_database.dart';

/// Cache-first menu access. There's no real MUSTAV public API, so "remote
/// fetch" is simulated with a short delay against the known-good seed data
/// (spec explicitly allows simulating a backend). The important behavior
/// this repository guarantees:
///  - first launch: seed + cache the menu
///  - online: attempt a refresh, update cache silently
///  - offline or refresh failure: serve whatever is already cached, never
///    throw, never leave the screen blank (spec 3.5)
class MenuRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Burger>> getMenu({required bool isOnline}) async {
    final cached = await _db.readCachedMenu();

    if (!isOnline) {
      if (cached.isNotEmpty) return cached;
      return MenuSeed.burgers; // last-resort fallback, never a blank screen
    }

    try {
      final fresh = await _simulatedRemoteFetch();
      await _db.cacheMenu(fresh);
      return fresh;
    } catch (_) {
      // Network flaked mid-refresh — serve cache instead of failing the screen.
      if (cached.isNotEmpty) return cached;
      return MenuSeed.burgers;
    }
  }

  Future<DateTime?> lastCachedAt() => _db.menuCachedAt();

  Future<List<Burger>> _simulatedRemoteFetch() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MenuSeed.burgers;
  }
}
