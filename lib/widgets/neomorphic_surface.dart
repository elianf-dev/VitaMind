import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

class NeomorphicSurface extends StatefulWidget {
  const NeomorphicSurface({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.backgroundColor = AppColors.neoSurface,
    this.borderColor = AppColors.border,
    this.radius = AppSpacing.radius,
    this.width,
    this.height,
    this.alignment,
    this.onTap,
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
  final double shadowStrength;
  final String? semanticLabel;

  @override
  State<NeomorphicSurface> createState() => _NeomorphicSurfaceState();
}

class _NeomorphicSurfaceState extends State<NeomorphicSurface> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final surface = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      padding: widget.padding,
      transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
      decoration: BoxDecoration(
        color: _pressed ? AppColors.pressedSurface : widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: widget.borderColor),
        boxShadow: _pressed
            ? AppShadows.pressed()
            : AppShadows.raised(strength: widget.shadowStrength),
      ),
      child: widget.child,
    );

    final interactiveSurface = widget.onTap == null
        ? surface
        : Semantics(
            button: true,
            label: widget.semanticLabel,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.radius),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                onHighlightChanged: _setPressed,
                onTap: widget.onTap,
                child: surface,
              ),
            ),
          );

    return Padding(padding: widget.margin, child: interactiveSurface);
  }
}
