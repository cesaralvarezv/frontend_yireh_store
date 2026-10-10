import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallet_model.dart';
import '../services/token_storage.dart';
import '../utils/constants.dart';

/// Servicio de billetera — balance, historial y recarga.
class WalletService {
  final String baseUrl;

  WalletService({String? baseUrl}) : baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtiene saldo actual del usuario autenticado.
  Future<WalletBalance> getBalance() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/wallet/balance'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      return WalletBalance.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Error al obtener saldo: ${res.statusCode}');
  }

  /// Obtiene historial de transacciones.
  Future<List<RechargeTransaction>> getTransactions() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/wallet/transactions'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => RechargeTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al obtener transacciones: ${res.statusCode}');
  }

  /// Recarga saldo.
  Future<RechargeTransaction> recharge({
    required double amount,
    required String paymentMethod,
    String? referenceCode,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/recharge'),
      headers: headers,
      body: jsonEncode({
        'amount': amount,
        'paymentMethod': paymentMethod,
        'referenceCode': referenceCode,
      }),
    );
    if (res.statusCode == 200) {
      return RechargeTransaction.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractError(res.body));
  }

  String _extractError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error']?.toString() ?? data['message']?.toString() ?? body;
    } catch (_) {
      return body.isEmpty ? 'Error desconocido' : body;
    }
  }
}

