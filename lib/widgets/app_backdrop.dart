import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundStart,
            AppColors.backgroundMiddle,
            AppColors.backgroundEnd,
          ],
          stops: [0, 0.52, 1],
        ),
      ),
      child: BackdropGroup(
        child: Stack(
          fit: StackFit.expand,
          children: [const _AtmosphereVeil(), child],
        ),
      ),
    );
  }
}

class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const GlassPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final opacity = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    return AppBackdrop(
      child: FadeTransition(opacity: opacity, child: child),
    );
  }
}

class _AtmosphereVeil extends StatelessWidget {
  const _AtmosphereVeil();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _AtmospherePainter()));
  }
}

class _AtmospherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final coolPaint = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    final upperBand = Path()
      ..moveTo(0, size.height * 0.12)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.26)
      ..lineTo(0, size.height * 0.34)
      ..close();
    final lowerBand = Path()
      ..moveTo(0, size.height * 0.68)
      ..lineTo(size.width, size.height * 0.55)
      ..lineTo(size.width, size.height * 0.82)
      ..lineTo(0, size.height * 0.92)
      ..close();

    canvas.drawPath(upperBand, lightPaint);
    canvas.drawPath(lowerBand, coolPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
