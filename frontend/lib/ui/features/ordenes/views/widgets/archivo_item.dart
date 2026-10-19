import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../remove_bg/views/widgets/checker_painter.dart';
import '../../view_models/ordenes_view_model.dart';

/// Tarjeta visual optimizada para procesamiento por lotes (Paso 2).
/// Muestra número de foto en el lote, previsualización interactiva con fondo
/// ajedrezado transparente, alternador original/sin fondo y botón de comparación.
class ArchivoLoteCard extends StatefulWidget {
  const ArchivoLoteCard({
    super.key,
    required this.archivo,
    required this.numero,
    required this.onComparar,
    required this.onDescargar,
    required this.onReintentar,
    this.onQuitarDeCola,
  });

  final ArchivoEnProceso archivo;
  final int numero;
  final VoidCallback onComparar;
  final VoidCallback onDescargar;
  final VoidCallback onReintentar;
  final VoidCallback? onQuitarDeCola;

  @override
  State<ArchivoLoteCard> createState() => _ArchivoLoteCardState();
}

class _ArchivoLoteCardState extends State<ArchivoLoteCard> {
  bool _mostrarOriginal = false;

  @override
  Widget build(BuildContext context) {
    final arch = widget.archivo;
    final esCompletado = arch.estado == EstadoSubida.completado;
    final esProcesando = arch.estado == EstadoSubida.procesando;
    final esEnEspera = arch.estado == EstadoSubida.enEspera;
    final esFallido = arch.estado == EstadoSubida.fallido;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esProcesando
              ? AppColors.primary
              : (esFallido ? Colors.red.shade200 : const Color(0xFFE2E8F0)),
          width: esProcesando ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cabecera de la Tarjeta con Número e Identificador ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Container(
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      arch.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _BadgeEstado(estado: arch.estado),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── Área de Previsualización Visual (Ajedrezada para PNG) ──
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo ajedrezado para mostrar transparencia real como en Quitar Fondo
                  if (esCompletado && !_mostrarOriginal)
                    CustomPaint(painter: CheckerPainter()),

                  // Contenido de la Imagen
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildImagen(arch),
                    ),
                  ),

                  // Overlay animado mientras rembg procesa
                  if (esProcesando)
                    Container(
                      color: Colors.white.withValues(alpha: 0.75),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 10),
                          Text(
                            'Removiendo fondo…',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Overlay si está en espera en cola
                  if (esEnEspera)
                    Container(
                      color: Colors.white.withValues(alpha: 0.6),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'En cola de espera',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (widget.onQuitarDeCola != null) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                              tooltip: 'Quitar de la cola',
                              onPressed: widget.onQuitarDeCola,
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Botón flotante para alternar Original ↔ Sin fondo
                  if (esCompletado && arch.tieneOriginal)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _mostrarOriginal = !_mostrarOriginal),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _mostrarOriginal ? Icons.auto_awesome : Icons.image,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _mostrarOriginal ? 'Ver sin fondo' : 'Ver original',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Etiqueta flotante versión
                  if (esCompletado)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: (_mostrarOriginal ? Colors.black87 : AppColors.primary)
                              .withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _mostrarOriginal ? 'Original' : 'Sin fondo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── Barra Inferior de Acciones ──
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Botón Comparar / Inspeccionar
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

                  // Botón Descargar o Reintentar
                  if (esFallido)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onReintentar,
                        icon: const Icon(Icons.refresh, size: 15),
                        label: const Text('Reintentar', style: TextStyle(fontSize: 11.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: esCompletado ? widget.onDescargar : null,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagen(ArchivoEnProceso arch) {
    if (_mostrarOriginal && arch.tieneOriginal) {
      if (arch.bytes.isNotEmpty) {
        return Image.memory(arch.bytes, fit: BoxFit.contain);
      }
      if (arch.urlOriginal != null) {
        return Image.network(arch.urlOriginal!, fit: BoxFit.contain);
      }
    }

    if (arch.estado == EstadoSubida.completado) {
      if (arch.bytesResultado != null && arch.bytesResultado!.isNotEmpty) {
        return Image.memory(arch.bytesResultado!, fit: BoxFit.contain);
      }
      if (arch.urlResultado != null) {
        return Image.network(
          arch.urlResultado!,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, prog) => prog == null
              ? child
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 36, color: Colors.grey),
        );
      }
    }

    // Si aún no está completada, mostrar la imagen original seleccionada
    if (arch.bytes.isNotEmpty) {
      return Image.memory(arch.bytes, fit: BoxFit.contain);
    }
    if (arch.urlOriginal != null) {
      return Image.network(arch.urlOriginal!, fit: BoxFit.contain);
    }

    return const Icon(Icons.image_outlined, size: 36, color: Colors.grey);
  }
}

/// Fila compacta de lista para un archivo dentro del paso 2.
class ArchivoItem extends StatelessWidget {
  const ArchivoItem({
    super.key,
    required this.archivo,
    required this.numero,
    required this.onComparar,
    required this.onReintentar,
    required this.onDescargar,
    this.onQuitarDeCola,
  });

