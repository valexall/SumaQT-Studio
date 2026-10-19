import '../../domain/models/user.dart';

/// Modelo de datos recibido desde el API REST para un usuario.
class UserApiModel {
  const UserApiModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.creadoEn,
  });

  factory UserApiModel.fromJson(Map<String, dynamic> json) {
    return UserApiModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  final int id;
  final String nombre;
  final String email;
  final DateTime creadoEn;

  /// Transforma el modelo API en el modelo de Dominio
  User toDomain() {
    return User(
      id: id,
      nombre: nombre,
      email: email,
      creadoEn: creadoEn,
    );
  }
}

/// Respuesta de autenticación recibida desde /login o /registro.
class AuthResponseApiModel {
  const AuthResponseApiModel({
    required this.accessToken,
    required this.tokenType,
    required this.usuario,
  });

  factory AuthResponseApiModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseApiModel(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      usuario: UserApiModel.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final String tokenType;
  final UserApiModel usuario;
}
