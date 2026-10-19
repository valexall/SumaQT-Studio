import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../remove_bg/views/widgets/checker_painter.dart';
import '../../view_models/ordenes_view_model.dart';
import 'dialog_comparar_lote.dart';

/// Vista de entrega y galería interactiva de resultados para el Paso 3.
/// Ofrece comparación antes/después, descarga masiva, previsualización modal y UX moderna.
class EntregaGaleriaUx extends StatelessWidget {
  const EntregaGaleriaUx({super.key, required this.viewModel});

  final OrdenesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final orden = viewModel.ordenSeleccionada!;
    final completados = viewModel.archivos
        .where((a) => a.estado == EstadoSubida.completado)
        .toList();
    final puedeCerrar = !orden.estaEntregada && orden.imagenesProcesadas > 0 && !viewModel.enviando;
    final completa = orden.imagenesProcesadas >= orden.totalImagenes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Tarjeta de Estado / Lead Time ──
        _buildBannerEstado(context, orden),
        const SizedBox(height: 16),

        // ── Barra de acciones de entrega ──
        if (!orden.estaEntregada) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    completa
                        ? 'Todas las imágenes fueron procesadas con éxito. Ya puedes cerrar y entregar la orden.'
                        : 'Lote en progreso (${orden.imagenesProcesadas} de ${orden.totalImagenes}). Puedes seguir subiendo o cerrar la orden anticipadamente.',
                    style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: puedeCerrar ? viewModel.cerrarOrden : null,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Cerrar y Entregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Cabecera de Galería + Descarga Masiva ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Catálogo de Entregables (${completados.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (completados.isNotEmpty)
              ElevatedButton.icon(
                onPressed: viewModel.cargando ? null : viewModel.descargarTodoElLote,
                icon: const Icon(Icons.download_for_offline, size: 18),
                label: Text(
                  completados.length > 1 ? 'Descargar Lote en ZIP' : 'Descargar Imagen',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Grid interactivo de imágenes ──
        if (completados.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.hourglass_empty, size: 36, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text(
                  'Aún no hay imágenes listas para entregar.',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 340,
            ),
            itemCount: completados.length,
            itemBuilder: (context, index) {
              final arch = completados[index];
              return _TarjetaEntregable(
                archivo: arch,
                numero: index + 1,
                onComparar: () => DialogCompararLote.mostrar(
                  context,
                  archivos: completados,
                  indiceInicial: index,
                  onDescargar: viewModel.descargarResultado,
                ),
                onDescargar: () => viewModel.descargarResultado(arch),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBannerEstado(BuildContext context, dynamic orden) {
    final estaEntregada = orden.estaEntregada as bool;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estaEntregada
              ? [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]
              : [const Color(0xFFF0FDF4), const Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: estaEntregada ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: estaEntregada ? Colors.green : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              estaEntregada ? Icons.verified : Icons.timelapse,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estaEntregada
                      ? 'Orden Certificada y Entregada'
                      : 'Orden en Proceso de Producción',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  estaEntregada
                      ? 'Entregada el: ${orden.cerradaEn?.toString().substring(0, 16).replaceFirst('T', ' ') ?? '—'} · Todos los archivos están en Storage.'
                      : 'Cliente: ${orden.clienteNombre} (${orden.clienteEmail}) · Listo para descargar o auditar.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta individual para el catálogo de resultados con visor transparente y antes/después
class _TarjetaEntregable extends StatefulWidget {
  const _TarjetaEntregable({
    required this.archivo,
    required this.numero,
    required this.onComparar,
    required this.onDescargar,
  });

  final ArchivoEnProceso archivo;
  final int numero;
  final VoidCallback onComparar;
  final VoidCallback onDescargar;

  @override
  State<_TarjetaEntregable> createState() => _TarjetaEntregableState();
}

class _TarjetaEntregableState extends State<_TarjetaEntregable> {
  bool _mostrarOriginal = false;

  @override
  Widget build(BuildContext context) {
    final arch = widget.archivo;
    final tieneOriginal = arch.tieneOriginal;
    final url = arch.urlResultado;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Área de Imagen con fondo ajedrezado / checkerboard ──
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!_mostrarOriginal) CustomPaint(painter: CheckerPainter()),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _mostrarOriginal
                              ? _buildOriginal(arch)
                              : _buildResultado(arch),
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge de número de foto
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${widget.numero}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),

                // Etiqueta flotante de versión (Original vs Sin Fondo)
                Positioned(
                  top: 8,
                  left: 42,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (_mostrarOriginal ? Colors.black87 : Colors.green)
                          .withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _mostrarOriginal ? 'Original' : 'Sin fondo ✓',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Botón para alternar Original
                if (tieneOriginal)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        iconSize: 18,
                        tooltip: _mostrarOriginal ? 'Ver sin fondo' : 'Ver original',
                        icon: Icon(
                          _mostrarOriginal ? Icons.auto_awesome : Icons.image,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() => _mostrarOriginal = !_mostrarOriginal);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Pie de tarjeta con info y descarga ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.archivo.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onComparar,
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 15),
                        label: const Text('Comparar', style: TextStyle(fontSize: 11.5)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onDescargar,
                        icon: const Icon(Icons.download, size: 15),
                        label: const Text('Descargar', style: TextStyle(fontSize: 11.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (url != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.link, size: 14),
                      label: const Text('Copiar enlace público', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enlace copiado al portapapeles.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginal(ArchivoEnProceso arch) {
    if (arch.bytes.isNotEmpty) {
      return Image.memory(arch.bytes, fit: BoxFit.contain);
    }
    if (arch.urlOriginal != null) {
      return Image.network(
        arch.urlOriginal!,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, p) => p == null ? child : const CircularProgressIndicator(strokeWidth: 2),
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
      );
    }
    return const Icon(Icons.image, size: 30, color: Colors.grey);
  }

  Widget _buildResultado(ArchivoEnProceso arch) {
    if (arch.bytesResultado != null && arch.bytesResultado!.isNotEmpty) {
      return Image.memory(arch.bytesResultado!, fit: BoxFit.contain);
    }
    if (arch.urlResultado != null) {
      return Image.network(
        arch.urlResultado!,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, p) => p == null ? child : const CircularProgressIndicator(strokeWidth: 2),
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
      );
    }
    return const Icon(Icons.image, size: 30, color: Colors.grey);
  }
}
