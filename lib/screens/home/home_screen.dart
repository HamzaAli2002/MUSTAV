import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/store_location.dart';
import '../../providers/location_provider.dart';
import '../../widgets/burger_illustration.dart';
import '../../widgets/marquee_ticker.dart';
import '../../widgets/scroll_reveal.dart';
import '../../widgets/wave_divider.dart';
import '../../widgets/chef_mascot.dart';
import '../../widgets/cart_badge.dart';
import '../contact/contact_screen.dart';
import '../location/location_picker_screen.dart';
import '../menu/menu_screen.dart';
import '../spices/spices_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MUSTAV', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
            ),
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: Consumer(
              builder: (context, ref, _) {
                final selectedLocation = ref.watch(selectedLocationProvider).valueOrNull?.location;
                return Text(selectedLocation?.city.label ?? 'Select store', style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          const CartBadgeIcon(),
          const SizedBox(width: 4),
        ],
      ),
      drawer: const _NavDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroSection(onOrderNow: () => _goToMenu(context)),
          const MarqueeTicker(
            text: 'SMASHED • FRESH • BOLD • CRAVE •',
            backgroundColor: AppColors.red,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.2),
          ),
          ScrollReveal(child: _TopClassicSection(onOrderNow: () => _goToMenu(context))),
          const SizedBox(height: 28),
          ScrollReveal(child: _AboutCarousel()),
          const SizedBox(height: 36),
          ScrollReveal(child: const _ExperienceSection()),
          const SizedBox(height: 32),
          ScrollReveal(child: _IngredientsRow()),
          const SizedBox(height: 36),
          ScrollReveal(child: const _LocationsSection()),
          const SizedBox(height: 36),
          ScrollReveal(child: _StoryRow()),
          const SizedBox(height: 8),
          const WaveDivider(color: AppColors.maroon, height: 44),
          const MarqueeTicker(
            text: 'MUSTAV • BURGERS •',
            backgroundColor: AppColors.maroon,
            style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.2),
          ),
          ScrollReveal(child: _FeelItSection(onOrderNow: () => _goToMenu(context))),
          const _Footer(),
        ],
      ),
    );
  }

  void _goToMenu(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MenuScreen()));
  }
}

class _NavDrawer extends StatelessWidget {
  const _NavDrawer();

  @override
  Widget build(BuildContext context) {
    Widget navTile(String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(label, style: AppTheme.display(size: 22, color: Colors.white)),
          ),
        );

    return Drawer(
      backgroundColor: AppColors.red,
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.6)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Est. 2024 — Pakistan', style: AppTheme.body(size: 11, color: Colors.white, weight: FontWeight.w600)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              navTile('Home', () => Navigator.of(context).pop()),
              navTile('Burgers', () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MenuScreen()));
              }),
              navTile('Our Spices', () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpicesScreen()));
              }),
              navTile('Locations', () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationPickerScreen()));
              }),
              navTile('Contact', () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactScreen()));
              }),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('Crafted for your cravings · est. 2024',
                    style: AppTheme.body(size: 11, color: Colors.white.withOpacity(0.8))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onOrderNow;
  const _HeroSection({required this.onOrderNow});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 560,
          width: double.infinity,
          child: BurgerIllustration(size: 420, backgroundColor: AppColors.surfaceAlt),
        ),
        Container(
          height: 560,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.background.withOpacity(0.35), AppColors.background],
            ),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Est. 2024 — Pakistan', style: TextStyle(fontSize: 11, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 14),
                  const _StackedHeadline(top: 'SMASHED', bottom: 'FRESH'),
                  const SizedBox(height: 6),
                  const _StackedHeadline(top: 'BOLD', bottom: 'FLAVOR'),
                  const SizedBox(height: 18),
                  ElevatedButton(onPressed: onOrderNow, child: const Text('Order Now')),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StackedHeadline extends StatelessWidget {
  final String top;
  final String bottom;
  const _StackedHeadline({required this.top, required this.bottom});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(top, style: AppTheme.display(size: 42, color: Colors.white).copyWith(height: 0.95)),
        Text(bottom, style: AppTheme.display(size: 42, color: AppColors.yellow).copyWith(height: 0.95)),
      ],
    );
  }
}

