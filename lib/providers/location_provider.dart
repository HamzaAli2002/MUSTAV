import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/location_repository.dart';
import '../models/enums.dart';
import '../models/store_location.dart';
import '../services/geolocation_service.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) => LocationRepository());
final geolocationServiceProvider = Provider<GeolocationService>((ref) => GeolocationService());

final storesProvider = FutureProvider<List<StoreLocation>>((ref) {
  return ref.watch(locationRepositoryProvider).getLocations();
});

enum LocationResolutionStatus { idle, resolving, resolved, permissionDenied, serviceDisabled, gpsUnavailable }

class SelectedLocationState {
  final StoreLocation? location;
  final LocationResolutionStatus status;
  final double? distanceKm; // known only when resolved via GPS

  const SelectedLocationState({this.location, this.status = LocationResolutionStatus.idle, this.distanceKm});

  SelectedLocationState copyWith({StoreLocation? location, LocationResolutionStatus? status, double? distanceKm}) =>
      SelectedLocationState(
        location: location ?? this.location,
        status: status ?? this.status,
        distanceKm: distanceKm ?? this.distanceKm,
      );
}

/// Drives spec 3.3 end-to-end: request permission with rationale, use real
/// geolocation to suggest the nearest store, and fall back gracefully to
/// manual selection on denial/failure — never crashing, never a dead end.
class SelectedLocationNotifier extends AsyncNotifier<SelectedLocationState> {
  @override
  Future<SelectedLocationState> build() async {
    final repo = ref.watch(locationRepositoryProvider);
    final stores = await ref.watch(storesProvider.future);
    final savedCity = await repo.getSelectedCity();
    if (savedCity != null) {
      final match = stores.where((s) => s.city.name == savedCity);
      if (match.isNotEmpty) {
        return SelectedLocationState(location: match.first, status: LocationResolutionStatus.resolved);
      }
    }
    return const SelectedLocationState(status: LocationResolutionStatus.idle);
  }

  Future<void> resolveViaGps() async {
    state = AsyncData(state.valueOrNull?.copyWith(status: LocationResolutionStatus.resolving) ??
        const SelectedLocationState(status: LocationResolutionStatus.resolving));

    final geoService = ref.read(geolocationServiceProvider);
    final permissionResult = await geoService.requestPermission();

    if (permissionResult == LocationPermissionResult.serviceDisabled) {
      state = AsyncData(SelectedLocationState(status: LocationResolutionStatus.serviceDisabled));
      return;
    }
    if (permissionResult == LocationPermissionResult.deniedGraceful) {
      state = AsyncData(SelectedLocationState(status: LocationResolutionStatus.permissionDenied));
      return;
    }

    final position = await geoService.currentPosition();
    if (position == null) {
      // GPS failed/timed out — graceful fallback, no crash, no dead end.
      state = AsyncData(SelectedLocationState(status: LocationResolutionStatus.gpsUnavailable));
      return;
    }

    final stores = await ref.read(storesProvider.future);
    final nearest = geoService.nearestStore(position.latitude, position.longitude, stores);
    final distanceKm = geoService.distanceToStoreKm(position.latitude, position.longitude, nearest);
    await selectManually(nearest, distanceKm: distanceKm);
  }

  Future<void> selectManually(StoreLocation location, {double? distanceKm}) async {
    final repo = ref.read(locationRepositoryProvider);
    await repo.setSelectedCity(location.city.name);
    state = AsyncData(SelectedLocationState(
      location: location,
      status: LocationResolutionStatus.resolved,
      distanceKm: distanceKm, // null for manual picks — fee falls back to base
    ));
  }
}

final selectedLocationProvider =
    AsyncNotifierProvider<SelectedLocationNotifier, SelectedLocationState>(SelectedLocationNotifier.new);
