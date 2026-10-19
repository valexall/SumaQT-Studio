import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/ordenes_repository.dart';
import 'data/repositories/remove_bg_repository.dart';
import 'data/services/file_picker_service.dart';
import 'data/services/ordenes_service.dart';
import 'data/services/remove_bg_service.dart';
import 'ui/features/ordenes/view_models/ordenes_view_model.dart';
import 'ui/features/ordenes/views/ordenes_view.dart';
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
        ChangeNotifierProvider<OrdenesViewModel>(
          create: (_) => OrdenesViewModel(
            repository: OrdenesRepository(service: OrdenesService()),
            filePickerService: FilePickerService(),
          )..cargarOrdenes(),
        ),
      ],
      child: MaterialApp(
        title: 'SumaQt Studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _HomeShell(),
      ),
    );
  }
}

/// Contenedor con Barra de Navegación superior (Navbar unificado):
/// Pestañas: Quitar fondo / Órdenes de trabajo, junto a Iniciar sesión y Registrarse.
class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              // ── Logotipo & Marca ──
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 26),
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
              const SizedBox(width: 36),

              // ── Pestañas de Navegación en el Navbar ──
              _NavItem(
                titulo: 'Quitar fondo',
                icono: Icons.auto_fix_high,
                seleccionado: _indice == 0,
                onTap: () => setState(() => _indice = 0),
              ),
              const SizedBox(width: 12),
              _NavItem(
                titulo: 'Órdenes de trabajo',
                icono: Icons.assignment_turned_in_outlined,
                seleccionado: _indice == 1,
                onTap: () {
                  context.read<OrdenesViewModel>().cargarOrdenes();
                  setState(() => _indice = 1);
                },
              ),

              const Spacer(),

              // ── Botones de Sesión y Registro ──
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    color: Color(0xFF2B303A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Registrarse',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _indice,
        children: [
          Builder(
            builder: (context) => RemoveBgView(
              viewModel: context.read<RemoveBgViewModel>(),
              mostrarAppBar: false,
            ),
          ),
          Builder(
            builder: (context) => OrdenesView(
              viewModel: context.read<OrdenesViewModel>(),
              mostrarAppBar: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.titulo,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
  });

  final String titulo;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icono,
              size: 20,
              color: seleccionado ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
                color: seleccionado ? AppColors.primary : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
