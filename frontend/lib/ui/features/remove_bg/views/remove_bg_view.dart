import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/remove_bg_view_model.dart';
import 'widgets/gradient_button.dart';
import 'widgets/hero_section.dart';
import 'widgets/image_panel.dart';

/// Vista principal de la funcionalidad remove-bg.
///
/// Widget "dumb": sólo renderiza el estado expuesto por [RemoveBgViewModel].
/// Usa [ListenableBuilder] para reconstruirse ante cada [notifyListeners].
class RemoveBgView extends StatelessWidget {
  const RemoveBgView({
    super.key,
    required this.viewModel,
    this.mostrarAppBar = true,
    this.authViewModel,
  });

  final RemoveBgViewModel viewModel;
  final bool mostrarAppBar;
  final AuthViewModel? authViewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: mostrarAppBar ? _buildAppBar(context) : null,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                vertical: 40.0,
                horizontal: 24.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: viewModel.imagenOriginal == null
                    ? HeroSection(
                        onCargar: viewModel.seleccionarYProcesar,
                        procesando: viewModel.procesando,
                      )
                    : _buildResultado(context),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B303A),
              ),
              children: [
                TextSpan(text: 'Suma'),
                TextSpan(
                  text: 'Qt',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: ' Studio',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (authViewModel != null && authViewModel!.hasUserSession) ...[
          Center(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    (authViewModel!.currentUser?.nombre.isNotEmpty ?? false)
                        ? authViewModel!.currentUser!.nombre[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  authViewModel!.currentUser?.nombre ?? 'Usuario',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () => authViewModel!.logout(),
            icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          const SizedBox(width: 16),
        ] else ...[
          TextButton(
            onPressed: () {
              if (authViewModel != null) {
                if (!authViewModel!.isLoginMode) authViewModel!.toggleMode();
                authViewModel!.logout();
              }
            },
            child: const Text(
              'Iniciar sesión',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: () {
                if (authViewModel != null) {
                  if (authViewModel!.isLoginMode) authViewModel!.toggleMode();
                  authViewModel!.logout();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Registrarse',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Sección resultado ─────────────────────────────────────────────

  Widget _buildResultado(BuildContext context) {
    return Column(
      children: [
        // ── Estado de procesamiento ──
        if (viewModel.procesando)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 12),
                Text(
                  'Procesando imagen con rembg…',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // ── Banner de error ──
        if (viewModel.error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    viewModel.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

        // ── Comparativa: original vs resultado ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ImagePanel(
                titulo: 'Original',
                bytes: viewModel.imagenOriginal,
                etiqueta: viewModel.nombreArchivo,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ImagePanel(
                titulo: 'Sin fondo',
                bytes: viewModel.imagenResultado,
                etiqueta: viewModel.procesando
                    ? 'Procesando…'
                    : (viewModel.imagenResultado == null
                        ? 'Esperando…'
                        : 'Listo ✓'),
                checkerBackground: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ── Acciones ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: viewModel.limpiar,
              icon: const Icon(Icons.refresh),
              label: const Text('Nueva imagen'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (viewModel.imagenResultado != null)
              GradientButton(
                label: 'Descargar PNG',
                icon: Icons.download,
                onPressed: () => _descargar(context),
              ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Future<void> _descargar(BuildContext context) async {
    final ruta = await viewModel.descargar();
    if (ruta != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado: $ruta'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}
