import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Controlador global de carga para operaciones asíncronas y transiciones.
class LoadingController extends ChangeNotifier {
  int _pendingOperations = 0;

  bool get isLoading => _pendingOperations > 0;

  void _notify() {
    // Evita notificar mientras el framework está construyendo widgets;
    // en ese caso se programa la notificación para después de la fase build.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
      return;
    }

    notifyListeners();
  }

  void show() {
    _pendingOperations++;
    if (_pendingOperations == 1) {
      _notify();
    }
  }

  void hide() {
    if (_pendingOperations > 0) {
      _pendingOperations--;
      if (_pendingOperations == 0) {
        _notify();
      }
    }
  }
}

final LoadingController loadingController = LoadingController();
