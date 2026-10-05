import 'package:flutter/material.dart';

import '../screens/support_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'vita_mind_card.dart';

/// A quiet, dismissible offer of support after a hard check-in. Never blocks
/// the user and never shows anything promotional.
class SupportNudgeCard extends StatelessWidget {
  const SupportNudgeCard({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return VitaMindCard(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.primaryMist,
      borderColor: AppColors.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thanks for checking in. Hard days count too.',
            style: AppTextStyles.cardTitle(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'If things feel heavy, support is one tap away.',
            style: AppTextStyles.cardBody(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(SupportScreen.routeName),
                icon: const Icon(Icons.favorite_outline),
                label: const Text('Support options'),
              ),
              TextButton(onPressed: onDismiss, child: const Text('Not now')),
            ],
          ),
        ],
      ),
    );
  }
}
