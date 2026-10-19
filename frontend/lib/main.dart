import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/remove_bg_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/file_picker_service.dart';
import 'data/services/remove_bg_service.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/auth/views/auth_view.dart';
import 'ui/features/remove_bg/view_models/remove_bg_view_model.dart';
import 'ui/features/remove_bg/views/remove_bg_view.dart';

void main() {
  runApp(const SumaQtStudioApp());
}

class SumaQtStudioApp extends StatelessWidget {
  const SumaQtStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Autenticación ──────────────────────────────────────────
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(
            repository: AuthRepository(
              service: AuthService(),
            ),
          ),
        ),

        // ── Quitar Fondo ───────────────────────────────────────────
        ChangeNotifierProvider<RemoveBgViewModel>(
          create: (_) => RemoveBgViewModel(
            repository: RemoveBgRepository(
              service: RemoveBgService(),
            ),
            filePickerService: FilePickerService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SumaQt Studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Consumer<AuthViewModel>(
          builder: (context, authViewModel, _) {
            if (authViewModel.isAuthenticated) {
              return RemoveBgView(
                viewModel: context.read<RemoveBgViewModel>(),
                authViewModel: authViewModel,
              );
            }
            return AuthView(viewModel: authViewModel);
          },
        ),
      ),
    );
  }
}
