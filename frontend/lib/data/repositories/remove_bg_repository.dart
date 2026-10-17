import 'dart:typed_data';

import '../services/remove_bg_service.dart';
import '../../domain/models/procesamiento_imagen.dart';

/// Repositorio que orquesta [RemoveBgService] y expone modelos de dominio.
/// Es la única fuente de verdad para el procesamiento de imágenes.
class RemoveBgRepository {
  RemoveBgRepository({required RemoveBgService service})
      : _service = service;

  final RemoveBgService _service;

  /// Envía la imagen al backend y retorna un [ProcesamientoImagen].
  /// Propaga [RemoveBgServiceException] ante errores del servidor.
  Future<ProcesamientoImagen> quitarFondo(
    Uint8List bytes,
    String nombreArchivo,
  ) async {
    final bytesResultado =
        await _service.procesarImagen(bytes, nombreArchivo);

    return ProcesamientoImagen(
      bytesResultado: bytesResultado,
      nombreOriginal: nombreArchivo,
    );
  }
}
