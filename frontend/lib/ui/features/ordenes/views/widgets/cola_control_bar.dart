import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../view_models/ordenes_view_model.dart';

/// Barra de control interactiva para la cola de procesamiento del Paso 2.
/// Incluye barra de progreso, badges de conteo, selector de vista (cuadrícula/lista)
/// y botón de descarga rápida del lote en ZIP.
class ColaControlBar extends StatelessWidget {
  const ColaControlBar({super.key, required this.viewModel});

  final OrdenesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final archivos = viewModel.archivos;
    final total = archivos.length;
    final completados = archivos.where((a) => a.estado == EstadoSubida.completado).length;
    final enProceso = archivos.where((a) => a.estado == EstadoSubida.procesando).length;
    final enEspera = archivos.where((a) => a.estado == EstadoSubida.enEspera).length;
    final fallidos = archivos.where((a) => a.estado == EstadoSubida.fallido).length;

    final double progreso = total == 0 ? 0 : (completados / total);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                viewModel.procesando ? Icons.sync : Icons.layers_outlined,
                color: viewModel.procesando ? AppColors.primary : const Color(0xFF1E293B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                viewModel.procesando
                    ? 'Procesando imágenes del lote…'
                    : 'Lote de imágenes ($total fotos)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),

              // Selector de vista: Cuadrícula (Cards) vs Lista
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.grid_view, size: 16),
                    tooltip: 'Vista en cuadrícula (recomendada para lotes)',
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.view_list, size: 16),
                    tooltip: 'Vista en lista compacta',
                  ),
                ],
                selected: {viewModel.vistaCuadricula},
                onSelectionChanged: (_) => viewModel.alternarVista(),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),

              // Porcentaje
              Text(
                '${(progreso * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? null : progreso,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _badge('Listas', '$completados', Colors.green, Icons.check_circle_outline),
              if (enProceso > 0)
                _badge('En curso', '$enProceso', AppColors.primary, Icons.motion_photos_on_outlined),
              if (enEspera > 0)
                _badge('En cola', '$enEspera', const Color(0xFF64748B), Icons.hourglass_top),
              if (fallidos > 0)
                _badge('Fallidas', '$fallidos', Colors.red, Icons.error_outline),

              const Spacer(),

              // Descarga masiva rápida en ZIP
              if (completados > 0)
                ElevatedButton.icon(
                  onPressed: viewModel.cargando ? null : viewModel.descargarTodoElLote,
                  icon: const Icon(Icons.archive_outlined, size: 15),
                  label: Text(
                    completados > 1 ? 'Descargar lote ($completados en ZIP)' : 'Descargar foto',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

              if (enEspera > 0) ...[
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: viewModel.cancelarPendientesEnCola,
                  icon: const Icon(Icons.clear_all, size: 16, color: Colors.red),
                  label: const Text(
                    'Cancelar pendientes',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String etiqueta, String conteo, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$etiqueta: $conteo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
