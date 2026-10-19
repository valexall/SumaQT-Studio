import 'dart:typed_data';

import '../../domain/models/orden.dart';
import '../services/ordenes_service.dart';

/// Repositorio que orquesta [OrdenesService] y expone modelos de dominio.
/// Única fuente de verdad del flujo de órdenes de trabajo.
class OrdenesRepository {
  OrdenesRepository({required OrdenesService service}) : _service = service;

  final OrdenesService _service;

  Future<Orden> crearOrden({
    required String nombreProyecto,
    required String clienteNombre,
    required String clienteEmail,
    required int totalImagenes,
  }) async {
    final json = await _service.crearOrden(
      nombreProyecto: nombreProyecto,
      clienteNombre: clienteNombre,
      clienteEmail: clienteEmail,
      totalImagenes: totalImagenes,
    );
    return Orden.fromJson(json);
  }

  Future<List<Orden>> listarOrdenes() async {
    final lista = await _service.listarOrdenes();
    return lista.map(Orden.fromJson).toList();
  }

  Future<Orden> obtenerDetalle(String ordenId) async {
    final json = await _service.obtenerDetalle(ordenId);
    return Orden.fromJson(json);
  }

  /// Sube la imagen, la procesa con rembg y registra el resultado en
  /// Supabase Storage. Propaga [OrdenesServiceException] ante errores.
  Future<ArchivoOrden> procesarArchivo({
    required String ordenId,
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    final json = await _service.procesarArchivo(
      ordenId: ordenId,
      bytes: bytes,
      nombreArchivo: nombreArchivo,
    );
    return ArchivoOrden.fromJson(json);
  }

  Future<Orden> cerrarOrden(String ordenId) async {
    final json = await _service.cerrarOrden(ordenId);
    return Orden.fromJson(json);
  }

  Future<Orden> actualizarOrden(
    String ordenId, {
    String? nombreProyecto,
    String? clienteNombre,
    String? clienteEmail,
  }) async {
    final json = await _service.actualizarOrden(
      ordenId,
      nombreProyecto: nombreProyecto,
      clienteNombre: clienteNombre,
      clienteEmail: clienteEmail,
    );
    return Orden.fromJson(json);
  }

  Future<void> eliminarOrden(String ordenId) async {
    await _service.eliminarOrden(ordenId);
  }

  Future<MetricasOrdenes> obtenerMetricas() async {
    final json = await _service.obtenerMetricas();
    return MetricasOrdenes.fromJson(json);
  }

  /// Descarga el PNG procesado (Supabase Storage) como bytes.
  Future<Uint8List> descargarImagen(String url) =>
      _service.descargarImagen(url);

  /// Descarga directamente desde el backend por ID de archivo.
  Future<Uint8List> descargarArchivoBackend(String ordenId, String archivoId) =>
      _service.descargarArchivoBackend(ordenId, archivoId);

  /// Descarga todo el lote comprimido en ZIP.
  Future<Uint8List> descargarLoteZip(String ordenId) =>
      _service.descargarLoteZip(ordenId);
}
