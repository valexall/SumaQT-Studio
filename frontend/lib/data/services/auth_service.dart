import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../models/user_api_model.dart';

/// Servicio HTTP para llamadas a los endpoints de autenticación.
class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Registra una nueva cuenta de usuario en el backend.
  Future<AuthResponseApiModel> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConfig.authRegisterUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponseApiModel.fromJson(json);
    } else {
      _handleError(response);
    }
  }

  /// Inicia sesión con credenciales existentes.
  Future<AuthResponseApiModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConfig.authLoginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponseApiModel.fromJson(json);
    } else {
      _handleError(response);
    }
  }

  /// Consulta el perfil del usuario autenticado con su token JWT.
  Future<UserApiModel> getMe(String token) async {
    final response = await _client.get(
      Uri.parse(AppConfig.authMeUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserApiModel.fromJson(json);
    } else {
      _handleError(response);
    }
  }

  Never _handleError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = json['detail'];
      if (detail != null) {
        throw Exception(detail.toString());
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('FormatException')) {
        rethrow;
      }
    }
    throw Exception('Error del servidor (${response.statusCode}): ${response.reasonPhrase}');
  }
}
