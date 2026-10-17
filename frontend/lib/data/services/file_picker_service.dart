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
  /// Abre el diálogo de selección de imágenes.
  /// Retorna [null] si el usuario cancela o el archivo está vacío.
  Future<ArchivoSeleccionado?> seleccionarImagen() async {
    final archivo = await FilePicker.pickFile(type: FileType.image);
    if (archivo == null) return null;

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
}
