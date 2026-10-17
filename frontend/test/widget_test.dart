import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/main.dart';
import 'package:frontend/data/repositories/remove_bg_repository.dart';
import 'package:frontend/data/services/file_picker_service.dart';
import 'package:frontend/data/services/remove_bg_service.dart';
import 'package:frontend/ui/features/remove_bg/view_models/remove_bg_view_model.dart';
import 'package:frontend/ui/features/remove_bg/views/remove_bg_view.dart';

void main() {
  testWidgets('RemoveBgView smoke test: muestra el hero inicial',
      (WidgetTester tester) async {
    final viewModel = RemoveBgViewModel(
      repository: RemoveBgRepository(service: RemoveBgService()),
      filePickerService: FilePickerService(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<RemoveBgViewModel>.value(
        value: viewModel,
        child: MaterialApp(
          home: RemoveBgView(viewModel: viewModel),
        ),
      ),
    );

    // La vista inicial debe mostrar el titular del hero
    expect(find.textContaining('Quita el fondo'), findsOneWidget);
    expect(find.text('Cargar imagen'), findsOneWidget);
  });

  testWidgets('SumaQtStudioApp arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const SumaQtStudioApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
