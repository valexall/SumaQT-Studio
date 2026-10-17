import 'package:flutter/material.dart';

/// [CustomPainter] que dibuja un patrón de tablero de ajedrez para
/// indicar transparencia en imágenes PNG.
class CheckerPainter extends CustomPainter {
  static const double _tileSize = 16.0;
  static const Color _light = Color(0xFFFFFFFF);
  static const Color _dark = Color(0xFFCBCBCB);

  @override
  void paint(Canvas canvas, Size size) {
    final paintLight = Paint()..color = _light;
    final paintDark = Paint()..color = _dark;

    final cols = (size.width / _tileSize).ceil();
    final rows = (size.height / _tileSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final rect = Rect.fromLTWH(
          col * _tileSize,
          row * _tileSize,
          _tileSize,
          _tileSize,
        );
        canvas.drawRect(rect, (row + col).isEven ? paintLight : paintDark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
