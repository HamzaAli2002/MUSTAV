import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/order_provider.dart';
import '../order_tracking/order_tracking_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _accountController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.easyPaisa;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutProvider);
    final cart = ref.watch(cartProvider).valueOrNull ?? [];
    final locationState = ref.watch(selectedLocationProvider).valueOrNull;
    final location = locationState?.location;

    ref.listen(checkoutProvider, (previous, next) {
      if (next.phase == CheckoutPhase.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
        );
      }
    });

    final subtotal = cart.fold(0, (sum, i) => sum + i.lineTotalRs);
    final delivery = computeDeliveryFeeRs(locationState?.distanceKm);
    final total = subtotal + delivery;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.maroon,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Text('CHECKOUT', style: AppTheme.display(size: 20, color: AppColors.yellow).copyWith(letterSpacing: 1)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionCard(
                  title: 'ORDER SUMMARY',
                  child: Column(
                    children: [
                      for (final item in cart)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text('${item.burger.name}  ×${item.quantity}', style: AppTheme.body(size: 13))),
                              Text('Rs. ${item.lineTotalRs}', style: AppTheme.body(size: 13, weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      const Divider(height: 20),
                      _row('Subtotal', subtotal),
                      _row('Delivery Fee', delivery),
                      const Divider(height: 20),
                      _row('Total', total, bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'DELIVERY DETAILS',
                  child: Column(
                    children: [
                      TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(labelText: 'Delivery Address · ${location?.city.label ?? ''}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'PAYMENT METHOD',
                  child: Column(
                    children: [
                      for (final method in PaymentMethod.values) _PaymentTile(
                        method: method,
                        selected: _selectedMethod == method,
                        onTap: () => setState(() => _selectedMethod = method),
                      ),
                      if (_selectedMethod.requiresAccountNumber) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _accountController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: '${_selectedMethod.label} Account Number'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You will receive a confirmation prompt on your phone.',
                          style: AppTheme.body(size: 11, color: AppColors.inkSoft),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (checkout.phase == CheckoutPhase.failed) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            checkout.errorMessage ?? 'Order failed to submit.',
                            style: AppTheme.body(size: 13, color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Your cart is safe — nothing was lost. Tap retry to resubmit.',
                    style: AppTheme.body(size: 12, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: checkout.phase == CheckoutPhase.submitting || location == null || cart.isEmpty
                        ? null
                        : () {
                            if (checkout.phase == CheckoutPhase.failed) {
                              ref.read(checkoutProvider.notifier).retry();
                            } else {
                              ref.read(checkoutProvider.notifier).submitOrder(items: cart, location: location, deliveryFeeRs: delivery);
                            }
                          },
                    child: checkout.phase == CheckoutPhase.submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(checkout.phase == CheckoutPhase.failed ? 'RETRY ORDER' : 'PLACE ORDER — Rs. $total'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, int amount, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.body(weight: bold ? FontWeight.w800 : FontWeight.w500, size: bold ? 15 : 13)),
            Text('Rs. $amount', style: AppTheme.body(weight: bold ? FontWeight.w800 : FontWeight.w500, size: bold ? 15 : 13)),
          ],
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.display(size: 15, color: AppColors.ink)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentTile({required this.method, required this.selected, required this.onTap});

  Color get _iconColor => switch (method) {
        PaymentMethod.easyPaisa => const Color(0xFF3AA53A),
        PaymentMethod.jazzCash => AppColors.red,
        PaymentMethod.card => AppColors.orange,
      };

  IconData get _icon => switch (method) {
        PaymentMethod.easyPaisa => Icons.account_balance_wallet,
        PaymentMethod.jazzCash => Icons.smartphone,
        PaymentMethod.card => Icons.credit_card,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Radio<bool>(value: true, groupValue: selected ? true : null, onChanged: (_) => onTap(), activeColor: AppColors.red),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _iconColor.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(_icon, size: 16, color: _iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: AppTheme.body(size: 13, weight: FontWeight.w700)),
                  Text(method.subtitle, style: AppTheme.body(size: 10, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
