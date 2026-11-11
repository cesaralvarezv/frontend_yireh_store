import 'package:flutter/material.dart';
import '../../controllers/loading_controller.dart';

/// Overlay global de carga. Se muestra mientras hay operaciones activas
/// o durante las transiciones de navegación entre secciones.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    if (!loadingController.isLoading) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: true,
      child: const ColoredBox(
        color: Colors.black87,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
