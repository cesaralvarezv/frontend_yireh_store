import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// SRP: Solo captura y envía logs al backend.
/// DIP: Independiente de controllers/views.
class LogService {
  final http.Client _client;
  final String baseUrl;
  final List<_LogEntry> _buffer = [];
  bool _flushing = false;

  LogService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  /// Inicializa la captura de errores de Flutter.
  void init() {
    FlutterError.onError = (details) {
      report(
        level: 'ERROR',
        tag: 'FlutterError',
        message: details.exceptionAsString(),
        stackTrace: details.stack?.toString(),
      );
    };
  }

  void report({required String level, required String tag, required String message, String? stackTrace}) {
    _buffer.add(_LogEntry(level: level, tag: tag, message: message, stackTrace: stackTrace));
    _flush();
  }

  Future<void> _flush() async {
    if (_flushing || _buffer.isEmpty) return;
    _flushing = true;
    try {
      final batch = List<_LogEntry>.from(_buffer);
      _buffer.clear();
      final body = batch.map((e) => e.toJson()).toList();
      await _client.post(
        Uri.parse('$baseUrl/logs/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {
      // Silenciar — no causar loop infinito de errores
    } finally {
      _flushing = false;
    }
  }
}

class _LogEntry {
  final String level;
  final String tag;
  final String message;
  final String? stackTrace;

  _LogEntry({required this.level, required this.tag, required this.message, this.stackTrace});

  Map<String, dynamic> toJson() => {
        'level': level,
        'tag': tag,
        'message': message,
        'stackTrace': stackTrace ?? '',
        'platform': defaultTargetPlatform.name,
        'deviceInfo': 'Flutter ${kIsWeb ? "web" : defaultTargetPlatform.name}',
      };
}
