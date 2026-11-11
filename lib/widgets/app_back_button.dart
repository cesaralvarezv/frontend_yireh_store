import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Botón de regreso cuadrado y consistente para las pantallas administrativas.
class AppBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const AppBackButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Volver',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
    );
  }
}
