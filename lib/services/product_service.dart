import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../utils/constants.dart';
import '../services/token_storage.dart';
import '../services/http_log_interceptor.dart';
import '../main.dart' show logService;

/// Servicio para gestión de productos (solo ADMIN).
class ProductService {
  final http.Client _client;
  final String baseUrl;

  ProductService({http.Client? client, String? baseUrl})
      : _client = client ??
            HttpLogInterceptor(
              inner: http.Client(),
              onLog: (l, t, m, s) => logService.report(level: l, tag: t, message: m, stackTrace: s),
            ),
        baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<String> _getToken() async {
    return await TokenStorage.getToken() ?? '';
  }

  /// GET /api/products — lista productos.
  Future<List<ProductModel>> getAll({bool activeOnly = false, int? categoryId}) async {
    final token = await _getToken();
    final params = <String, String>{};
    if (activeOnly) params['activeOnly'] = 'true';
    if (categoryId != null) params['categoryId'] = categoryId.toString();
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => ProductModel.fromJson(e)).toList();
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  /// POST /api/products — crea un producto (ADMIN only).
  Future<ProductModel> createProduct({
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    required int categoryId,
    required int order,
  }) async {
    final token = await _getToken();
    final res = await _client.post(
      Uri.parse('$baseUrl/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'price': price,
        if (description != null && description.isNotEmpty) 'description': description,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        'categoryId': categoryId,
        'order': order,
      }),
    );
    if (res.statusCode == 201) {
      return ProductModel.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else if (res.statusCode == 409) {
      throw Exception('409: Ya existe un producto con ese nombre');
    } else {
      throw Exception(_extractError(res.body));
    }
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
