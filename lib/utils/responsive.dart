import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static double logoHeight(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) return 90;
    if (h < 600) return 110; // móviles muy pequeños (ej: 4.5", 480x854)
    if (h < 700) return 130; // móviles pequeños
    if (h < 800) return 150;
    return 170; // estándar / tablets
  }

  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 340) return 16;
    if (w < 380) return 18;
    if (w < 600) return 20;
    return 24; // tablets
  }

  static double topPadding(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    if (h < 600) return 12;
    if (h < 700) return 16;
    return 28;
  }

  static double fieldSpacing(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    if (h < 600) return 10;
    if (h < 700) return 12;
    return 16;
  }

  static double sectionSpacing(BuildContext context, double base) {
    final h = MediaQuery.of(context).size.height;
    if (h < 600) return base * 0.6;
    if (h < 700) return base * 0.75;
    return base;
  }
}
