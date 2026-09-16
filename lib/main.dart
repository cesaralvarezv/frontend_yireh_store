import 'dart:async';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'services/log_service.dart';
import 'views/splash_view.dart';

/// Instancia global del servicio de logs — accesible desde cualquier parte.
final logService = LogService();

void main() {
  // Captura errores no atrapados en Zones y evita Zone mismatch
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    logService.init();
    runApp(const YirehApp());
  }, (error, stackTrace) {
    logService.report(
      level: 'ERROR',
      tag: 'UncaughtZone',
      message: error.toString(),
      stackTrace: stackTrace.toString(),
    );
  });
}

class YirehApp extends StatelessWidget {
  const YirehApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashView(),
    );
  }
}
