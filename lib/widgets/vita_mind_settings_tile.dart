import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'vita_mind_card.dart';

class VitaMindSettingsTile extends StatelessWidget {
  const VitaMindSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return VitaMindCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}
