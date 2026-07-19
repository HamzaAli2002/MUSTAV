import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';
import '../../models/store_location.dart';
import '../../providers/location_provider.dart';

/// Uses OpenStreetMap tiles via flutter_map — completely free, no API key
/// and no billing account required (unlike Google Maps SDK). Satisfies
/// spec 3.3's "native map view" requirement via the "or equivalent" clause.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider);
    final selectedState = ref.watch(selectedLocationProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your store')),
      body: storesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, st) =>
            const Center(child: Text('Could not load store locations.')),
        data: (stores) {
          return Column(
            children: [
              SizedBox(
                height: 220,
                child: FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(
                        31.5204, 74.3587), // centered on Lahore by default
                    initialZoom: 5.2,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.khizex.mustav_mobile',
                    ),
                    MarkerLayer(
                      markers: stores
                          .map((s) => Marker(
                                point: LatLng(s.latitude, s.longitude),
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on,
                                    color: AppColors.accent, size: 34),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: selectedState?.status ==
                            LocationResolutionStatus.resolving
                        ? null
                        : () async {
                            await ref
                                .read(selectedLocationProvider.notifier)
                                .resolveViaGps();
                            _handleResolutionResult(context, ref);
                          },
                    icon: selectedState?.status ==
                            LocationResolutionStatus.resolving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: Text(
                      selectedState?.status ==
                              LocationResolutionStatus.resolving
                          ? 'Finding your location…'
                          : 'Use my current location',
                    ),
                  ),
                ),
              ),
              if (selectedState?.status ==
                  LocationResolutionStatus.permissionDenied)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Location permission wasn't granted — pick your city below instead.",
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ),
              if (selectedState?.status ==
                  LocationResolutionStatus.serviceDisabled)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Location services are off on this device — pick your city below instead.",
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ),
              if (selectedState?.status ==
                  LocationResolutionStatus.gpsUnavailable)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Couldn't get a GPS fix (try moving near a window) — pick your city below instead.",
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Or pick manually',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    final isSelected =
                        selectedState?.location?.city == store.city;
                    return _StoreTile(
                      store: store,
                      isSelected: isSelected,
                      onTap: () async {
                        await ref
                            .read(selectedLocationProvider.notifier)
                            .selectManually(store);
                        _mapController.move(
                            LatLng(store.latitude, store.longitude), 11);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleResolutionResult(BuildContext context, WidgetRef ref) {
    final result = ref.read(selectedLocationProvider).valueOrNull;
    if (result?.status == LocationResolutionStatus.resolved) {
      final loc = result?.location;
      if (loc != null)
        _mapController.move(LatLng(loc.latitude, loc.longitude), 11);
      if (context.mounted) Navigator.of(context).pop();
    }
    // permissionDenied / serviceDisabled cases just render inline messaging
    // above — no crash, no dead-end screen (spec 3.3).
  }
}

class _StoreTile extends StatelessWidget {
  final StoreLocation store;
  final bool isSelected;
  final VoidCallback onTap;

  const _StoreTile(
      {required this.store, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color:
          isSelected ? AppColors.accent.withOpacity(0.15) : AppColors.surface,
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.storefront,
            color: isSelected ? AppColors.accent : AppColors.textSecondary),
        title: Text(store.city.label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(store.tagline,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.accent)
            : null,
      ),
    );
  }
}
