import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'models/enums.dart';
import 'providers/order_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/order_tracking/order_tracking_screen.dart';
import 'widgets/mustav_loader.dart';

class MustavApp extends ConsumerWidget {
  const MustavApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MUSTAV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const _StartupGate(),
    );
  }
}

/// On cold start: shows the site's yellow burger-building loader for a
/// beat (matching the real site's page-transition animation), then checks
/// whether an order was in flight when the app was last killed and
/// resumes tracking it instead of dropping the user back at the menu with
/// no context.
class _StartupGate extends ConsumerStatefulWidget {
  const _StartupGate();

  @override
  ConsumerState<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<_StartupGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const Scaffold(body: MustavLoader());
    }

    final latestOrder = ref.watch(latestOrderProvider);

    return latestOrder.when(
      loading: () => const Scaffold(body: MustavLoader()),
      error: (_, __) => const HomeScreen(),
      data: (order) {
        if (order != null && order.status != OrderStatus.delivered) {
          Future.microtask(() => ref.read(checkoutProvider.notifier).resumeOrder(order));
          return const OrderTrackingScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
