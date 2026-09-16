import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget de logo. Usa `assets/images/logo.png` si existe; en ausencia
/// muestra una reconstrucción vectorial fiel a la captura (Yireh Store + águila).
class AppLogo extends StatelessWidget {
  final double height;
  const AppLogo({super.key, this.height = 150});

  @override
  Widget build(BuildContext context) {
    // Intenta cargar asset, con fallback visual para que la app siempre compile
    // aunque el usuario aún no haya agregado el png.
    return SizedBox(
      height: height,
      child: Image.asset(
        AppConstants.logoAsset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _FallbackLogo(height: height);
        },
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final double height;
  const _FallbackLogo({required this.height});

  @override
  Widget build(BuildContext context) {
    // Reconstrucción aproximada del logo Yireh Store
    // Mantiene colores y proporciones; reemplazar por png cuando exista
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Texto Yireh
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Yireh',
                style: TextStyle(
                  fontSize: height * 0.32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0E7AD6),
                  shadows: const [
                    Shadow(
                      color: Color(0xFF0B2A45),
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                  letterSpacing: 1,
                ),
              ),
              // Highlight efecto burbuja
              Positioned(
                top: 0,
                child: Text(
                  'Yireh',
                  style: TextStyle(
                    fontSize: height * 0.32,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 6
                      ..color = const Color(0xFF0B2A45),
                  ),
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Store',
                  style: TextStyle(
                    fontSize: height * 0.34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Color(0xFF0B2A45),
                        offset: Offset(0, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Store',
                  style: TextStyle(
                    fontSize: height * 0.34,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 7
                      ..color = const Color(0xFF0B2A45),
                  ),
                ),
              ],
            ),
          ),
          // Cinta + águila simplificada
          Transform.translate(
            offset: const Offset(0, -10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: height * 0.6,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2FA8FF),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFF0B2A45), width: 2),
                  ),
                ),
                const SizedBox(width: 6),
                // Águila en taza (emoji/Icon placeholder fiel)
                Container(
                  width: height * 0.32,
                  height: height * 0.28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2FA8FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0B2A45), width: 2),
                  ),
                  child: const Icon(
                    Icons.coffee,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'assets/images/logo.png no encontrado',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
