import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pageBottom = 28;
  static const double radius = 8;

  static const EdgeInsets page = EdgeInsets.fromLTRB(xl, md, xl, pageBottom);
  static const EdgeInsets tabPage = EdgeInsets.fromLTRB(xl, xl, xl, pageBottom);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets cardLarge = EdgeInsets.all(18);
}
