import 'dart:async';
import 'package:http/http.dart' as http;
import '../../controllers/loading_controller.dart';

/// Interceptor HTTP que loguea errores de red y controla el spinner global
/// para métodos de escritura (POST, PUT, PATCH, DELETE).
class HttpLogInterceptor extends http.BaseClient {
  final http.Client _inner;
  final void Function(String level, String tag, String message, String? stackTrace)? onLog;

  HttpLogInterceptor({required http.Client inner, this.onLog}) : _inner = inner; // ignore: prefer_initializing_formals

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final shouldShow = request.method == 'POST' || request.method == 'PUT' || request.method == 'PATCH' || request.method == 'DELETE';

    if (shouldShow) {
      loadingController.show();
    }

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _inner.send(request);
      stopwatch.stop();

      if (response.statusCode >= 400) {
        onLog?.call(
          'WARN',
          'HttpError',
          '${request.method} ${request.url} → ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)',
          null,
        );
      }
      return response;
    } catch (e, st) {
      stopwatch.stop();
      onLog?.call(
        'ERROR',
        'HttpError',
        '${request.method} ${request.url} → $e (${stopwatch.elapsedMilliseconds}ms)',
        st.toString(),
      );
      rethrow;
    } finally {
      if (shouldShow) {
        loadingController.hide();
      }
    }
  }
}
