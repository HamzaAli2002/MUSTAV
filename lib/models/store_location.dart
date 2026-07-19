import 'package:equatable/equatable.dart';
import 'enums.dart';

class StoreLocation extends Equatable {
  final CityName city;
  final String address;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String tagline;

  const StoreLocation({
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.tagline,
  });

  factory StoreLocation.fromMap(Map<String, Object?> map) => StoreLocation(
        city: CityName.fromDb(map['city'] as String),
        address: map['address'] as String,
        latitude: map['latitude'] as double,
        longitude: map['longitude'] as double,
        imageUrl: map['imageUrl'] as String,
        tagline: map['tagline'] as String,
      );

  Map<String, Object?> toMap() => {
        'city': city.name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrl': imageUrl,
        'tagline': tagline,
      };

  @override
  List<Object?> get props => [city];
}

/// The four MUSTAV locations with real approximate city-center coordinates,
/// used for nearest-store geolocation matching (spec 3.3).
class LocationSeed {
  static const List<StoreLocation> stores = [
    StoreLocation(
      city: CityName.lahore,
      address: 'MUSTAV Flagship, Gulberg III, Lahore',
      latitude: 31.5204,
      longitude: 74.3587,
      imageUrl: 'https://picsum.photos/seed/mustav-lahore/700/700',
      tagline: 'Where tradition meets taste — our flagship kitchen.',
    ),
    StoreLocation(
      city: CityName.islamabad,
      address: 'MUSTAV Blue Area, Islamabad',
      latitude: 33.6844,
      longitude: 73.0479,
      imageUrl: 'https://picsum.photos/seed/mustav-islamabad/700/700',
      tagline: 'Capital flavors, crafted with precision.',
    ),
    StoreLocation(
      city: CityName.rawalpindi,
      address: 'MUSTAV Saddar, Rawalpindi',
      latitude: 33.5651,
      longitude: 73.0169,
      imageUrl: 'https://picsum.photos/seed/mustav-rawalpindi/700/700',
      tagline: 'Bold street-style smash burgers.',
    ),
    StoreLocation(
      city: CityName.multan,
      address: 'MUSTAV Cantt, Multan',
      latitude: 30.1575,
      longitude: 71.5249,
      imageUrl: 'https://picsum.photos/seed/mustav-multan/700/700',
      tagline: 'Southern hospitality in every bite.',
    ),
  ];
}
