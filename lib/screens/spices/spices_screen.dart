import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/menu_provider.dart';
import '../product_detail/product_detail_screen.dart';

class SpicesScreen extends ConsumerWidget {
  const SpicesScreen({super.key});

  static const _blurbs = {
    SpiceLevel.mild: 'Smooth and comforting — full flavor, no burn.',
    SpiceLevel.medium: 'A confident kick with a smoky-sweet finish.',
    SpiceLevel.hot: 'Fresh jalapeño heat for those who crave the fire.',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Our Spices')),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, st) => const Center(child: Text('Could not load spice info.')),
        data: (burgers) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final level in SpiceLevel.values) ...[
              Text(level.label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.accent)),
              const SizedBox(height: 4),
              Text(_blurbs[level] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ...burgers.where((b) => b.spiceLevel == level).map(
                    (b) => Card(
                      child: ListTile(
                        title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('Rs. ${b.priceRs}'),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(burger: b)),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
