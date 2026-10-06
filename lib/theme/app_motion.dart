import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  /// Animation style for dialogs and bottom sheets: none when the system
  /// asks to reduce motion, otherwise the Material default. Material's
  /// overlays don't read that setting themselves.
  static AnimationStyle? overlay(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null;
  }
}
