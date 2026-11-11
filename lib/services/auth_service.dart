import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'http_log_interceptor.dart';
import '../main.dart' show logService;

/// Abstraccion para capa de datos externa.
abstract class AuthService {
  Future<UserModel?> login({required String email, required String password});
  Future<UserModel?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  });
}

/// Mock para tests sin backend.
class MockAuthService implements AuthService {
  UserModel? _currentUser;

  @override
  Future<UserModel?> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = UserModel(name: 'Demo User', phone: '', email: email, token: 'mock-token', customerId: 1, customerCode: 'CLI-000001');
    return _currentUser;
  }

  @override
  Future<UserModel?> register({required String name, required String phone, required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 900));
    _currentUser = UserModel(name: name, phone: phone, email: email, token: 'mock-token', customerId: 1, customerCode: 'CLI-000001');
    return _currentUser;
  }
}

/// Implementacion real conectada a Spring Boot via IP del backend.
class ApiAuthService implements AuthService {
  final http.Client _client;
  final String baseUrl;

  ApiAuthService({http.Client? client, String? baseUrl})
      : _client = client ??
            HttpLogInterceptor(
              inner: http.Client(),
              onLog: (l, t, m, s) => logService.report(level: l, tag: t, message: m, stackTrace: s),
            ),
      baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  @override
  Future<UserModel?> login({required String email, required String password}) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  @override
  Future<UserModel?> register({required String name, required String phone, required String email, required String password}) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'phone': phone, 'email': email, 'password': password}),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return UserModel.fromJson(data);
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
