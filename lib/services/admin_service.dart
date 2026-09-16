import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../services/token_storage.dart';
import '../services/http_log_interceptor.dart';
import '../main.dart' show logService;

/// Servicio para gestión de usuarios (solo ADMIN).
/// SRP: solo llamadas HTTP de administración.
class AdminService {
  final http.Client _client;
  final String baseUrl;

  AdminService({http.Client? client, String? baseUrl})
      : _client = client ??
            HttpLogInterceptor(
              inner: http.Client(),
              onLog: (l, t, m, s) => logService.report(level: l, tag: t, message: m, stackTrace: s),
            ),
        baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<String> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return token ?? '';
  }

  /// GET /api/users — lista todos los usuarios (ADMIN only).
  Future<List<UserModel>> getAllUsers() async {
    final token = await _getHeaders();
    final res = await _client.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => UserModel.fromJson(e)).toList();
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  /// POST /api/users — crea un usuario (ADMIN only).
  Future<UserModel> createUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    final token = await _getHeaders();
    final res = await _client.post(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } else if (res.statusCode == 403) {
      throw Exception('403: No tienes permisos de administrador');
    } else if (res.statusCode == 401) {
      throw Exception('401: Sesion expirada');
    } else if (res.statusCode == 409) {
      throw Exception('409: El correo electronico ya esta registrado');
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
