import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Modelo simple que encapsula el archivo seleccionado por el usuario.
class ArchivoSeleccionado {
  const ArchivoSeleccionado({required this.bytes, required this.nombre});
  final Uint8List bytes;
  final String nombre;
}

/// Servicio que envuelve el plugin [FilePicker] para desacoplar la lógica
/// de selección/guardado de archivos del ViewModel.
class FilePickerService {
  /// Abre el diálogo de selección de imágenes (permite varias a la vez).
  /// Retorna la lista vacía si el usuario cancela.
  Future<List<ArchivoSeleccionado>> seleccionarImagenes() async {
    final archivos = await FilePicker.pickFiles(type: FileType.image);
    final seleccion = <ArchivoSeleccionado>[];
    for (final f in archivos) {
      final bytes = await f.readAsBytes();
      if (bytes.isNotEmpty) {
        seleccion.add(ArchivoSeleccionado(bytes: bytes, nombre: f.name));
      }
    }
    return seleccion;
  }

  /// Abre el diálogo de selección de UNA imagen (flujo Remove BG).
  /// Retorna [null] si el usuario cancela o el archivo está vacío.
  Future<ArchivoSeleccionado?> seleccionarImagen() async {
    final lista = await FilePicker.pickFiles(type: FileType.image);
    if (lista.isEmpty) return null;

    final archivo = lista.first;
    final bytes = await archivo.readAsBytes();
    if (bytes.isEmpty) return null;

    return ArchivoSeleccionado(bytes: bytes, nombre: archivo.name);
  }

  /// Abre el diálogo de guardado.
  /// Retorna la ruta del archivo guardado, o [null] si el usuario cancela.
  Future<String?> guardarPng({
    required String titulo,
    required String nombreArchivo,
    required Uint8List bytes,
  }) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: titulo,
      fileName: nombreArchivo,
      bytes: bytes,
      mimeType: 'image/png',
    );
    return uri?.toFilePath();
  }

  /// Guarda cualquier archivo con su tipo MIME respectivo (ej. ZIP).
  Future<String?> guardarArchivo({
    required String titulo,
    required String nombreArchivo,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: titulo,
      fileName: nombreArchivo,
      bytes: bytes,
      mimeType: mimeType,
    );
    return uri?.toFilePath();
  }
}