  final ArchivoEnProceso archivo;
  final int numero;
  final VoidCallback onComparar;
  final VoidCallback onReintentar;
  final VoidCallback onDescargar;
  final VoidCallback? onQuitarDeCola;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Número en el lote
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$numero',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Miniatura con soporte para ajedrezado
          _MiniaturaConChecker(archivo: archivo),
          const SizedBox(width: 12),

          // Nombre y estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  archivo.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  switch (archivo.estado) {
                    EstadoSubida.enEspera => 'En cola de procesamiento…',
                    EstadoSubida.procesando => 'Removiendo fondo con rembg…',
                    EstadoSubida.completado => 'Sin fondo ✓ (PNG transparente listo)',
                    EstadoSubida.fallido => archivo.mensajeError ?? 'Error al procesar',
                  },
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: switch (archivo.estado) {
                      EstadoSubida.enEspera => const Color(0xFF64748B),
                      EstadoSubida.procesando => AppColors.primary,
                      EstadoSubida.completado => Colors.green,
                      EstadoSubida.fallido => Colors.red,
                    },
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Botones de acción
          OutlinedButton.icon(
            onPressed: onComparar,
            icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
            label: const Text('Ver'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 6),

          switch (archivo.estado) {
            EstadoSubida.enEspera => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary),
                  ),
                  if (onQuitarDeCola != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      tooltip: 'Quitar de la cola',
                      onPressed: onQuitarDeCola,
                    ),
                ],
              ),
            EstadoSubida.procesando => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            EstadoSubida.completado => ElevatedButton.icon(
                onPressed: onDescargar,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Descargar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            EstadoSubida.fallido => ElevatedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          },
        ],
      ),
    );
  }
}

class _MiniaturaConChecker extends StatelessWidget {
  const _MiniaturaConChecker({required this.archivo});

  final ArchivoEnProceso archivo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (archivo.estado == EstadoSubida.completado)
              CustomPaint(painter: CheckerPainter()),
            _renderImg(),
          ],
        ),
      ),
    );
  }

  Widget _renderImg() {
    if (archivo.estado == EstadoSubida.completado) {
      if (archivo.bytesResultado != null && archivo.bytesResultado!.isNotEmpty) {
        return Image.memory(archivo.bytesResultado!, fit: BoxFit.cover);
      }
      if (archivo.urlResultado != null) {
        return Image.network(archivo.urlResultado!, fit: BoxFit.cover);
      }
    }
    if (archivo.bytes.isNotEmpty) {
      return Image.memory(archivo.bytes, fit: BoxFit.cover);
    }
    if (archivo.urlOriginal != null) {
      return Image.network(archivo.urlOriginal!, fit: BoxFit.cover);
    }
    return const Icon(Icons.image, size: 24, color: Colors.grey);
  }
}

class _BadgeEstado extends StatelessWidget {
  const _BadgeEstado({required this.estado});

  final EstadoSubida estado;

  @override
  Widget build(BuildContext context) {
    final (texto, color, icono) = switch (estado) {
      EstadoSubida.enEspera => ('En cola', const Color(0xFF64748B), Icons.hourglass_top),
      EstadoSubida.procesando => ('Procesando', AppColors.primary, Icons.sync),
      EstadoSubida.completado => ('Listo ✓', Colors.green, Icons.check),
      EstadoSubida.fallido => ('Error', Colors.red, Icons.error_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            texto,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
