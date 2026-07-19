import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/addon.dart';
import '../../models/burger.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/burger_illustration.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Burger burger;
  const ProductDetailScreen({super.key, required this.burger});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final Set<String> _selectedAddOnIds = {};
  int _quantity = 1;

  List<AddOn> get _selectedAddOns =>
      AddOnCatalog.all.where((a) => _selectedAddOnIds.contains(a.id)).toList();

  int get _unitPrice =>
      widget.burger.priceRs + _selectedAddOns.fold(0, (s, a) => s + a.priceRs);

  @override
  Widget build(BuildContext context) {
    final burger = widget.burger;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: BurgerIllustration(
                  size: 220, backgroundColor: AppColors.surfaceAlt),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(burger.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(burger.description,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 16),
                  _InfoChipsRow(burger: burger),
                  const SizedBox(height: 24),
                  const Text('Customize',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text(
                    'Structured add-ons — priced and typed, not free text.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ...AddOnCatalog.all.map((addOn) => _AddOnTile(
                        addOn: addOn,
                        selected: _selectedAddOnIds.contains(addOn.id),
                        onChanged: (checked) => setState(() {
                          if (checked) {
                            _selectedAddOnIds.add(addOn.id);
                          } else {
                            _selectedAddOnIds.remove(addOn.id);
                          }
                        }),
                      )),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(
                                () => _quantity = (_quantity - 1).clamp(1, 20)),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$_quantity',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          IconButton(
                            onPressed: () => setState(
                                () => _quantity = (_quantity + 1).clamp(1, 20)),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              ref
                  .read(cartProvider.notifier)
                  .addItem(burger, _selectedAddOns, quantity: _quantity);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${burger.name} added to cart'),
                    backgroundColor: AppColors.surfaceAlt),
              );
            },
            child: Text('Add to Cart · Rs. ${_unitPrice * _quantity}'),
          ),
        ),
      ),
    );
  }
}

class _InfoChipsRow extends StatelessWidget {
  final Burger burger;
  const _InfoChipsRow({required this.burger});

  @override
  Widget build(BuildContext context) {
    Widget stat(IconData icon, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        stat(Icons.schedule, burger.prepTimeLabel),
        stat(Icons.local_fire_department, burger.spiceLevel.label),
        stat(Icons.bakery_dining, '${burger.bunType.label} bun'),
        stat(Icons.set_meal, '${burger.pattyType.label} patty'),
        stat(Icons.local_dining, '${burger.calories} kcal'),
        stat(Icons.fitness_center, '${burger.proteinG}g protein'),
      ],
    );
  }
}

class _AddOnTile extends StatelessWidget {
  final AddOn addOn;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _AddOnTile(
      {required this.addOn, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: (v) => onChanged(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.accent,
      title: Text(addOn.name),
      subtitle: addOn.priceRs > 0
          ? Text('+Rs. ${addOn.priceRs}')
          : const Text('Free'),
    );
  }
}
