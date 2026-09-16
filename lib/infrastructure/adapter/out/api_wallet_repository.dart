import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/port/out/wallet_repository_port.dart';
import '../../../models/wallet_model.dart';
import '../../../utils/constants.dart';
import '../../../services/token_storage.dart';
import '../../../services/http_log_interceptor.dart';
import '../../../main.dart' show logService;

class ApiWalletRepository implements WalletRepositoryPort {
  static const _timeout = Duration(seconds: 12);
  final http.Client _client;
  final String baseUrl;

  ApiWalletRepository({http.Client? client, String? baseUrl})
      : _client = client ??
            HttpLogInterceptor(
              inner: http.Client(),
              onLog: (l, t, m, s) => logService.report(level: l, tag: t, message: m, stackTrace: s),
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
  Future<double> getBalance() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/wallet/balance'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['balance'] as num?)?.toDouble() ?? 0.0;
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  @override
  Future<RechargeTransaction> recharge({
    required double amount,
    required String paymentMethod,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/wallet/recharge'),
      headers: await _headers(),
      body: jsonEncode({
        'amount': amount,
        'paymentMethod': paymentMethod,
      }),
    ).timeout(_timeout);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return RechargeTransaction.fromJson(data);
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  @override
  Future<List<RechargeTransaction>> getTransactions() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/wallet/transactions'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List? ?? [];
      return list
          .map((e) => RechargeTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  String _extractError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error']?.toString() ?? body;
    } catch (_) {
      return body.isEmpty ? 'Error de servidor' : body;
    }
  }
}
