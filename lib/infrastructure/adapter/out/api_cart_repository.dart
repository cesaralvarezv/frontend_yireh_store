import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/cart_item_model.dart';
import '../../../domain/port/out/cart_repository_port.dart';
import '../../../utils/constants.dart';
import '../../../services/token_storage.dart';
import '../../../services/http_log_interceptor.dart';
import '../../../main.dart' show logService;

/// Implementación real conectada a Spring Boot via API.
class ApiCartRepository implements CartRepositoryPort {
  static const _requestTimeout = Duration(seconds: 12);
  final http.Client _client;
  final String baseUrl;

  ApiCartRepository({http.Client? client, String? baseUrl})
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
  Future<List<CartItemModel>> getItems() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/cart'),
      headers: await _headers(),
    ).timeout(_requestTimeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final itemsJson = data['items'] as List? ?? [];
      return itemsJson.map((e) => _cartItemFromJson(e)).toList();
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesión expirada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No autorizado');
    } else {
      throw Exception('Error al cargar carrito: ${res.statusCode}');
    }
  }

  @override
  Future<void> addItem(CartItemModel item) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/cart/items'),
      headers: await _headers(),
      body: jsonEncode({
        'productId': int.parse(item.productId),
        'quantity': item.quantity,
      }),
    ).timeout(_requestTimeout);

    if (res.statusCode == 200) {
      return;
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesión expirada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No autorizado');
    } else if (res.statusCode == 404) {
      throw Exception('404: Producto no encontrado');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  @override
  Future<void> removeItem(String productId) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/cart/items/$productId'),
      headers: await _headers(),
    ).timeout(_requestTimeout);

    if (res.statusCode == 200) {
      return;
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesión expirada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No autorizado');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  @override
  Future<void> updateQuantity(String productId, int quantity) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/cart/items/$productId?quantity=$quantity'),
      headers: await _headers(),
    ).timeout(_requestTimeout);

    if (res.statusCode == 200) {
      return;
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesión expirada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No autorizado');
    } else if (res.statusCode == 404) {
      throw Exception('404: Producto no encontrado en carrito');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  @override
  Future<void> clear() async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/cart'),
      headers: await _headers(),
    ).timeout(_requestTimeout);

    if (res.statusCode == 200) {
      return;
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesión expirada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No autorizado');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  CartItemModel _cartItemFromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'].toString(),
      productName: json['productName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  String _extractError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error']?.toString() ?? body;
    } catch (_) {
      return body.isEmpty ? 'Error desconocido' : body;
    }
  }
}