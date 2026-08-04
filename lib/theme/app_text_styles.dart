import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle? pageTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: AppColors.text,
      fontWeight: FontWeight.w800,
    );
  }

  static TextStyle? sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
      color: AppColors.text,
      fontWeight: FontWeight.w800,
    );
  }

  static TextStyle? cardTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      color: AppColors.text,
      fontWeight: FontWeight.w800,
    );
  }

  static TextStyle? supportiveBody(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedText, height: 1.35);
  }

  static TextStyle? cardBody(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.bodyText, height: 1.4);
  }

  static TextStyle? meta(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.mutedText,
      fontWeight: FontWeight.w700,
    );
  }

  static const String displayFontFamily = 'Fraunces';

  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.text,
    double height = 1.05,
    FontStyle style = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: displayFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * -0.015,
      fontStyle: style,
    );
  }

  static TextStyle eyebrow({Color color = AppColors.mutedText, double size = 11}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: size * 0.14,
      color: color,
    );
  }
}
