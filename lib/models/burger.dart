import 'package:equatable/equatable.dart';
import 'enums.dart';

/// A menu item. All fields strictly typed — no Map<String, dynamic> passed
/// around the app as "data" (spec 3.7).
class Burger extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final int priceRs;
  final int prepTimeMinLow;
  final int prepTimeMinHigh;
  final SpiceLevel spiceLevel;
  final BunType bunType;
  final PattyType pattyType;
  final int calories;
  final int proteinG;
  final String description;
  /// A real photo fetched opportunistically from the Foodish API and
  /// cached locally. Null until successfully resolved — the UI always
  /// falls back to the guaranteed BurgerIllustration when this is null.
  final String? resolvedPhotoUrl;

  const Burger({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.priceRs,
    required this.prepTimeMinLow,
    required this.prepTimeMinHigh,
    required this.spiceLevel,
    required this.bunType,
    required this.pattyType,
    required this.calories,
    required this.proteinG,
    required this.description,
    this.resolvedPhotoUrl,
  });

  String get prepTimeLabel => '$prepTimeMinLow–$prepTimeMinHigh min';

  Burger copyWith({String? resolvedPhotoUrl}) => Burger(
        id: id,
        name: name,
        imageUrl: imageUrl,
        priceRs: priceRs,
        prepTimeMinLow: prepTimeMinLow,
        prepTimeMinHigh: prepTimeMinHigh,
        spiceLevel: spiceLevel,
        bunType: bunType,
        pattyType: pattyType,
        calories: calories,
        proteinG: proteinG,
        description: description,
        resolvedPhotoUrl: resolvedPhotoUrl ?? this.resolvedPhotoUrl,
      );

  factory Burger.fromMap(Map<String, Object?> map) => Burger(
        id: map['id'] as String,
        name: map['name'] as String,
        imageUrl: map['imageUrl'] as String,
        priceRs: map['priceRs'] as int,
        prepTimeMinLow: map['prepTimeMinLow'] as int,
        prepTimeMinHigh: map['prepTimeMinHigh'] as int,
        spiceLevel: SpiceLevel.fromDb(map['spiceLevel'] as String),
        bunType: BunType.fromDb(map['bunType'] as String),
        pattyType: PattyType.fromDb(map['pattyType'] as String),
        calories: map['calories'] as int,
        proteinG: map['proteinG'] as int,
        description: map['description'] as String,
        resolvedPhotoUrl: map['resolvedPhotoUrl'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'priceRs': priceRs,
        'prepTimeMinLow': prepTimeMinLow,
        'prepTimeMinHigh': prepTimeMinHigh,
        'spiceLevel': spiceLevel.name,
        'bunType': bunType.name,
        'pattyType': pattyType.name,
        'calories': calories,
        'proteinG': proteinG,
        'description': description,
        'resolvedPhotoUrl': resolvedPhotoUrl,
      };

  @override
  List<Object?> get props => [id, name, priceRs];
}

/// Seed data mirroring mustav.vercel.app/menu exactly (fetched 2026-07-15).
/// Used to seed the local DB on first launch, and as offline fallback if the
/// remote source is unreachable and the cache is empty.
class MenuSeed {
  static const List<Burger> burgers = [
    Burger(
      id: 'classic-smash',
      name: 'Classic Smash',
      imageUrl: 'https://loremflickr.com/800/600/burger,cheeseburger?lock=101',
      priceRs: 850,
      prepTimeMinLow: 10,
      prepTimeMinHigh: 12,
      spiceLevel: SpiceLevel.mild,
      bunType: BunType.brioche,
      pattyType: PattyType.beef,
      calories: 720,
      proteinG: 32,
      description:
          'Smashed hot on the flat top — our prime beef patty locks in ultimate juiciness under a caramelized crust.',
    ),
    Burger(
      id: 'spicy-jalapeno',
      name: 'Spicy Jalapeño',
      imageUrl: 'https://loremflickr.com/800/600/burger,spicy?lock=102',
      priceRs: 950,
      prepTimeMinLow: 12,
      prepTimeMinHigh: 14,
      spiceLevel: SpiceLevel.hot,
      bunType: BunType.brioche,
      pattyType: PattyType.beef,
      calories: 810,
      proteinG: 34,
      description: 'Loaded with fresh jalapeños and a fiery kick for those who crave the heat.',
    ),
    Burger(
      id: 'bacon-cheese',
      name: 'Bacon Cheese',
      imageUrl: 'https://loremflickr.com/800/600/burger,bacon?lock=103',
      priceRs: 1100,
      prepTimeMinLow: 12,
      prepTimeMinHigh: 15,
      spiceLevel: SpiceLevel.mild,
      bunType: BunType.brioche,
      pattyType: PattyType.beef,
      calories: 900,
      proteinG: 37,
      description: 'Crispy bacon and melted cheddar stacked on our signature smashed patty.',
    ),
    Burger(
      id: 'veggie-delight',
      name: 'Veggie Delight',
      imageUrl: 'https://loremflickr.com/800/600/burger,vegetarian?lock=104',
      priceRs: 750,
      prepTimeMinLow: 10,
      prepTimeMinHigh: 12,
      spiceLevel: SpiceLevel.mild,
      bunType: BunType.sesame,
      pattyType: PattyType.veggie,
      calories: 620,
      proteinG: 17,
      description: 'A hearty plant-based patty on a toasted sesame bun, fully loaded and fresh.',
    ),
    Burger(
      id: 'bbq-ranch',
      name: 'BBQ Ranch',
      imageUrl: 'https://loremflickr.com/800/600/burger,bbq?lock=105',
      priceRs: 1000,
      prepTimeMinLow: 12,
      prepTimeMinHigh: 14,
      spiceLevel: SpiceLevel.medium,
      bunType: BunType.brioche,
      pattyType: PattyType.beef,
      calories: 870,
      proteinG: 36,
      description: 'Smoky BBQ glaze and cool ranch drizzle over a caramelized smashed patty.',
    ),
    Burger(
      id: 'mushroom-swiss',
      name: 'Mushroom Swiss',
      imageUrl: 'https://loremflickr.com/800/600/burger,mushroom?lock=106',
      priceRs: 1050,
      prepTimeMinLow: 12,
      prepTimeMinHigh: 14,
      spiceLevel: SpiceLevel.mild,
      bunType: BunType.brioche,
      pattyType: PattyType.beef,
      calories: 830,
      proteinG: 33,
      description: 'Sautéed mushrooms and melted Swiss cheese folded into every bite.',
    ),
  ];
}