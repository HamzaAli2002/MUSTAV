import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/location_provider.dart';
import '../checkout/checkout_screen.dart';
import '../location/location_picker_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? false;
    final locationState = ref.watch(selectedLocationProvider).valueOrNull;
    final selectedLocation = locationState?.location;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: Text(
          'YOUR CART${cartAsync.valueOrNull != null ? ' (${cartAsync.valueOrNull!.fold(0, (s, i) => s + i.quantity)})' : ''}',
          style: AppTheme.display(size: 18, color: AppColors.ink),
        ),
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.red)),
        error: (e, st) => const Center(child: Text('Could not load your cart.')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    'https://mustav.vercel.app/images/general/empty-cart.png',
                    width: 96,
                    height: 96,
                    errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 12),
                  Text('Hungry? Add items to start your order.', style: AppTheme.body(color: AppColors.inkSoft)),
                ],
              ),
            );
          }

          final subtotal = items.fold(0, (sum, i) => sum + i.lineTotalRs);
          final delivery = computeDeliveryFeeRs(locationState?.distanceKm);
          final total = subtotal + delivery;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _CartLine(item: items[index]),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              selectedLocation != null
                                  ? 'Delivering from ${selectedLocation.city.label}'
                                  : 'Select a store location',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                      _PriceRow('Subtotal', subtotal),
                      _PriceRow('Delivery fee', delivery),
                      const Divider(height: 20),
                      _PriceRow('Total', total, emphasized: true),
                      const SizedBox(height: 14),
                      if (!isOnline)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            "You're offline — connect to place your order.",
                            style: TextStyle(color: AppColors.warning, fontSize: 12),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (!isOnline || selectedLocation == null)
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                                  ),
                          child: const Text('CHECKOUT'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  final CartItem item;
  const _CartLine({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(item.burger.imageUrl, width: 64, height: 64, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.burger.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (item.addOns.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.addOns.map((a) => a.name).join(', '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 6),
                Text('Rs. ${item.lineTotalRs}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => notifier.updateQuantity(item.cartItemId, item.quantity - 1),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                  ),
                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => notifier.updateQuantity(item.cartItemId, item.quantity + 1),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => notifier.removeItem(item.cartItemId),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger, padding: EdgeInsets.zero),
                child: const Text('Remove', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final int amountRs;
  final bool emphasized;
  const _PriceRow(this.label, this.amountRs, {this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500,
      fontSize: emphasized ? 17 : 14,
      color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('Rs. $amountRs', style: style),
        ],
      ),
    );
  }
}
