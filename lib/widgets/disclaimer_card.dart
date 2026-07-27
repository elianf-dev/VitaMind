import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'vita_mind_card.dart';

class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({
    super.key,
    this.text = 'This is not medical advice or a diagnosis.',
    this.icon = Icons.health_and_safety_outlined,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return VitaMindCard(
      backgroundColor: AppColors.warningSurface,
      borderColor: AppColors.warningBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6E5A28),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
