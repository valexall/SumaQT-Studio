import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/models/user.dart';

/// ViewModel para la gestión del estado de autenticación (Login y Registro).
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _guestMode = false;

  bool get isLoginMode => _isLoginMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get guestMode => _guestMode;
  User? get currentUser => _repository.currentUser;
  bool get isAuthenticated => _repository.isAuthenticated || _guestMode;
  bool get hasUserSession => _repository.isAuthenticated;

  /// Alterna entre el modo "Iniciar Sesión" y "Registrarse".
  void toggleMode() {
    _isLoginMode = !_isLoginMode;
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia los mensajes de error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Permite usar la herramienta sin autenticarse (modo invitado).
  void continueAsGuest() {
    _guestMode = true;
    _errorMessage = null;
    notifyListeners();
  }

  /// Inicia sesión con correo y contraseña.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.login(email: email.trim(), password: password);
      _guestMode = false;
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registra una nueva cuenta de usuario.
  Future<bool> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.register(
        nombre: nombre.trim(),
        email: email.trim(),
        password: password,
      );
      _guestMode = false;
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cierra la sesión activa.
  void logout() {
    _repository.logout();
    _guestMode = false;
    _errorMessage = null;
    notifyListeners();
  }

  String _cleanError(Object e) {
    final str = e.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str;
  }
}
