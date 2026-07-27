import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class VitaMindPageHeader extends StatelessWidget {
  const VitaMindPageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.pageTitle(context)),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle!, style: AppTextStyles.supportiveBody(context)),
          ],
        ],
      ),
    );
  }
}
