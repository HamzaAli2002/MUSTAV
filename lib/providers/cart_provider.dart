import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/cart_repository.dart';
import '../models/addon.dart';
import '../models/burger.dart';
import '../models/cart_item.dart';
import 'menu_provider.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) => CartRepository());

/// Cart state lives in memory for instant UI updates, but every mutation is
/// written to SQLite immediately (not just on background/close) — spec 3.2.
/// On construction it rehydrates from disk, so a force-killed app resumes
/// exactly where it left off.
class CartNotifier extends AsyncNotifier<List<CartItem>> {
  static const _uuid = Uuid();

  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  Future<List<CartItem>> build() async {
    final menu = await ref.watch(menuProvider.future);
    return _repo.loadCart(menu);
  }

  Future<void> addItem(Burger burger, List<AddOn> addOns, {int quantity = 1}) async {
    final current = state.valueOrNull ?? [];

    // Merge into an existing identical line (same burger + same add-on set).
    final existingIndex = current.indexWhere(
      (item) => item.burger.id == burger.id && _sameAddOns(item.addOns, addOns),
    );

    List<CartItem> updated;
    CartItem changedItem;
    if (existingIndex != -1) {
      changedItem = current[existingIndex].copyWith(quantity: current[existingIndex].quantity + quantity);
      updated = [...current]..[existingIndex] = changedItem;
    } else {
      changedItem = CartItem(
        cartItemId: _uuid.v4(),
        burger: burger,
        addOns: addOns,
        quantity: quantity,
      );
      updated = [...current, changedItem];
    }

    state = AsyncData(updated);
    await _repo.save(changedItem); // persist immediately, not on app close
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    final current = state.valueOrNull ?? [];
    if (newQuantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    final index = current.indexWhere((i) => i.cartItemId == cartItemId);
    if (index == -1) return;
    final updatedItem = current[index].copyWith(quantity: newQuantity);
    final updated = [...current]..[index] = updatedItem;
    state = AsyncData(updated);
    await _repo.save(updatedItem);
  }

  Future<void> removeItem(String cartItemId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((i) => i.cartItemId != cartItemId).toList());
    await _repo.remove(cartItemId);
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    await _repo.clear();
  }

  bool _sameAddOns(List<AddOn> a, List<AddOn> b) {
    if (a.length != b.length) return false;
    final idsA = a.map((e) => e.id).toSet();
    final idsB = b.map((e) => e.id).toSet();
    return idsA.containsAll(idsB) && idsB.containsAll(idsA);
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

/// Cart badge count, kept in sync across every screen automatically since
/// it derives from the single source-of-truth cartProvider (spec 3.2).
final cartCountProvider = Provider.autoDispose<int>((ref) {
  final cart = ref.watch(cartProvider).valueOrNull ?? [];
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

final cartSubtotalProvider = Provider.autoDispose<int>((ref) {
  final cart = ref.watch(cartProvider).valueOrNull ?? [];
  return cart.fold(0, (sum, item) => sum + item.lineTotalRs);
});
