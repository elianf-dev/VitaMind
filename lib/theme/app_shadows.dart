import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> raised({double strength = 1}) {
    return [
      BoxShadow(
        color: AppColors.shadow.withValues(alpha: 0.42 * strength),
        offset: Offset(5 * strength, 6 * strength),
        blurRadius: 14 * strength,
      ),
      BoxShadow(
        color: AppColors.highlight.withValues(alpha: 0.82 * strength),
        offset: Offset(-4 * strength, -4 * strength),
        blurRadius: 12 * strength,
      ),
    ];
  }

  static List<BoxShadow> glass({double strength = 1}) {
    return [
      BoxShadow(
        color: AppColors.glassShadow.withValues(alpha: 0.18 * strength),
        offset: Offset(7 * strength, 10 * strength),
        blurRadius: 24 * strength,
      ),
      BoxShadow(
        color: AppColors.highlight.withValues(alpha: 0.48 * strength),
        offset: Offset(-3 * strength, -3 * strength),
        blurRadius: 10 * strength,
      ),
    ];
  }

  static List<BoxShadow> pressed() {
    return [
      BoxShadow(
        color: AppColors.shadow.withValues(alpha: 0.3),
        offset: const Offset(1, 1),
        blurRadius: 3,
      ),
      BoxShadow(
        color: AppColors.highlight.withValues(alpha: 0.65),
        offset: const Offset(-1, -1),
        blurRadius: 3,
      ),
    ];
  }
}
