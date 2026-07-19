import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/order_provider.dart';
import '../home/home_screen.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  static const _steps = [
    OrderStatus.received,
    OrderStatus.preparing,
    OrderStatus.readyOrOutForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(checkoutProvider).order;

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Order')),
        body: Center(child: Text('No active order.', style: AppTheme.body(color: AppColors.inkSoft))),
      );
    }

    final currentIndex = _steps.indexOf(order.status);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
          onPressed: () {
            ref.read(checkoutProvider.notifier).reset();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: InkWell(
          onTap: () {
            ref.read(checkoutProvider.notifier).reset();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
          child: Text('MUSTAV', style: AppTheme.display(size: 20, color: AppColors.red)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Matches the real site's "ORDER PLACED!" confirmation card exactly.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: Color(0xFFDFF3DF), shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Color(0xFF3AA53A), size: 30),
                ),
                const SizedBox(height: 14),
                Text('ORDER PLACED!', style: AppTheme.display(size: 20, color: AppColors.ink)),
                const SizedBox(height: 6),
                Text('Your order has been confirmed.', style: AppTheme.body(size: 13, color: AppColors.inkSoft)),
                const SizedBox(height: 10),
                Text('Total: Rs. ${order.totalRs}', style: AppTheme.display(size: 16, color: AppColors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(checkoutProvider.notifier).reset();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('ORDER MORE'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Order #${order.orderId.substring(0, 8)}', style: AppTheme.body(size: 12, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text('Delivering from ${order.location.city.label}', style: AppTheme.body(size: 12, color: AppColors.inkSoft)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _steps.length; i++)
                  _StatusStep(
                    label: _steps[i].label,
                    isDone: currentIndex >= i,
                    isLast: i == _steps.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You'll get a notification for each update, even if you close the app.",
            style: AppTheme.body(size: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isLast;

  const _StatusStep({required this.label, required this.isDone, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.red : AppColors.inkSoft.withOpacity(0.3);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: color)),
            ],
          ),
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              label,
              style: AppTheme.body(
                weight: isDone ? FontWeight.w700 : FontWeight.w400,
                color: isDone ? AppColors.ink : AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
