import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'token_storage.dart';
import 'http_log_interceptor.dart';
import '../main.dart' show logService;

class UserService {
  static const _timeout = Duration(seconds: 12);
  final http.Client _client;
  final String baseUrl;

  UserService({http.Client? client, String? baseUrl})
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

  Future<UserModel> getProfile() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = await TokenStorage.getToken();
      return UserModel.fromJson(data).copyWith(token: token);
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  Future<UserModel> updateProfile({required String name, required String phone}) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'phone': phone}),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = await TokenStorage.getToken();
      return UserModel.fromJson(data).copyWith(token: token);
    } else {
      throw Exception(_extractError(res.body));
    }
  }

  String _extractError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error']?.toString() ?? body;
    } catch (_) {
      return body.isEmpty ? 'Error al procesar solicitud' : body;
    }
  }
}
