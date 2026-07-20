import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/menu_repository.dart';
import '../models/burger.dart';
import '../models/enums.dart';
import 'connectivity_provider.dart';

final menuRepositoryProvider =
    Provider<MenuRepository>((ref) => MenuRepository());

/// The full menu, cache-first, refreshed opportunistically when online.
final menuProvider = FutureProvider.autoDispose<List<Burger>>((ref) async {
  final isOnlineAsync = await ref.watch(isOnlineProvider.future);
  final repo = ref.watch(menuRepositoryProvider);
  final burgers = await repo.getMenu(isOnline: isOnlineAsync);

  if (isOnlineAsync) {
    final missingPhotos =
        burgers.where((b) => b.resolvedPhotoUrl == null).toList();
    if (missingPhotos.isNotEmpty) {
      repo.resolveMissingPhotos(missingPhotos).then((_) {
        try {
          ref.invalidateSelf();
        } catch (_) {
          // Provider/widget already disposed — nothing to refresh.
        }
      });
    }
  }

  return burgers;
});

/// Filter chip selections — spice level and patty type. Re-filters the
/// already-cached/loaded list instantly with no network round trip (3.1).
class MenuFilterState {
  final SpiceLevel? spiceLevel;
  final PattyType? pattyType;

  const MenuFilterState({this.spiceLevel, this.pattyType});

  MenuFilterState copyWith({
    SpiceLevel? Function()? spiceLevel,
    PattyType? Function()? pattyType,
  }) =>
      MenuFilterState(
        spiceLevel: spiceLevel != null ? spiceLevel() : this.spiceLevel,
        pattyType: pattyType != null ? pattyType() : this.pattyType,
      );
}

class MenuFilterNotifier extends Notifier<MenuFilterState> {
  @override
  MenuFilterState build() => const MenuFilterState();

  void setSpiceLevel(SpiceLevel? level) {
    state = state.copyWith(spiceLevel: () => level);
  }

  void setPattyType(PattyType? type) {
    state = state.copyWith(pattyType: () => type);
  }

  void clear() {
    state = const MenuFilterState();
  }
}

final menuFilterProvider =
    NotifierProvider<MenuFilterNotifier, MenuFilterState>(
        MenuFilterNotifier.new);

/// The menu after filters are applied — pure, synchronous, instant.
final filteredMenuProvider =
    Provider.autoDispose<AsyncValue<List<Burger>>>((ref) {
  final menuAsync = ref.watch(menuProvider);
  final filter = ref.watch(menuFilterProvider);

  return menuAsync.whenData((menu) {
    return menu.where((b) {
      if (filter.spiceLevel != null && b.spiceLevel != filter.spiceLevel)
        return false;
      if (filter.pattyType != null && b.pattyType != filter.pattyType)
        return false;
      return true;
    }).toList();
  });
});
