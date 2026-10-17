import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/remove_bg_repository.dart';
import 'data/services/file_picker_service.dart';
import 'data/services/remove_bg_service.dart';
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
        // ── Registro de dependencias (DI manual con constructor injection) ──
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
        // Builder permite leer el Provider sin depender del contexto raíz
        home: Builder(
          builder: (context) => RemoveBgView(
            viewModel: context.read<RemoveBgViewModel>(),
          ),
        ),
      ),
    );
  }
}
