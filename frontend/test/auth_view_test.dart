import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/user_api_model.dart';
import 'package:frontend/data/repositories/auth_repository.dart';
import 'package:frontend/data/services/auth_service.dart';
import 'package:frontend/ui/features/auth/view_models/auth_view_model.dart';
import 'package:frontend/ui/features/auth/views/auth_view.dart';

class MockAuthService extends Fake implements AuthService {
  @override
  Future<AuthResponseApiModel> login({
    required String email,
    required String password,
  }) async {
    return AuthResponseApiModel(
      accessToken: 'fake_jwt_token',
      tokenType: 'bearer',
      usuario: UserApiModel(
        id: 1,
        nombre: 'Usuario Test',
        email: email,
        creadoEn: DateTime.now(),
      ),
    );
  }

  @override
  Future<AuthResponseApiModel> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    return AuthResponseApiModel(
      accessToken: 'fake_jwt_token_register',
      tokenType: 'bearer',
      usuario: UserApiModel(
        id: 2,
        nombre: nombre,
        email: email,
        creadoEn: DateTime.now(),
      ),
    );
  }
}

void main() {
  group('AuthView Widget Tests', () {
    late AuthViewModel viewModel;

    setUp(() {
      final repo = AuthRepository(service: MockAuthService());
      viewModel = AuthViewModel(repository: repo);
    });

    testWidgets('Muestra el formulario de inicio de sesión por defecto',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthView(viewModel: viewModel),
        ),
      );

      // Verificamos encabezado y botones del modo Login
      expect(find.text('SumaQt Studio'), findsOneWidget);
      expect(find.text('Inicia sesión para continuar'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Nombre completo'), findsNothing);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Regístrate aquí'), findsOneWidget);
    });

    testWidgets('Alterna a modo registro al pulsar "Regístrate aquí"',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthView(viewModel: viewModel),
        ),
      );

      // Pulsamos alternar a Registro
      await tester.tap(find.text('Regístrate aquí'));
      await tester.pump();

      // Debe aparecer el campo Nombre Completo y el botón Crear Cuenta
      expect(find.text('Crea tu cuenta de diseñador'), findsOneWidget);
      expect(find.text('Nombre completo'), findsOneWidget);
      expect(find.text('Crear Cuenta'), findsOneWidget);
      expect(find.text('Inicia Sesión'), findsOneWidget);
    });

    testWidgets('Permite continuar como invitado sin credenciales',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthView(viewModel: viewModel),
        ),
      );

      expect(viewModel.guestMode, isFalse);
      expect(viewModel.isAuthenticated, isFalse);

      await tester.tap(find.text('Continuar como invitado (sin login)'));
      await tester.pump();

      expect(viewModel.guestMode, isTrue);
      expect(viewModel.isAuthenticated, isTrue);
    });
  });
}
