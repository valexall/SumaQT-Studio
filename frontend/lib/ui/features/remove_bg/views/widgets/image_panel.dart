import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'checker_painter.dart';

/// Panel que muestra una imagen con encabezado de título y etiqueta.
/// Cuando [checkerBackground] es [true], pinta el patrón de transparencia.
class ImagePanel extends StatelessWidget {
  const ImagePanel({
    super.key,
    required this.titulo,
    required this.bytes,
    this.etiqueta,
    this.checkerBackground = false,
  });

  final String titulo;
  final Uint8List? bytes;
  final String? etiqueta;
  final bool checkerBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: checkerBackground ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            _buildImageArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (etiqueta != null)
            Flexible(
              child: Text(
                etiqueta!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    const placeholder = Center(
      child: Icon(Icons.image_outlined, size: 64, color: Colors.black12),
    );

    return SizedBox(
      height: 380,
      child: checkerBackground
          ? Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: CheckerPainter()),
                if (bytes != null)
                  Image.memory(bytes!, fit: BoxFit.contain)
                else
                  placeholder,
              ],
            )
          : (bytes != null
              ? Image.memory(bytes!, fit: BoxFit.contain)
              : placeholder),
    );
  }
}
