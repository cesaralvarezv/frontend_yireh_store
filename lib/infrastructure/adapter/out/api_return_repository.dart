import 'package:flutter_yireh_store/models/return_model.dart';
import 'package:http/http.dart';
import 'package:flutter_yireh_store/utils/constants.dart';
import 'package:flutter_yireh_store/services/token_storage.dart';

class ApiReturnRepository {
  static const _timeout = Duration(seconds: 15);
  final Client _client;
  final String baseUrl;

  ApiReturnRepository({Client? client, String? baseUrl})
      : _client = client ?? Client(),
        baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<OrderReturn> requestReturn(
      String userEmail, int orderId, String reason, List<ReturnItem> items) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/returns'),
      headers: await _headers(),
      body: jsonEncode({
        'orderId': orderId,
        'reason': reason,
        'items': items.map((e) => e.toMap()).toList(),
      }),
    ).timeout(_timeout);

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return OrderReturn.fromMap(data);
    } else {
      throw Exception('Error al solicitar devolución: ${res.body}');
    }
  }

  Future<List<OrderReturn>> myReturns(String userEmail) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/returns/my'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body) as List?;
      return list?.map((e) => OrderReturn.fromMap(e as Map<String, dynamic>)).toList() ?? [];
    } else {
      throw Exception('Error al obtener devoluciones: ${res.body}');
    }
  }

  Future<OrderReturn> getById(int returnId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/returns/$returnId'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return OrderReturn.fromMap(data);
    } else {
      throw Exception('Error al obtener devolución: ${res.body}');
    }
  }

  Future<OrderReturn> approveReturn(int returnId, String adminEmail) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/returns/$returnId/approve'),
      headers: await _headers(),
      body: jsonEncode({'adminEmail': adminEmail}),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return OrderReturn.fromMap(data);
    } else {
      throw Exception('Error al aprobar devolución: ${res.body}');
    }
  }

  Future<OrderReturn> rejectReturn(int returnId, String adminEmail, String reason) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/returns/$returnId/reject'),
      headers: await _headers(),
      body: jsonEncode({'adminEmail': adminEmail, 'reason': reason}),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return OrderReturn.fromMap(data);
    } else {
      throw Exception('Error al rechazar devolución: ${res.body}');
    }
  }

  Future<OrderReturn> processReturn(int returnId,
      {required String processorEmail,
      BigDecimal? cashReceived,
      String? notes}) async {
    final Map<String, dynamic> body = {
      'processorEmail': processorEmail,
    };
    if (cashReceived != null) {
      body['cashReceived'] = cashReceived.toString();
    }
    if (notes != null) {
      body['notes'] = notes;
    }

    final res = await _client.patch(
      Uri.parse('$baseUrl/api/returns/$returnId/process'),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return OrderReturn.fromMap(data);
    } else {
      throw Exception('Error al procesar devolución: ${res.body}');
    }
  }

  Future<OrderReturn> cancelReturn(int returnId, String cancelerEmail) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/returns/$returnId/cancel'),
      headers: await _headers(),
      body: jsonEncode({'cancelerEmail': cancelerEmail}),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return OrderReturn.fromMap(data);
    } else {
      throw Exception('Error al cancelar devolución: ${res.body}');
    }
  }
}