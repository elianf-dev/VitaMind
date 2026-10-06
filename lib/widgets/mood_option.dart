import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'neomorphic_surface.dart';

class MoodOption extends StatelessWidget {
  const MoodOption({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // One node with the label, selected state, and tap, so screen readers
    // don't also read the emoji's name or announce the tile twice.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: NeomorphicSurface(
        width: 96,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        backgroundColor: selected
            ? AppColors.primarySoft
            : AppColors.neoSurface,
        borderColor: selected ? colorScheme.primary : AppColors.border,
        shadowStrength: selected ? 0.55 : 0.8,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: AppSpacing.sm),
            // Shrink to fit the fixed-width tile at large text sizes rather
            // than cutting the word off.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? colorScheme.primary : AppColors.bodyText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
