import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'neomorphic_surface.dart';
import 'vita_mind_card.dart';

class VitaMindActionCard extends StatelessWidget {
  const VitaMindActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor = AppColors.primary,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 40.0 : 48.0;

    return VitaMindCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? AppSpacing.md : 18),
      borderColor: accentColor.withValues(alpha: 0.18),
      child: Row(
        children: [
          NeomorphicSurface(
            width: iconSize,
            height: iconSize,
            padding: EdgeInsets.zero,
            backgroundColor: Color.alphaBlend(
              accentColor.withValues(alpha: 0.12),
              AppColors.neoSurface,
            ),
            borderColor: accentColor.withValues(alpha: 0.16),
            shadowStrength: 0.45,
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle(context)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
