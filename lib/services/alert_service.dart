import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Servicio centralizado de alertas y feedback visual.
/// Evita duplicación de SnackBars, Dialogs y Toasts en cada componente.
class AlertService {
  AlertService._();

  static final AlertService _instance = AlertService._();
  static AlertService get instance => _instance;

  BuildContext? _context;

  /// Inicializa el servicio con el context actual (llamar en main.dart o en cada vista).
  void init(BuildContext context) {
    _context = context;
  }

  /// Establece context temporal para una alerta específica.
  void _ensureContext(BuildContext? context) {
    _context = context ?? _context;
  }

  bool get _hasContext => _context != null;

  // ─────────────────────────────────────────────────
  // SNACKBARS
  // ─────────────────────────────────────────────────

  /// SnackBar de éxito (verde).
  void success(String message, {BuildContext? context, Duration duration = const Duration(seconds: 3)}) {
    _ensureContext(context);
    if (!_hasContext) return;
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// SnackBar de error (rojo).
  void error(String message, {BuildContext? context, Duration duration = const Duration(seconds: 4)}) {
    _ensureContext(context);
    if (!_hasContext) return;
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// SnackBar de advertencia (ámbar/naranja).
  void warning(String message, {BuildContext? context, Duration duration = const Duration(seconds: 3)}) {
    _ensureContext(context);
    if (!_hasContext) return;
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// SnackBar de info (azul).
  void info(String message, {BuildContext? context, Duration duration = const Duration(seconds: 3)}) {
    _ensureContext(context);
    if (!_hasContext) return;
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// SnackBar personalizado con acción.
  void action({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    BuildContext? context,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 5),
  }) {
    _ensureContext(context);
    if (!_hasContext) return;
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // DIALOGS DE CONFIRMACIÓN
  // ─────────────────────────────────────────────────

  /// Diálogo de confirmación genérico.
  Future<bool?> confirm({
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
    bool isDestructive = false,
    BuildContext? context,
  }) async {
    _ensureContext(context);
    if (!_hasContext) return false;

    return showDialog<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive ? AppColors.error : (confirmColor ?? AppColors.primary),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Diálogo específico para eliminar categoría.
  Future<bool?> confirmDeleteCategory({
    required String categoryName,
    BuildContext? context,
  }) async {
    return confirm(
      context: context,
      title: 'Eliminar categoría',
      message: '¿Estás seguro de que deseas eliminar la categoría "$categoryName"?\n\nEsta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );
  }

  /// Diálogo de carga (loading).
  void showLoading({String message = 'Procesando...', BuildContext? context}) {
    _ensureContext(context);
    if (!_hasContext) return;
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Oculta diálogo de carga.
  void hideLoading({BuildContext? context}) {
    _ensureContext(context);
    if (!_hasContext) return;
    Navigator.of(_context!, rootNavigator: true).pop();
  }

  // ─────────────────────────────────────────────────
  // ERRORES HTTP ESTÁNDAR
  // ─────────────────────────────────────────────────

  /// Maneja errores HTTP comunes y muestra mensaje amigable.
  void handleHttpError(int statusCode, {String? customMessage, BuildContext? context}) {
    String message;
    switch (statusCode) {
      case 400:
        message = customMessage ?? 'Datos inválidos. Verifica la información.';
        break;
      case 401:
        message = 'Sesión expirada. Inicia sesión nuevamente.';
        break;
      case 403:
        message = 'No tienes permisos para realizar esta acción.';
        break;
      case 404:
        message = customMessage ?? 'Recurso no encontrado.';
        break;
      case 409:
        message = customMessage ?? 'Conflicto: el recurso ya existe o tiene dependencias.';
        break;
      case 500:
        message = 'Error interno del servidor. Intenta más tarde.';
        break;
      default:
        message = customMessage ?? 'Error inesperado (código $statusCode).';
    }
    error(message, context: context);
  }
}