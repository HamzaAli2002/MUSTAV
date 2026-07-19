import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/addon.dart';
import '../../models/burger.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/cart_badge.dart';
import '../../widgets/marquee_ticker.dart';
import '../../widgets/offline_banner.dart';
import '../home/home_screen.dart';
import '../location/location_picker_screen.dart';
import '../product_detail/product_detail_screen.dart';
import 'widgets/burger_card.dart';
import 'widgets/filter_chips.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredMenu = ref.watch(filteredMenuProvider);
    final selectedLocation = ref.watch(selectedLocationProvider).valueOrNull?.location;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          ),
        ),
        title: InkWell(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          ),
          child: Text('MUSTAV', style: AppTheme.display(size: 22, color: AppColors.red)),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
            ),
            icon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.inkSoft),
            label: Text(
              selectedLocation?.city.label ?? 'Select store',
              style: AppTheme.body(size: 12, color: AppColors.inkSoft, weight: FontWeight.w600),
            ),
          ),
          const CartBadgeIcon(),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Container(
            width: double.infinity,
            color: AppColors.maroon,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THE BEST', style: AppTheme.body(size: 12, color: AppColors.yellow, weight: FontWeight.w800).copyWith(letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('EAT LIKE\nYOU MEAN IT', style: AppTheme.display(size: 26, color: Colors.white)),
              ],
            ),
          ),
          const MarqueeTicker(text: 'BOLD • FRESH • CRAVE •', backgroundColor: AppColors.red, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.2)),
          const FilterChipsBar(),
          Expanded(
            child: filteredMenu.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.red)),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "Couldn't load the menu right now. Pull to refresh once you're back online.",
                    style: AppTheme.body(color: AppColors.inkSoft),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (burgers) {
                if (burgers.isEmpty) {
                  return Center(
                    child: Text('No burgers match your filters.', style: AppTheme.body(color: AppColors.inkSoft)),
                  );
                }
                // ListView.builder virtualizes automatically — off-screen
                // cards are never built/kept in memory (spec 3.6).
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: burgers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Text('OUR FINEST BURGER PICKS', style: AppTheme.display(size: 18, color: AppColors.ink)),
                            const Spacer(),
                            Text('${burgers.length} items', style: AppTheme.body(size: 12, color: AppColors.inkSoft)),
                          ],
                        ),
                      );
                    }
                    final burger = burgers[index - 1];
                    return BurgerCard(
                      burger: burger,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProductDetailScreen(burger: burger)),
                      ),
                      onAddToCart: () => _quickAdd(context, ref, burger),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _quickAdd(BuildContext context, WidgetRef ref, Burger burger) {
    ref.read(cartProvider.notifier).addItem(burger, const <AddOn>[]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Added to Cart · ${burger.name}'),
          ],
        ),
        duration: const Duration(milliseconds: 1000),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
