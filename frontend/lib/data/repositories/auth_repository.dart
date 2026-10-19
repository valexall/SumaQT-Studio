import '../../domain/models/user.dart';
import '../services/auth_service.dart';

/// Repositorio de autenticación.
/// Gestiona la sesión actual en memoria y coordina llamadas con [AuthService].
class AuthRepository {
  AuthRepository({required AuthService service}) : _service = service;

  final AuthService _service;

  String? _token;
  User? _currentUser;

  String? get currentToken => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Registra una nueva cuenta y establece la sesión.
  Future<User> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final response = await _service.register(
      nombre: nombre,
      email: email,
      password: password,
    );
    _token = response.accessToken;
    _currentUser = response.usuario.toDomain();
    return _currentUser!;
  }

  /// Inicia sesión y almacena el token JWT y usuario en memoria.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _service.login(
      email: email,
      password: password,
    );
    _token = response.accessToken;
    _currentUser = response.usuario.toDomain();
    return _currentUser!;
  }

  /// Cierra la sesión activa y limpia los datos en memoria.
  void logout() {
    _token = null;
    _currentUser = null;
  }
}
