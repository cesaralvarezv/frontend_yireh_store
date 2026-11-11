import 'dart:async';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'services/log_service.dart';
import 'controllers/loading_controller.dart';
import 'widgets/loading_overlay.dart';
import 'views/splash_view.dart';

/// Instancia global del servicio de logs — accesible desde cualquier parte.
final logService = LogService();

class _AppLoadingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    loadingController.show();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    loadingController.show();
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    loadingController.hide();
  }
}

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
      navigatorObservers: [_AppLoadingNavigatorObserver()],
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();

        return AnimatedBuilder(
          animation: loadingController,
          builder: (context, _) {
            return Stack(
              children: [
                content,
                if (loadingController.isLoading)
                  const Positioned.fill(child: LoadingOverlay()),
              ],
            );
          },
        );
      },
      home: const SplashView(),
    );
  }
}
