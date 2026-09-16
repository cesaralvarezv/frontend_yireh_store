import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../utils/constants.dart';
import '../services/token_storage.dart';
import '../services/http_log_interceptor.dart';
import '../main.dart' show logService;

/// Servicio para gestión de categorías (solo ADMIN).
/// SRP: solo llamadas HTTP de administración de categorías.
class CategoryService {
  final http.Client _client;
  final String baseUrl;

  CategoryService({http.Client? client, String? baseUrl})
      : _client = client ??
            HttpLogInterceptor(
              inner: http.Client(),
              onLog: (l, t, m, s) => logService.report(level: l, tag: t, message: m, stackTrace: s),
            ),
        baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<String> _getToken() async {
    return await TokenStorage.getToken() ?? '';
  }

  /// GET /api/categories — lista todas las categorías (ADMIN: todas, USER: solo activas).
  Future<List<CategoryModel>> getAll({bool activeOnly = false}) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/categories').replace(
      queryParameters: {'activeOnly': activeOnly.toString()},
    );
    final res = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => CategoryModel.fromJson(e)).toList();
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  /// GET /api/categories/:id — obtiene una categoría por ID.
  Future<CategoryModel> getById(String id) async {
    final token = await _getToken();
    final res = await _client.get(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return CategoryModel.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      throw Exception('404: Categoría no encontrada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  /// POST /api/categories — crea una categoría (ADMIN only).
  Future<CategoryModel> createCategory({
    required String name,
    required String description,
    required String icon,
    required String location,
    required int order,
  }) async {
    final token = await _getToken();
    final res = await _client.post(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'icon': icon,
        'location': location,
        'order': order,
      }),
    );
    if (res.statusCode == 201) {
      return CategoryModel.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else if (res.statusCode == 409) {
      throw Exception('409: Ya existe una categoría con ese nombre');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  /// PUT /api/categories/:id — actualiza una categoría (ADMIN only).
  Future<CategoryModel> updateCategory({
    required String id,
    required String name,
    required String description,
    required String icon,
    required String location,
    required int order,
  }) async {
    final token = await _getToken();
    final res = await _client.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'icon': icon,
        'location': location,
        'order': order,
      }),
    );
    if (res.statusCode == 200) {
      return CategoryModel.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      throw Exception('404: Categoría no encontrada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else if (res.statusCode == 409) {
      throw Exception('409: Ya existe una categoría con ese nombre');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  /// PATCH /api/categories/:id/deactivate — desactiva una categoría (ADMIN only).
  Future<CategoryModel> deactivateCategory(String id) async {
    final token = await _getToken();
    final res = await _client.patch(
      Uri.parse('$baseUrl/categories/$id/deactivate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return CategoryModel.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      throw Exception('404: Categoría no encontrada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  /// PATCH /api/categories/:id/activate — activa una categoría (ADMIN only).
  Future<CategoryModel> activateCategory(String id) async {
    final token = await _getToken();
    final res = await _client.patch(
      Uri.parse('$baseUrl/categories/$id/activate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return CategoryModel.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      throw Exception('404: Categoría no encontrada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  /// DELETE /api/categories/:id — elimina una categoría (ADMIN only).
  Future<void> deleteCategory(String id) async {
    final token = await _getToken();
    final res = await _client.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 204) {
      return;
    } else if (res.statusCode == 404) {
      throw Exception('404: Categoría no encontrada');
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else if (res.statusCode == 409) {
      throw Exception('409: No se puede eliminar la categoría porque tiene productos asociados');
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