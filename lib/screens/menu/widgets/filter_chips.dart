import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums.dart';
import '../../../providers/menu_provider.dart';

class FilterChipsBar extends ConsumerWidget {
  const FilterChipsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(menuFilterProvider);
    final notifier = ref.read(menuFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final level in SpiceLevel.values) ...[
            ChoiceChip(
              label: Text(level.label),
              selected: filter.spiceLevel == level,
              onSelected: (selected) => notifier.setSpiceLevel(selected ? level : null),
            ),
            const SizedBox(width: 8),
          ],
          Container(width: 1, height: 24, color: Colors.white.withOpacity(0.1)),
          const SizedBox(width: 8),
          for (final type in PattyType.values) ...[
            ChoiceChip(
              label: Text(type.label),
              selected: filter.pattyType == type,
              onSelected: (selected) => notifier.setPattyType(selected ? type : null),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
