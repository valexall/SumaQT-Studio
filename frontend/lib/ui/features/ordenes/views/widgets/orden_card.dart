import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../domain/models/orden.dart';

/// Tarjeta moderna tipo SaaS para una orden en el Dashboard.
/// Incluye barra de progreso visual, avatares con iniciales, badges y menú de acciones directo.
class OrdenCard extends StatelessWidget {
  const OrdenCard({
    super.key,
    required this.orden,
    required this.onTap,
    this.onEditar,
    this.onEliminar,
  });

  final Orden orden;
  final VoidCallback onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context) {
    final progreso = orden.totalImagenes == 0
        ? 0.0
        : (orden.imagenesProcesadas / orden.totalImagenes).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar / Iniciales del Proyecto
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.primaryAccent.withValues(alpha: 0.25),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        orden.nombreProyecto.isNotEmpty
                            ? orden.nombreProyecto.substring(0, 1).toUpperCase()
                            : 'O',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Título y datos del cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  orden.nombreProyecto,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _ChipEstado(estado: orden.estado),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    orden.clienteNombre,
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    orden.clienteEmail,
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Menú contextual directo
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                      tooltip: 'Opciones de orden',
                      onSelected: (val) {
                        if (val == 'editar' && onEditar != null) onEditar!();
                        if (val == 'eliminar' && onEliminar != null) onEliminar!();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF334155)),
                              SizedBox(width: 8),
                              Text('Corregir datos'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar orden', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Barra de progreso del lote y conteo
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progreso,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            orden.estaEntregada ? Colors.green : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${orden.imagenesProcesadas}/${orden.totalImagenes} procesadas (${(progreso * 100).toInt()}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.estado});

  final EstadoOrden estado;

  @override
  Widget build(BuildContext context) {
    final (etiqueta, color, icono) = switch (estado) {
      EstadoOrden.pendiente => ('Pendiente', const Color(0xFFD97706), Icons.hourglass_empty),
      EstadoOrden.procesando => ('Procesando', AppColors.primary, Icons.sync),
      EstadoOrden.entregada => ('Entregada', Colors.green, Icons.check_circle),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
