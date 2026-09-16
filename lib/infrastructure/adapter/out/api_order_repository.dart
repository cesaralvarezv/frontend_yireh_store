import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/port/out/order_repository_port.dart';
import '../../../models/order_model.dart';
import '../../../utils/constants.dart';
import '../../../services/token_storage.dart';
import '../../../services/http_log_interceptor.dart';
import '../../../main.dart' show logService;

class ApiOrderRepository implements OrderRepositoryPort {
  static const _timeout = Duration(seconds: 15);
  final http.Client _client;
  final String baseUrl;

  ApiOrderRepository({http.Client? client, String? baseUrl})
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
  Future<OrderModel> checkout({
    required String deliveryLocation,
    required String paymentMethod,
    String? notes,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/orders/checkout'),
      headers: await _headers(),
      body: jsonEncode({
        'deliveryLocation': deliveryLocation,
        'paymentMethod': paymentMethod,
        'notes': notes,
      }),
    ).timeout(_timeout);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return OrderModel.fromJson(data);
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  @override
  Future<List<OrderModel>> getMyOrders() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/orders/my-orders'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List? ?? [];
      return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  @override
  Future<List<OrderModel>> getAllOrdersAdmin() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/orders/admin'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List? ?? [];
      return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  @override
  Future<OrderModel> updateOrderStatus(int orderId, String newStatus) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/orders/$orderId/status?status=$newStatus'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return OrderModel.fromJson(data);
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
