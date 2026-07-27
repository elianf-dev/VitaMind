import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'glass_surface.dart';

class VitaMindCard extends StatelessWidget {
  const VitaMindCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.md),
    this.padding = AppSpacing.card,
    this.borderColor = AppColors.border,
    this.backgroundColor = AppColors.glassSurface,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      width: double.infinity,
      margin: margin,
      padding: padding,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      onTap: onTap,
      child: child,
    );
  }
}
