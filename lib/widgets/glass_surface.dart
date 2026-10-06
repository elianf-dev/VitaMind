import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

class GlassSurface extends StatefulWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.backgroundColor = AppColors.glassSurface,
    this.borderColor = AppColors.border,
    this.radius = AppSpacing.cardRadius,
    this.width,
    this.height,
    this.alignment,
    this.onTap,
    this.blur = 18,
    this.shadowStrength = 1,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double radius;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final VoidCallback? onTap;
  final double blur;
  final double shadowStrength;
  final String? semanticLabel;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) {
      return;
    }
    setState(() => _pressed = value);
  }

  void _setFocused(bool value) {
    if (_focused != value) {
      setState(() => _focused = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final highContrast = MediaQuery.highContrastOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 150);

    final content = widget.onTap == null
        // Transparent Material so nested ListTiles and switches paint their
        // ripples and focus highlights above the card fill.
        ? Material(type: MaterialType.transparency, child: widget.child)
        : Semantics(
            button: true,
            label: widget.semanticLabel,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: _setPressed,
                onFocusChange: _setFocused,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                child: widget.child,
              ),
            ),
          );

    final Color background;
    if (highContrast) {
      background = AppColors.highContrastSurface;
    } else if (_pressed) {
      background = AppColors.glassPressed;
    } else {
      background = widget.backgroundColor;
    }

    // The focus ring replaces the ink highlight that overlayColor hides.
    final Border border;
    if (_focused) {
      border = Border.all(color: AppColors.focusRing, width: 2.5);
    } else if (highContrast) {
      border = Border.all(color: AppColors.highContrastBorder, width: 1.5);
    } else {
      border = Border.all(color: widget.borderColor);
    }

    final fill = AnimatedContainer(
      duration: duration,
      alignment: widget.alignment,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(widget.radius),
        border: border,
      ),
      child: content,
    );

    return Padding(
      padding: widget.margin,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(
          0,
          _pressed && !reduceMotion ? 1 : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: highContrast
              ? null
              : _pressed
              ? AppShadows.pressed()
              : AppShadows.glass(strength: widget.shadowStrength),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          // Blur only shows through a translucent fill, so high contrast
          // (opaque fill) skips it.
          child: highContrast
              ? fill
              : BackdropFilter.grouped(
                  filter: ImageFilter.blur(
                    sigmaX: widget.blur,
                    sigmaY: widget.blur,
                  ),
                  child: fill,
                ),
        ),
      ),
    );
  }
}
