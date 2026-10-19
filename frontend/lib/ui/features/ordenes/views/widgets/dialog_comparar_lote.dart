import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../remove_bg/views/widgets/checker_painter.dart';
import '../../view_models/ordenes_view_model.dart';

/// Modal interactivo tipo inspector para lotes de fotos.
/// Permite comparar lado a lado o alternar entre la foto original y la
/// imagen sin fondo, navegar secuencialmente por todas las fotos del lote
/// (← / →) y descargar directamente la foto seleccionada.
class DialogCompararLote extends StatefulWidget {
  const DialogCompararLote({
    super.key,
    required this.archivos,
    required this.indiceInicial,
    required this.onDescargar,
  });

  final List<ArchivoEnProceso> archivos;
  final int indiceInicial;
  final Future<void> Function(ArchivoEnProceso archivo) onDescargar;

  static Future<void> mostrar(
    BuildContext context, {
    required List<ArchivoEnProceso> archivos,
    required int indiceInicial,
    required Future<void> Function(ArchivoEnProceso archivo) onDescargar,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DialogCompararLote(
        archivos: archivos,
        indiceInicial: indiceInicial,
        onDescargar: onDescargar,
      ),
    );
  }

  @override
  State<DialogCompararLote> createState() => _DialogCompararLoteState();
}

class _DialogCompararLoteState extends State<DialogCompararLote> {
  late int _indiceActual;
  bool _descargando = false;

  @override
  void initState() {
    super.initState();
    _indiceActual = widget.indiceInicial.clamp(0, widget.archivos.length - 1);
  }

  void _anterior() {
    if (_indiceActual > 0) {
      setState(() => _indiceActual--);
    }
  }

  void _siguiente() {
    if (_indiceActual < widget.archivos.length - 1) {
      setState(() => _indiceActual++);
    }
  }

  Future<void> _ejecutarDescarga(ArchivoEnProceso archivo) async {
    setState(() => _descargando = true);
    try {
      await widget.onDescargar(archivo);
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.archivos.isEmpty) return const SizedBox.shrink();

    final archivo = widget.archivos[_indiceActual];
    final total = widget.archivos.length;
    final esPrimero = _indiceActual == 0;
    final esUltimo = _indiceActual == total - 1;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _anterior,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _siguiente,
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 780),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Barra Superior (Navegación e Identificación) ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Foto ${_indiceActual + 1} de $total',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              archivo.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Comparativa en alta fidelidad: Original vs. Sin fondo',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botones de navegación en lote
                      IconButton.outlined(
                        tooltip: 'Foto anterior (←)',
                        onPressed: esPrimero ? null : _anterior,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      const SizedBox(width: 6),
                      IconButton.outlined(
                        tooltip: 'Foto siguiente (→)',
                        onPressed: esUltimo ? null : _siguiente,
                        icon: const Icon(Icons.chevron_right),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // ── Área de Comparación Visual (Lado a Lado) ──
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Panel Izquierdo: Original
                        Expanded(
                          child: _PanelFoto(
                            titulo: 'Original',
                            subtitulo: 'Con fondo original',
                            badgeColor: const Color(0xFF475569),
                            icono: Icons.image_outlined,
                            contenido: _buildOriginalWidget(archivo),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Panel Derecho: Sin Fondo
                        Expanded(
                          child: _PanelFoto(
                            titulo: 'Sin Fondo (Resultado rembg)',
                            subtitulo: 'Transparente (PNG)',
                            badgeColor: AppColors.primary,
                            icono: Icons.auto_awesome,
                            conAjedrezado: true,
                            contenido: _buildResultadoWidget(archivo),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Barra Inferior de Acciones ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            archivo.estado == EstadoSubida.completado
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: archivo.estado == EstadoSubida.completado
                                ? Colors.green
                                : Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            archivo.estado == EstadoSubida.completado
                                ? 'Fondo removido con éxito · Listo para entrega'
                                : 'Estado: ${archivo.estado.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (archivo.urlResultado != null) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: archivo.urlResultado!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('URL pública copiada al portapapeles.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.link, size: 16),
                              label: const Text('Copiar enlace'),
                            ),
                            const SizedBox(width: 10),
                          ],
                          ElevatedButton.icon(
                            onPressed: _descargando ? null : () => _ejecutarDescarga(archivo),
                            icon: _descargando
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download, size: 18),
                            label: Text(_descargando ? 'Guardando…' : 'Descargar esta foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalWidget(ArchivoEnProceso archivo) {
    if (archivo.bytes.isNotEmpty) {
      return Image.memory(
        archivo.bytes,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }
    if (archivo.urlOriginal != null && archivo.urlOriginal!.isNotEmpty) {
      return Image.network(
        archivo.urlOriginal!,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, prog) => prog == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Original no disponible en memoria.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoWidget(ArchivoEnProceso archivo) {
    if (archivo.bytesResultado != null && archivo.bytesResultado!.isNotEmpty) {
      return Image.memory(
        archivo.bytesResultado!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }
    if (archivo.urlResultado != null && archivo.urlResultado!.isNotEmpty) {
      return Image.network(
        archivo.urlResultado!,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, prog) => prog == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Procesando o esperando resultado…',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PanelFoto extends StatelessWidget {
  const _PanelFoto({
    required this.titulo,
    required this.subtitulo,
    required this.badgeColor,
    required this.icono,
    required this.contenido,
    this.conAjedrezado = false,
  });

  final String titulo;
  final String subtitulo;
  final Color badgeColor;
  final IconData icono;
  final Widget contenido;
  final bool conAjedrezado;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera del panel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(icono, size: 16, color: badgeColor),
                  const SizedBox(width: 8),
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: badgeColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    subtitulo,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Visualizador
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (conAjedrezado) CustomPaint(painter: CheckerPainter()),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: contenido,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
