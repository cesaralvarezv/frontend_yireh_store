import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../../domain/port/out/product_repository_port.dart';
import '../../../utils/constants.dart';
import '../../../services/token_storage.dart';

/// Implementación real conectada a Spring Boot via 172.20.1.4:8080.
class ApiProductRepository implements ProductRepositoryPort {
  static const _requestTimeout = Duration(seconds: 12);
  final http.Client _client;
  final String baseUrl;

  ApiProductRepository({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<CategoryModel>> getCategories({String? location}) async {
    final params = <String, String>{'activeOnly': 'true'};
    if (location != null && location.isNotEmpty) {
      params['location'] = location;
    }
    final res = await _client.get(
      Uri.parse('$baseUrl/categories').replace(queryParameters: params),
      headers: await _headers(),
    ).timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => CategoryModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final uri = Uri.parse('$baseUrl/categories/$categoryId/products');
    final res = await _client.get(uri, headers: await _headers()).timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => ProductModel.fromJson(e)).toList();
    }
    throw Exception('No fue posible cargar los productos de esta categoría (${res.statusCode})');
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: {
      'query': query,
      'activeOnly': 'true',
    });
    final res = await _client.get(uri, headers: await _headers()).timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => ProductModel.fromJson(e)).toList();
    }
    return [];
  }
}