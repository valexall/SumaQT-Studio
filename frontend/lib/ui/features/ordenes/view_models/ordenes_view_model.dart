import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/ordenes_repository.dart';
import '../../../../data/services/file_picker_service.dart';
import '../../../../data/services/ordenes_service.dart';
import '../../../../domain/models/orden.dart';

/// Estado local de un archivo mientras viaja al backend.
enum EstadoSubida { enEspera, procesando, completado, fallido }

/// Archivo seleccionado por el usuario en el wizard.
/// Conserva los bytes originales y los procesados para permitir previsualización
/// y descarga inmediata en lote sin depender de la red.
class ArchivoEnProceso {
  ArchivoEnProceso({
    required this.bytes,
    required this.nombre,
    this.archivoId,
    this.ordenId,
    this.estado = EstadoSubida.enEspera,
    this.bytesResultado,
    this.urlOriginal,
    this.urlResultado,
    this.mensajeError,
  });

  final Uint8List bytes;
  final String nombre;
  String? archivoId;
  final String? ordenId;
  EstadoSubida estado;
  Uint8List? bytesResultado;
  String? urlOriginal;
  String? urlResultado;
  String? mensajeError;

  bool get tieneOriginal => bytes.isNotEmpty || (urlOriginal != null && urlOriginal!.isNotEmpty);
  bool get tieneResultado =>
      (bytesResultado != null && bytesResultado!.isNotEmpty) ||
      (urlResultado != null && urlResultado!.isNotEmpty);
}

/// ViewModel del flujo "Orden de trabajo".
///
/// Expone estado inmutable (sólo getters) a la Vista; la Vista nunca
/// llama a [notifyListeners] directamente.
class OrdenesViewModel extends ChangeNotifier {
  OrdenesViewModel({
    required OrdenesRepository repository,
    required FilePickerService filePickerService,
  })  : _repository = repository,
        _filePickerService = filePickerService;

  final OrdenesRepository _repository;
  final FilePickerService _filePickerService;

  // ── Estado expuesto (sólo lectura) ──────────────────────────────

  List<Orden> _ordenes = const [];
  List<Orden> get ordenes => _ordenes;

  Orden? _ordenSeleccionada;
  Orden? get ordenSeleccionada => _ordenSeleccionada;

  MetricasOrdenes? _metricas;
  MetricasOrdenes? get metricas => _metricas;

  bool _cargando = false;
  bool get cargando => _cargando;

  bool _enviando = false;
  bool get enviando => _enviando;

  bool _procesandoCola = false;

  /// Cantidad de archivos aún no procesados (en cola + en curso).
  int get pendientesEnCola =>
      _archivos.where((a) => a.estado == EstadoSubida.enEspera).length;

  /// True mientras la cola serial está procesando imágenes.
  bool get procesando => _procesandoCola;

  /// True si aún hay trabajo local en vuelo (cola o proceso en curso).
  bool get hayColaActiva =>
      _archivos.any((a) => a.estado == EstadoSubida.enEspera || a.estado == EstadoSubida.procesando);

  /// Archivos visibles para la orden seleccionada: los que trae el servidor
  /// más los procesos locales en vuelo de esa misma orden.
  List<ArchivoEnProceso> get archivosDeLaOrden {
    final orden = _ordenSeleccionada;
    if (orden == null) return const [];
    return _archivos.where((a) => a.ordenId == orden.id).toList();
  }

  bool _mostrandoFormulario = false;
  bool get mostrandoFormulario => _mostrandoFormulario;

  bool _vistaCuadricula = true;
  bool get vistaCuadricula => _vistaCuadricula;

  void alternarVista() {
    _vistaCuadricula = !_vistaCuadricula;
    notifyListeners();
  }

  final List<ArchivoEnProceso> _archivos = [];
  List<ArchivoEnProceso> get archivos => _archivos;

  String? _error;
  String? get error => _error;

  String? _aviso;
  String? get aviso => _aviso;

  // ── Comandos de lista ───────────────────────────────────────────

