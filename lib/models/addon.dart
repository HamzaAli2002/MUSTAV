import 'package:equatable/equatable.dart';

/// A structured, typed add-on/customization option (spec 3.1).
/// Never represented as free text.
class AddOn extends Equatable {
  final String id;
  final String name;
  final int priceRs; // additional price in PKR, integer (no float currency math)
  final bool isRemoval; // true for "no onions"-style removals (priceRs == 0 typically)

  const AddOn({
    required this.id,
    required this.name,
    required this.priceRs,
    this.isRemoval = false,
  });

  factory AddOn.fromMap(Map<String, Object?> map) => AddOn(
        id: map['id'] as String,
        name: map['name'] as String,
        priceRs: map['priceRs'] as int,
        isRemoval: (map['isRemoval'] as int) == 1,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'priceRs': priceRs,
        'isRemoval': isRemoval ? 1 : 0,
      };

  @override
  List<Object?> get props => [id, name, priceRs, isRemoval];
}

/// Canonical add-on catalog. MUSTAV's live site doesn't expose add-ons,
/// so this is modeled here as structured, typed data per spec.
class AddOnCatalog {
  static const List<AddOn> all = [
    AddOn(id: 'extra_cheese', name: 'Extra Cheese', priceRs: 100),
    AddOn(id: 'extra_patty', name: 'Extra Patty', priceRs: 250),
    AddOn(id: 'add_bacon', name: 'Add Bacon', priceRs: 150),
    AddOn(id: 'spicy_mayo', name: 'Spicy Mayo', priceRs: 50),
    AddOn(id: 'no_onions', name: 'No Onions', priceRs: 0, isRemoval: true),
    AddOn(id: 'no_pickles', name: 'No Pickles', priceRs: 0, isRemoval: true),
    AddOn(id: 'extra_sauce', name: 'Extra Chili Honey Glaze', priceRs: 80),
  ];

  static AddOn byId(String id) => all.firstWhere((a) => a.id == id);
}
