import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionSemanticLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;

  /// Screen-reader label for the action when [actionLabel] alone is vague
  /// (for example "Add" read out of context).
  final String? actionSemanticLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: AppTextStyles.sectionTitle(context)),
              ),
              if (hasAction)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    semanticsLabel: actionSemanticLabel,
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
