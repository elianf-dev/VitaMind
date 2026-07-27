import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> raised({double strength = 1}) {
    return [
      BoxShadow(
        color: AppColors.shadow.withValues(alpha: 0.52 * strength),
        offset: Offset(4 * strength, 4 * strength),
        blurRadius: 10 * strength,
      ),
      BoxShadow(
        color: AppColors.highlight.withValues(alpha: 0.92 * strength),
        offset: Offset(-4 * strength, -4 * strength),
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
