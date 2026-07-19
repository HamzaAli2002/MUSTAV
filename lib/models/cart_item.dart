import 'package:equatable/equatable.dart';
import 'addon.dart';
import 'burger.dart';

/// A single line in the cart. Immutable — updates produce a new CartItem.
/// All money is stored/computed as integer PKR (no floating point drift,
/// no string concatenation of currency per spec 3.2).
class CartItem extends Equatable {
  final String cartItemId; // unique per line, so identical burger+addons combos can coexist
  final Burger burger;
  final List<AddOn> addOns;
  final int quantity;

  const CartItem({
    required this.cartItemId,
    required this.burger,
    required this.addOns,
    required this.quantity,
  });

  /// Price of a single unit including its add-ons.
  int get unitPriceRs => burger.priceRs + addOns.fold(0, (sum, a) => sum + a.priceRs);

  /// Total for this line (unit price × quantity).
  int get lineTotalRs => unitPriceRs * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        cartItemId: cartItemId,
        burger: burger,
        addOns: addOns,
        quantity: quantity ?? this.quantity,
      );

  factory CartItem.fromMap(Map<String, Object?> map, {
    required Burger burger,
    required List<AddOn> addOns,
  }) =>
      CartItem(
        cartItemId: map['cartItemId'] as String,
        burger: burger,
        addOns: addOns,
        quantity: map['quantity'] as int,
      );

  Map<String, Object?> toMap() => {
        'cartItemId': cartItemId,
        'burgerId': burger.id,
        'quantity': quantity,
        // addOns are stored in a join table (cart_item_addons) — see AppDatabase
      };

  @override
  List<Object?> get props => [cartItemId, burger, addOns, quantity];
}
