import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/port/out/cash_closure_repository_port.dart';
import '../../../models/cash_closure_status_model.dart';
import '../../../services/http_log_interceptor.dart';
import '../../../services/token_storage.dart';
import '../../../utils/constants.dart';
import '../../../main.dart' show logService;

/// Consulta el estado del turno de caja del backend.
class ApiCashClosureRepository implements CashClosureRepositoryPort {
  static const _timeout = Duration(seconds: 12);

  final http.Client _client;
  final String baseUrl;

  ApiCashClosureRepository({http.Client? client, String? baseUrl})
      : _client = client ??
            HttpLogInterceptor(
              inner: http.Client(),
              onLog: (l, t, m, s) =>
                  logService.report(level: l, tag: t, message: m, stackTrace: s),
            ),
        baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<CashClosureStatusModel> getStatus() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/cash-closures/status'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CashClosureStatusModel.fromJson(data);
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesión expirada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No autorizado');
    } else {
      throw Exception('No se pudo consultar el estado de caja (${res.statusCode}).');
    }
  }
}
