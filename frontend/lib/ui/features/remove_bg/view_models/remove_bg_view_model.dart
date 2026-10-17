import 'package:flutter/foundation.dart';

import '../../../../data/repositories/remove_bg_repository.dart';
import '../../../../data/services/file_picker_service.dart';
import '../../../../data/services/remove_bg_service.dart';

/// ViewModel para la funcionalidad remove-bg.
/// Extiende [ChangeNotifier] y expone estado inmutable (solo getters) a la Vista.
/// La Vista nunca llama a [notifyListeners] directamente.
class RemoveBgViewModel extends ChangeNotifier {
  RemoveBgViewModel({
    required RemoveBgRepository repository,
    required FilePickerService filePickerService,
  })  : _repository = repository,
        _filePickerService = filePickerService;

  final RemoveBgRepository _repository;
  final FilePickerService _filePickerService;

  // ── Estado expuesto (sólo lectura) ──────────────────────────────

  Uint8List? _imagenOriginal;
  Uint8List? get imagenOriginal => _imagenOriginal;

  Uint8List? _imagenResultado;
  Uint8List? get imagenResultado => _imagenResultado;

  String? _nombreArchivo;
  String? get nombreArchivo => _nombreArchivo;

  bool _procesando = false;
  bool get procesando => _procesando;

  String? _error;
  String? get error => _error;

  // ── Comandos (invocados desde la Vista) ─────────────────────────

  /// Abre el selector de archivos y procesa la imagen seleccionada.
  Future<void> seleccionarYProcesar() async {
    final archivo = await _filePickerService.seleccionarImagen();
    if (archivo == null) return;

    _imagenOriginal = archivo.bytes;
    _nombreArchivo = archivo.nombre;
    _imagenResultado = null;
    _error = null;
    notifyListeners();

    await _procesarImagen(archivo.bytes, archivo.nombre);
  }

  /// Guarda el resultado como PNG.
  /// Retorna la ruta guardada o [null] si el usuario cancela.
  Future<String?> descargar() async {
    if (_imagenResultado == null) return null;
    return _filePickerService.guardarPng(
      titulo: 'Guardar imagen sin fondo',
      nombreArchivo: 'sin_fondo.png',
      bytes: _imagenResultado!,
    );
  }

  /// Reinicia el estado completo para procesar una nueva imagen.
  void limpiar() {
    _imagenOriginal = null;
    _imagenResultado = null;
    _nombreArchivo = null;
    _error = null;
    _procesando = false;
    notifyListeners();
  }

  // ── Lógica privada ──────────────────────────────────────────────

  Future<void> _procesarImagen(Uint8List bytes, String nombre) async {
    _procesando = true;
    notifyListeners();

    try {
      final resultado = await _repository.quitarFondo(bytes, nombre);
      _imagenResultado = resultado.bytesResultado;
      _error = null;
    } on RemoveBgServiceException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = 'No se pudo conectar al backend: $e';
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }
}
