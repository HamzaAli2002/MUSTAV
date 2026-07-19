import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

/// True = online, false = offline. Defaults to true (assume online) until
/// the first check resolves, to avoid flashing the offline banner on cold
/// start unnecessarily.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.isOnline();
  yield* service.onStatusChange;
});
