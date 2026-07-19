import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

import '../models/store_location.dart';

enum LocationPermissionResult { granted, deniedGraceful, serviceDisabled }

class GeolocationService {
  /// Requests permission with a clear rationale (spec 3.3). Never throws —
  /// any denial or disabled service falls back gracefully to manual pick.
  Future<LocationPermissionResult> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionResult.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return LocationPermissionResult.deniedGraceful;
    }
    return LocationPermissionResult.granted;
  }

  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      // Fresh GPS fix failed/timed out (common on emulators or indoors) —
      // try the device's last-known fix before giving up entirely.
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null; // caller falls back to manual selection
      }
    }
  }

  /// Finds the nearest of the four MUSTAV locations using real haversine
  /// distance — never a hardcoded default (spec 3.3).
  StoreLocation nearestStore(double lat, double lng, List<StoreLocation> stores) {
    StoreLocation? nearest;
    double bestDistanceKm = double.infinity;
    for (final store in stores) {
      final d = _haversineKm(lat, lng, store.latitude, store.longitude);
      if (d < bestDistanceKm) {
        bestDistanceKm = d;
        nearest = store;
      }
    }
    return nearest!;
  }

  /// Distance from the given coordinates to a specific store, in km — used
  /// to compute a distance-based delivery fee.
  double distanceToStoreKm(double lat, double lng, StoreLocation store) =>
      _haversineKm(lat, lng, store.latitude, store.longitude);

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);
}
