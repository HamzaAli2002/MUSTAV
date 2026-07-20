import '../../models/burger.dart';
import '../../services/food_image_service.dart';
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
  final FoodImageService _foodImageService = FoodImageService();

  Future<List<Burger>> getMenu({required bool isOnline}) async {
    final cached = await _db.readCachedMenu();

    if (!isOnline) {
      if (cached.isNotEmpty) return cached;
      return MenuSeed.burgers; // last-resort fallback, never a blank screen
    }

    try {
      final fresh = await _simulatedRemoteFetch();
      // Preserve any already-resolved real photos across the "refresh" —
      // otherwise every refresh would wipe them and re-trigger fetching.
      final merged = fresh.map((b) {
        final existing = cached.where((c) => c.id == b.id).firstOrNull;
        return existing?.resolvedPhotoUrl != null
            ? b.copyWith(resolvedPhotoUrl: existing!.resolvedPhotoUrl)
            : b;
      }).toList();
      await _db.cacheMenu(merged);
      return merged;
    } catch (_) {
      // Network flaked mid-refresh — serve cache instead of failing the screen.
      if (cached.isNotEmpty) return cached;
      return MenuSeed.burgers;
    }
  }

  /// Fetches a real photo for each burger that doesn't have one yet, in
  /// parallel, persisting each result as soon as it resolves. Safe to call
  /// repeatedly — burgers that already failed simply stay on the
  /// illustration fallback until the next app launch tries again.
  Future<void> resolveMissingPhotos(List<Burger> burgers) async {
    await Future.wait(burgers.map((b) async {
      final url = await _foodImageService.fetchBurgerPhoto();
      if (url != null) {
        await _db.updateResolvedPhotoUrl(b.id, url);
      }
    }));
  }

  Future<DateTime?> lastCachedAt() => _db.menuCachedAt();

  Future<List<Burger>> _simulatedRemoteFetch() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MenuSeed.burgers;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
