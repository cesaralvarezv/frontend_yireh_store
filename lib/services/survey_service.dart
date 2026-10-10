import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/survey_model.dart';
import '../services/token_storage.dart';
import '../utils/constants.dart';

/// Servicio para encuestas CSAT — POST y GET contra /api/satisfaction/surveys.
class SurveyService {
  final String baseUrl;

  SurveyService({String? baseUrl}) : baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Envía una calificación CSAT post-entrega.
  Future<SurveyModel> submitSurvey({
    required int orderId,
    required int rating,
    List<String> quickTags = const [],
    String? comment,
  }) async {
    final headers = await _authHeaders();
    final body = jsonEncode({
      'orderId': orderId,
      'rating': rating,
      if (quickTags.isNotEmpty) 'quickTags': quickTags.join(','),
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });

    final res = await http.post(
      Uri.parse('$baseUrl/satisfaction/surveys'),
      headers: headers,
      body: body,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return SurveyModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractError(res.body));
  }

  /// Consulta si ya existe encuesta para una orden.
  Future<SurveyModel?> getSurveyByOrder(int orderId) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/satisfaction/surveys/order/$orderId'),
      headers: headers,
    );
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    if (res.statusCode == 200) {
      return SurveyModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return null;
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
