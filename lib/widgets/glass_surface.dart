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
    this.radius = AppSpacing.radius,
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

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.onTap == null
        ? widget.child
        : Semantics(
            button: true,
            label: widget.semanticLabel,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: _setPressed,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                child: widget.child,
              ),
            ),
          );

    return Padding(
      padding: widget.margin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: _pressed
              ? AppShadows.pressed()
              : AppShadows.glass(strength: widget.shadowStrength),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: BackdropFilter.grouped(
            filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: widget.alignment,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: _pressed
                    ? AppColors.glassPressed
                    : widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(color: widget.borderColor),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
