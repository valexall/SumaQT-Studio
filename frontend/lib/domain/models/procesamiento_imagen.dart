import 'dart:typed_data';

/// Modelo de dominio que representa el resultado de un procesamiento de imagen.
class ProcesamientoImagen {
  const ProcesamientoImagen({
    required this.bytesResultado,
    required this.nombreOriginal,
  });

  /// Bytes del PNG resultante sin fondo.
  final Uint8List bytesResultado;

  /// Nombre del archivo original enviado al backend.
  final String nombreOriginal;
}
