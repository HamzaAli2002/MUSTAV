import '../../models/burger.dart';
import '../../models/cart_item.dart';
import '../db/app_database.dart';

class CartRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<CartItem>> loadCart(List<Burger> menu) => _db.readCart(menu);

  Future<void> save(CartItem item) => _db.upsertCartItem(item);

  Future<void> remove(String cartItemId) => _db.removeCartItem(cartItemId);

  Future<void> clear() => _db.clearCart();
}
