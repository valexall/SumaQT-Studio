import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Contenedor de una etapa numerada del flujo E2E.
/// Cada sección rotula el paso que representa en el proceso.
class SeccionPaso extends StatelessWidget {
  const SeccionPaso({
    super.key,
    required this.numero,
    required this.titulo,
    required this.detalle,
    required this.child,
    this.accion,
  });

  final int numero;
  final String titulo;
  final String detalle;
  final Widget child;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$numero',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      detalle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ?accion,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