  Future<void> cargarOrdenes() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final ordenes = await _repository.listarOrdenes();
      _ordenes = ordenes;
      try {
        _metricas = await _repository.obtenerMetricas();
      } on OrdenesServiceException {
        _metricas = null;
      }
    } on OrdenesServiceException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = 'No se pudo conectar al backend: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void mostrarFormulario() {
    _mostrandoFormulario = true;
    _error = null;
    notifyListeners();
  }

  void ocultarFormulario() {
    _mostrandoFormulario = false;
    _error = null;
    notifyListeners();
  }

  /// Crea la orden (evento de negocio inicial) y abre su wizard.
  /// La cantidad de imágenes se deriva de [imagenes] (las seleccionadas).
  Future<void> crearOrden({
    required String nombreProyecto,
    required String clienteNombre,
    required String clienteEmail,
    required List<ArchivoSeleccionado> imagenes,
  }) async {
    if (imagenes.isEmpty) {
      _error = 'Selecciona al menos una imagen para crear la orden.';
      notifyListeners();
      return;
    }

    _enviando = true;
    _error = null;
    notifyListeners();

    try {
      final orden = await _repository.crearOrden(
        nombreProyecto: nombreProyecto,
        clienteNombre: clienteNombre,
        clienteEmail: clienteEmail,
        totalImagenes: imagenes.length,
      );
      _mostrandoFormulario = false;
      _ordenes = [orden, ..._ordenes];
      _aviso = 'Orden creada: ${orden.nombreProyecto}';
      await _abrirOrden(orden.id);

      // Encola las imágenes seleccionadas; se procesan solas en serie.
      _encolar(imagenes.map(
        (a) => ArchivoEnProceso(bytes: a.bytes, nombre: a.nombre, ordenId: orden.id),
      ));
    } on OrdenesServiceException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = 'No se pudo conectar al backend: $e';
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  // ── Comandos de detalle (wizard) ────────────────────────────────

  Future<void> seleccionarOrden(String ordenId) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _abrirOrden(ordenId);
    } on OrdenesServiceException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = 'No se pudo conectar al backend: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _abrirOrden(String ordenId) async {
    final orden = await _repository.obtenerDetalle(ordenId);
    _ordenSeleccionada = orden;

    // Procesos locales aún en cola o en curso (de cualquier orden): no
    // existen en el servidor hasta completarse, así que se conservan al
    // recargar (sobreviven a la navegación al dashboard y de vuelta).
    final enVuelo = _archivos
        .where(
          (a) => a.estado == EstadoSubida.enEspera || a.estado == EstadoSubida.procesando,
        )
        .toList();

    _archivos.clear();
    for (final archivo in orden.archivos) {
      if (archivo.estado == EstadoArchivo.procesado) {
        _archivos.add(
          ArchivoEnProceso(
            bytes: Uint8List(0),
            nombre: archivo.nombreOriginal,
            archivoId: archivo.id,
            ordenId: orden.id,
            estado: EstadoSubida.completado,
            urlOriginal: archivo.urlOriginal,
            urlResultado: archivo.urlResultado,
          ),
        );
      } else {
        // Archivo con estado 'error' en BD: se lista para poder reintentar.
        _archivos.add(
          ArchivoEnProceso(
            bytes: Uint8List(0),
            nombre: archivo.nombreOriginal,
            archivoId: archivo.id,
            ordenId: orden.id,
            estado: EstadoSubida.fallido,
            urlOriginal: archivo.urlOriginal,
            mensajeError: 'Error registrado en el servidor.',
          ),
        );
      }
    }
    _archivos.addAll(enVuelo);
  }

  void volverALista() {
    _ordenSeleccionada = null;
    // Conserva los procesos locales aún en vuelo (la cola sigue corriendo
    // en segundo plano); descarta los de estado terminal, que se recargan
    // desde el servidor al volver a abrir la orden.
    _archivos.removeWhere(
      (a) => a.estado == EstadoSubida.completado || a.estado == EstadoSubida.fallido,
    );
    _error = null;
    _aviso = null;
    notifyListeners();
    cargarOrdenes();
  }

  /// Permite corregir los datos de una orden (nombre de proyecto, cliente o correo).
  Future<void> editarOrden({
    required String ordenId,
    String? nombreProyecto,
    String? clienteNombre,
    String? clienteEmail,
  }) async {
    _enviando = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.actualizarOrden(
        ordenId,
        nombreProyecto: nombreProyecto,
        clienteNombre: clienteNombre,
        clienteEmail: clienteEmail,
      );
      if (_ordenSeleccionada?.id == ordenId) {
        _ordenSeleccionada = await _repository.obtenerDetalle(ordenId);
      }
      _aviso = 'Orden actualizada correctamente.';
      await cargarOrdenes();
    } on OrdenesServiceException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = 'No se pudo actualizar la orden: $e';
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  /// Elimina una orden (si fue creada por error).
  Future<void> eliminarOrden(String ordenId) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.eliminarOrden(ordenId);
      if (_ordenSeleccionada?.id == ordenId) {
        _ordenSeleccionada = null;
      }
      // Descarta también los procesos locales en vuelo de la orden eliminada.
      _archivos.removeWhere((a) => a.ordenId == ordenId);
      _aviso = 'Orden eliminada correctamente.';
      await cargarOrdenes();
    } on OrdenesServiceException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = 'No se pudo eliminar la orden: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Máximo número de imágenes por lote y límite de peso seguro (45 MB)
  /// para no saturar la cuota total de 50 MB de Supabase Storage.
  static const int maxImagenesPorLote = 20;
  static const int maxBytesPorLote = 45 * 1024 * 1024; // 45 MB

  /// Abre el selector de imágenes para el formulario (paso 1).
  /// No encola: las imágenes las consume el formulario y las pasa a
  /// [crearOrden] al enviar. Protege la cuota máxima de 50 MB de Supabase.
  Future<List<ArchivoSeleccionado>> seleccionarImagenesParaFormulario() async {
    final seleccion = await _filePickerService.seleccionarImagenes();
    if (seleccion.isEmpty) return seleccion;

    List<ArchivoSeleccionado> filtradas = seleccion;
    if (filtradas.length > maxImagenesPorLote) {
      _error = 'Límite de lote: se seleccionaron las primeras $maxImagenesPorLote imágenes (máx. permitido por cuota).';
      filtradas = filtradas.take(maxImagenesPorLote).toList();
    }

    final totalBytes = filtradas.fold<int>(0, (sum, f) => sum + f.bytes.length);
    if (totalBytes > maxBytesPorLote) {
      final mb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
      _error = 'El lote seleccionado pesa $mb MB y supera el límite de seguridad de 45 MB para Supabase Storage.';
      notifyListeners();
      return const [];
    }

    notifyListeners();
    return filtradas;
  }

  /// Paso 2: selecciona una o varias imágenes y las encola.
  /// Valida cantidad y peso acumulado para proteger la cuota de Supabase Storage.
  Future<void> agregarYProcesarImagenes() async {
    final orden = _ordenSeleccionada;
    if (orden == null) return;

    final seleccion = await _filePickerService.seleccionarImagenes();
    if (seleccion.isEmpty) return;

    List<ArchivoSeleccionado> filtradas = seleccion;
    if (filtradas.length > maxImagenesPorLote) {
      _error = 'Límite de lote: se admiten hasta $maxImagenesPorLote imágenes por selección.';
      filtradas = filtradas.take(maxImagenesPorLote).toList();
    }

    final totalBytes = filtradas.fold<int>(0, (sum, f) => sum + f.bytes.length);
    if (totalBytes > maxBytesPorLote) {
      final mb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
      _error = 'El lote pesa $mb MB y supera el límite de seguridad de 45 MB para Supabase Storage.';
      notifyListeners();
      return;
    }

    _error = null;
    _aviso = null;
    _encolar(
      filtradas.map(
        (a) => ArchivoEnProceso(
          bytes: a.bytes,
          nombre: a.nombre,
          ordenId: orden.id,
        ),
      ),
    );
  }

  /// Reintenta un archivo que falló (el backend registra un nuevo intento).
  /// Los archivos restaurados desde BD no conservan los bytes originales;
  /// en ese caso se pide volver a seleccionarlos.
  Future<void> reintentarArchivo(ArchivoEnProceso archivo) async {
    if (archivo.ordenId == null) return;
    if (archivo.bytes.isEmpty) {
      _error = 'Esta imagen falló en el servidor y no conserva los bytes '
          'originales; usa "Agregar imágenes" para subirla de nuevo.';
      notifyListeners();
      return;
    }
    archivo.estado = EstadoSubida.enEspera;
    archivo.mensajeError = null;
    _error = null;
    notifyListeners();
    _encolar([archivo]);
  }

  /// Cancela o remueve un archivo que aún esté en espera en la cola.
  void quitarDeCola(ArchivoEnProceso archivo) {
    if (archivo.estado == EstadoSubida.enEspera) {
      _archivos.remove(archivo);
      notifyListeners();
    }
  }

  /// Vacía todos los archivos que aún estén pendientes en la cola.
  void cancelarPendientesEnCola() {
    _archivos.removeWhere((a) => a.estado == EstadoSubida.enEspera);
    notifyListeners();
  }

  /// Agrega archivos a la cola y arranca el procesamiento serial si no
  /// hay uno en curso. Permite seguir agregando mientras procesa.
  void _encolar(Iterable<ArchivoEnProceso> nuevos) {
    _archivos.addAll(nuevos);
    notifyListeners();
    _drenarCola();
  }

  /// Procesa la cola una imagen a la vez en segundo plano.
  /// Usa el [ArchivoEnProceso.ordenId] guardado al encolar (sobrevive a
  /// navegación del usuario).
  Future<void> _drenarCola() async {
    if (_procesandoCola) return;
    _procesandoCola = true;
    notifyListeners();

    try {
      while (true) {
        ArchivoEnProceso? siguiente;
        for (final a in _archivos) {
          if (a.estado == EstadoSubida.enEspera && a.ordenId != null) {
            siguiente = a;
            break;
          }
        }
        if (siguiente == null) break;
        await _procesar(siguiente, siguiente.ordenId!);
      }
    } finally {
      _procesandoCola = false;
      notifyListeners();
    }
  }

  Future<void> _procesar(ArchivoEnProceso archivo, String ordenId) async {
    archivo.estado = EstadoSubida.procesando;
    notifyListeners();

    try {
      final resultado = await _repository.procesarArchivo(
        ordenId: ordenId,
        bytes: archivo.bytes,
        nombreArchivo: archivo.nombre,
      );
      archivo.estado = EstadoSubida.completado;
      archivo.archivoId = resultado.id;
      archivo.urlOriginal = resultado.urlOriginal;
      archivo.urlResultado = resultado.urlResultado;
      if (resultado.imagenBase64 != null && resultado.imagenBase64!.isNotEmpty) {
        archivo.bytesResultado = base64Decode(resultado.imagenBase64!);
      }

      // Refresca imagenes_procesadas / estado solo si sigue viendo esa orden.
      if (_ordenSeleccionada?.id == ordenId) {
        final orden = await _repository.obtenerDetalle(ordenId);
        _ordenSeleccionada = orden;
      }
    } on OrdenesServiceException catch (e) {
      archivo.estado = EstadoSubida.fallido;
      archivo.mensajeError = e.toString();
      _error = e.toString();
    } catch (e) {
      archivo.estado = EstadoSubida.fallido;
      archivo.mensajeError = 'No se pudo conectar al backend: $e';
      _error = 'No se pudo conectar al backend: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Paso 3: cierra el ciclo (estado entregada + métrica de tiempo).
  Future<void> cerrarOrden() async {
    final orden = _ordenSeleccionada;
    if (orden == null || _enviando) return;

    _enviando = true;
    _error = null;
    notifyListeners();

    try {
      final cerrada = await _repository.cerrarOrden(orden.id);
      _ordenSeleccionada = cerrada;
      _aviso = 'Orden entregada: ${cerrada.nombreProyecto}';
      _metricas = await _repository.obtenerMetricas();
    } on OrdenesServiceException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = 'No se pudo conectar al backend: $e';
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  // ── Descarga del resultado (entrega) ────────────────────────────

  /// Descarga el PNG procesado (usando los bytes en memoria o Storage/backend).
  /// Retorna la ruta guardada o [null] si el usuario cancela.
  Future<String?> descargarResultado(ArchivoEnProceso archivo) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      Uint8List? bytes = archivo.bytesResultado;

      // Si no los tiene en memoria, intentar descargarlos
      if (bytes == null || bytes.isEmpty) {
        if (archivo.urlResultado != null && archivo.urlResultado!.isNotEmpty) {
          try {
            bytes = await _repository.descargarImagen(archivo.urlResultado!);
          } catch (_) {
            // Fallback al backend directo si la URL pública falla
            if (archivo.ordenId != null && archivo.archivoId != null) {
              bytes = await _repository.descargarArchivoBackend(
                archivo.ordenId!,
                archivo.archivoId!,
              );
            }
          }
        } else if (archivo.ordenId != null && archivo.archivoId != null) {
          bytes = await _repository.descargarArchivoBackend(
            archivo.ordenId!,
            archivo.archivoId!,
          );
        }
      }

      if (bytes == null || bytes.isEmpty) {
        _error = 'No se pudo obtener la imagen procesada de "${archivo.nombre}".';
        return null;
      }

      // Guardar en caché del objeto para futuras descargas inmediatas
      archivo.bytesResultado = bytes;

      final base = archivo.nombre.replaceAll(RegExp(r'\.[^.]+$'), '');
      final ruta = await _filePickerService.guardarPng(
        titulo: 'Guardar imagen sin fondo',
        nombreArchivo: '${base}_sin_fondo.png',
        bytes: bytes,
      );

      if (ruta != null) {
        _aviso = 'Guardado con éxito: ${base}_sin_fondo.png';
      }
      return ruta;
    } on OrdenesServiceException catch (e) {
      _error = e.toString();
      return null;
    } catch (e) {
      _error = 'No se pudo descargar el resultado: $e';
      return null;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Descarga todo el lote comprimido en un único archivo ZIP.
  Future<void> descargarLoteZip() async {
    final orden = _ordenSeleccionada;
    if (orden == null) return;

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final zipBytes = await _repository.descargarLoteZip(orden.id);
      final nombreZip = '${orden.nombreProyecto.replaceAll(RegExp(r'\s+'), '_')}_lote_sin_fondo.zip';
      final guardado = await _filePickerService.guardarArchivo(
        titulo: 'Guardar lote completo en ZIP',
        nombreArchivo: nombreZip,
        bytes: zipBytes,
        mimeType: 'application/zip',
      );
      if (guardado != null) {
        _aviso = 'Lote ZIP guardado con éxito.';
      }
    } on OrdenesServiceException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = 'No se pudo generar el archivo ZIP: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Descarga secuencialmente todos los resultados completados.
  Future<void> descargarTodoElLote() async {
    final completados = _archivos.where((a) => a.estado == EstadoSubida.completado).toList();
    if (completados.isEmpty) return;

    // Si tiene más de 2 imágenes, ofrecer descarga en ZIP por comodidad y rapidez
    if (completados.length > 1) {
      await descargarLoteZip();
      return;
    }

    int guardados = 0;
    for (final arch in completados) {
      final guardado = await descargarResultado(arch);
      if (guardado != null) {
        guardados++;
      }
    }
    if (guardados > 0) {
      _aviso = 'Se guardaron $guardados imágenes descargadas.';
      notifyListeners();
    }
  }

  // ── Limpieza de banners ─────────────────────────────────────────

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  void limpiarAviso() {
    _aviso = null;
    notifyListeners();
  }
}
