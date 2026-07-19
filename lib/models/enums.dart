/// Strictly typed enums — never pass these around as raw strings/dynamic.
library;

enum SpiceLevel {
  mild,
  medium,
  hot;

  String get label => switch (this) {
        SpiceLevel.mild => 'Mild',
        SpiceLevel.medium => 'Medium',
        SpiceLevel.hot => 'Hot',
      };

  static SpiceLevel fromDb(String value) => SpiceLevel.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SpiceLevel.mild,
      );
}

enum BunType {
  brioche,
  sesame;

  String get label => switch (this) {
        BunType.brioche => 'Brioche',
        BunType.sesame => 'Sesame',
      };

  static BunType fromDb(String value) => BunType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => BunType.brioche,
      );
}

enum PattyType {
  beef,
  veggie;

  String get label => switch (this) {
        PattyType.beef => 'Beef',
        PattyType.veggie => 'Veggie',
      };

  static PattyType fromDb(String value) => PattyType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PattyType.beef,
      );
}

/// Order lifecycle — matches spec 3.4 exactly.
enum OrderStatus {
  received,
  preparing,
  readyOrOutForDelivery,
  delivered,
  failed;

  String get label => switch (this) {
        OrderStatus.received => 'Received',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.readyOrOutForDelivery => 'Ready / Out for Delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.failed => 'Failed',
      };

  static OrderStatus fromDb(String value) => OrderStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => OrderStatus.received,
      );
}

enum CityName {
  lahore,
  islamabad,
  rawalpindi,
  multan;

  String get label => switch (this) {
        CityName.lahore => 'Lahore',
        CityName.islamabad => 'Islamabad',
        CityName.rawalpindi => 'Rawalpindi',
        CityName.multan => 'Multan',
      };

  static CityName fromDb(String value) => CityName.values.firstWhere(
        (e) => e.name == value,
        orElse: () => CityName.lahore,
      );
}

/// Pakistani mobile-wallet + card options shown on the real site's
/// checkout page.
enum PaymentMethod {
  easyPaisa,
  jazzCash,
  card;

  String get label => switch (this) {
        PaymentMethod.easyPaisa => 'EasyPaisa',
        PaymentMethod.jazzCash => 'JazzCash',
        PaymentMethod.card => 'Credit / Debit Card',
      };

  String get subtitle => switch (this) {
        PaymentMethod.easyPaisa => 'Pay via EasyPaisa mobile account',
        PaymentMethod.jazzCash => 'Pay via JazzCash mobile account',
        PaymentMethod.card => 'Pay with Visa or Mastercard',
      };

  bool get requiresAccountNumber => this == PaymentMethod.easyPaisa || this == PaymentMethod.jazzCash;
}
