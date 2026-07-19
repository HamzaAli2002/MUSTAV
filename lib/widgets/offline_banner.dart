import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOffline = isOnlineAsync.valueOrNull == false;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isOffline
          ? Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              color: AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    "You're offline — showing cached menu. Orders can't be placed right now.",
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('online')),
    );
  }
}