class _TopClassicSection extends StatelessWidget {
  final VoidCallback onOrderNow;
  const _TopClassicSection({required this.onOrderNow});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOP CLASSIC', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 12)),
          const SizedBox(height: 6),
          const Text('juicy cheesy fully Loaded', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text(
            'MUSTAV is back and bolder than ever. Honoring our rich roots, we bring you the ultimate smashed experience — fully loaded, hot, and crafted fresh.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const ChefMascot(size: 72),
              const SizedBox(width: 14),
              ElevatedButton(onPressed: onOrderNow, child: const Text('Order Now')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutCarousel extends StatelessWidget {
  static const _tiles = [
    (Icons.restaurant_menu, Color(0xFF6B4A2F)),
    (Icons.local_dining, Color(0xFFF2B705)),
    (Icons.storefront, Color(0xFF4E0018)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.82),
        itemCount: _tiles.length,
        itemBuilder: (context, index) {
          final (icon, color) = _tiles[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: color,
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 64),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EXPERIENCE', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 12)),
          const SizedBox(height: 6),
          const Text('food that feels good', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          _FeatureCard(emoji: '🔥', title: 'BOLD FLAVOUR', lines: const ['100% Organic', 'Zero Guilt', 'True Taste']),
          const SizedBox(height: 12),
          _FeatureCard(emoji: '💪', title: '450 kcal', lines: const ['High Protein', 'Fresh Ingredients', 'Low Carb']),
          const SizedBox(height: 12),
          _FeatureCard(emoji: '✨', title: 'Pure Quality', lines: const ['Every Layer', 'Packed With', 'Signature Flavor']),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final List<String> lines;
  const _FeatureCard({required this.emoji, required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(lines.join(' · '), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsRow extends StatelessWidget {
  static const _items = [
    ('Lettuce', Icons.eco, Color(0xFF7EA32A)),
    ('Tomato', Icons.circle, Color(0xFFD32F2F)),
    ('Cheese', Icons.square, Color(0xFFF2B705)),
    ('Patty', Icons.circle, Color(0xFF6B4A2F)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (name, icon, color) = _items[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                IngredientTile(icon: icon, color: color, size: 110),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LocationsSection extends ConsumerWidget {
  const _LocationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TAKE AWAY', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 12)),
          const SizedBox(height: 6),
          const Text('quality that travels with you', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text(
            'Freshly packed smash burgers, ready to go wherever you crave. From our flat-top to any corner of Pakistan.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          storesAsync.when(
            loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: AppColors.accent))),
            error: (e, st) => const SizedBox.shrink(),
            data: (stores) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: stores.length,
              itemBuilder: (context, index) => _LocationCard(store: stores[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends ConsumerWidget {
  final StoreLocation store;
  const _LocationCard({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await ref.read(selectedLocationProvider.notifier).selectManually(store);
        if (context.mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MenuScreen()));
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CityTile(color: _cityColor(store.city)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              right: 10,
              child: Text(
                store.city.label.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _cityColor(CityName city) => switch (city) {
        CityName.lahore => const Color(0xFF6B4A2F),
        CityName.islamabad => const Color(0xFF4E0018),
        CityName.rawalpindi => const Color(0xFFED6F2F),
        CityName.multan => const Color(0xFF7EA32A),
      };
}

class _StoryRow extends StatelessWidget {
  static const _items = [
    ('Freshly Greens', 'Grilled to perfection — juicy, smoky, unforgettable.', Icons.eco, Color(0xFF7EA32A)),
    ('Juicy Tomatoes', 'Sun-ripened tomatoes that bring natural sweetness and balance.', Icons.circle, Color(0xFFD32F2F)),
    ('Creamy Cheese', 'Rich, creamy cheese that melts into every bite.', Icons.square, Color(0xFFF2B705)),
    ('Perfect Patty', 'Grilled to perfection — juicy, smoky, unforgettable.', Icons.circle, Color(0xFF6B4A2F)),
    ('Artisan Bun', 'Soft, toasted buns crafted to hold everything together.', Icons.bakery_dining, Color(0xFFE79A3F)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('A story in every bite.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final (title, desc, icon, color) = _items[index];
              return SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: IngredientTile(icon: icon, color: color, size: 120),
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeelItSection extends StatelessWidget {
  final VoidCallback onOrderNow;
  const _FeelItSection({required this.onOrderNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.maroon,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FEEL IT', style: AppTheme.body(size: 12, color: AppColors.yellow, weight: FontWeight.w800).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text('feel the Change', style: AppTheme.display(size: 26, color: Colors.white)),
          const SizedBox(height: 10),
          Text(
            'Smashed for the bold, built for the hungry. Dive into a legendary craft experience where every crispy edge and juicy layer rules.',
            style: AppTheme.body(color: Colors.white.withOpacity(0.8), size: 13).copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const ChefMascot(size: 72),
              const SizedBox(width: 14),
              ElevatedButton(onPressed: onOrderNow, child: const Text('Order Now')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget navLink(String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(label, style: AppTheme.body(size: 13, color: Colors.white.withOpacity(0.85))),
          ),
        );

    return Container(
      color: AppColors.maroon,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MUSTAV', style: AppTheme.display(size: 24, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Crafted for your cravings · est. 2024', style: AppTheme.body(size: 12, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 20),
          Text('NAVIGATE', style: AppTheme.body(size: 12, color: AppColors.yellow, weight: FontWeight.w800).copyWith(letterSpacing: 1)),
          const SizedBox(height: 4),
          navLink('Home', () => Navigator.of(context).popUntil((route) => route.isFirst)),
          navLink('Burgers', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MenuScreen()))),
          navLink('Spices', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpicesScreen()))),
          navLink('Contact', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactScreen()))),
          const SizedBox(height: 20),
          Text('LOCATIONS', style: AppTheme.body(size: 12, color: AppColors.yellow, weight: FontWeight.w800).copyWith(letterSpacing: 1)),
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              final storesAsync = ref.watch(storesProvider);
              return storesAsync.when(
                loading: () => Text('Lahore\nIslamabad\nRawalpindi\nMultan',
                    style: AppTheme.body(size: 13, color: Colors.white.withOpacity(0.85)).copyWith(height: 1.8)),
                error: (e, st) => Text('Lahore\nIslamabad\nRawalpindi\nMultan',
                    style: AppTheme.body(size: 13, color: Colors.white.withOpacity(0.85)).copyWith(height: 1.8)),
                data: (stores) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final store in stores)
                      navLink(store.city.label, () async {
                        await ref.read(selectedLocationProvider.notifier).selectManually(store);
                        if (context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MenuScreen()));
                        }
                      }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text('OWNER', style: AppTheme.body(size: 12, color: AppColors.yellow, weight: FontWeight.w800).copyWith(letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('Mustafa', style: AppTheme.body(size: 13, color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 24),
          Text('© 2026 MUSTAV — All rights reserved', style: AppTheme.body(size: 11, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }
}