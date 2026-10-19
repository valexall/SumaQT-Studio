import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/app_config.dart';

/// Servicio stateless que encapsula la comunicación HTTP del flujo
/// de órdenes de trabajo con el backend FastAPI.
class OrdenesService {
  OrdenesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ── Órdenes ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> crearOrden({
    required String nombreProyecto,
    required String clienteNombre,
    required String clienteEmail,
    required int totalImagenes,
  }) async {
    final respuesta = await _client.post(
      Uri.parse(AppConfig.ordenesUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre_proyecto': nombreProyecto,
        'cliente_nombre': clienteNombre,
        'cliente_email': clienteEmail,
        'total_imagenes': totalImagenes,
      }),
    );
    return _decodificarMapa(respuesta);
  }

  Future<List<Map<String, dynamic>>> listarOrdenes() async {
    final respuesta = await _client.get(Uri.parse(AppConfig.ordenesUrl));
    _verificarStatus(respuesta);
    final cuerpo = jsonDecode(respuesta.body);
    if (cuerpo is! List) {
      throw const OrdenesServiceException(mensaje: 'Respuesta inesperada.');
    }
    return cuerpo.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> obtenerDetalle(String ordenId) async {
    final respuesta = await _client.get(
      Uri.parse(AppConfig.ordenDetalleUrl(ordenId)),
    );
    return _decodificarMapa(respuesta);
  }

  Future<Map<String, dynamic>> cerrarOrden(String ordenId) async {
    final respuesta = await _client.post(
      Uri.parse(AppConfig.ordenCerrarUrl(ordenId)),
    );
    return _decodificarMapa(respuesta);
  }

  Future<Map<String, dynamic>> actualizarOrden(
    String ordenId, {
    String? nombreProyecto,
    String? clienteNombre,
    String? clienteEmail,
  }) async {
    final payload = <String, dynamic>{};
    if (nombreProyecto != null) payload['nombre_proyecto'] = nombreProyecto;
    if (clienteNombre != null) payload['cliente_nombre'] = clienteNombre;
    if (clienteEmail != null) payload['cliente_email'] = clienteEmail;

    final respuesta = await _client.patch(
      Uri.parse(AppConfig.ordenDetalleUrl(ordenId)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return _decodificarMapa(respuesta);
  }

  Future<void> eliminarOrden(String ordenId) async {
    final respuesta = await _client.delete(
      Uri.parse(AppConfig.ordenDetalleUrl(ordenId)),
    );
    _verificarStatus(respuesta);
  }

  Future<Map<String, dynamic>> obtenerMetricas() async {
    final respuesta = await _client.get(
      Uri.parse(AppConfig.ordenesMetricasUrl),
    );
    return _decodificarMapa(respuesta);
  }

  // ── Archivos ────────────────────────────────────────────────────

  /// Descarga el PNG procesado desde la URL pública de Supabase Storage.
  Future<Uint8List> descargarImagen(String url) async {
    final respuesta = await _client.get(Uri.parse(url));
    if (respuesta.statusCode != 200) {
      throw OrdenesServiceException(
        statusCode: respuesta.statusCode,
        mensaje: 'No se pudo descargar el resultado desde Storage.',
      );
    }
    return respuesta.bodyBytes;
  }

  /// Descarga directamente desde el backend si Storage público no está disponible.
  Future<Uint8List> descargarArchivoBackend(String ordenId, String archivoId) async {
    final respuesta = await _client.get(
      Uri.parse(AppConfig.ordenDescargarArchivoUrl(ordenId, archivoId)),
    );
    if (respuesta.statusCode != 200) {
      throw OrdenesServiceException(
        statusCode: respuesta.statusCode,
        mensaje: 'No se pudo descargar el archivo desde el servidor.',
      );
    }
    return respuesta.bodyBytes;
  }

  /// Descarga todo el lote comprimido en ZIP desde el backend.
  Future<Uint8List> descargarLoteZip(String ordenId) async {
    final respuesta = await _client.get(
      Uri.parse(AppConfig.ordenDescargarZipUrl(ordenId)),
    );
    if (respuesta.statusCode != 200) {
      throw OrdenesServiceException(
        statusCode: respuesta.statusCode,
        mensaje: 'No se pudo generar el lote ZIP en el servidor.',
      );
    }
    return respuesta.bodyBytes;
  }

  /// Envía una imagen al backend; este la procesa con rembg, la sube a
  /// Supabase Storage y devuelve el registro con [url_resultado].
  Future<Map<String, dynamic>> procesarArchivo({
    required String ordenId,
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    final uri = Uri.parse(AppConfig.ordenArchivosUrl(ordenId));
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'archivo',
          bytes,
          filename: nombreArchivo,
          contentType: _inferirMediaType(nombreArchivo),
        ),
      );

    final streamed = await _client.send(request);
    final respuesta = await http.Response.fromStream(streamed);
    return _decodificarMapa(respuesta);
  }

  // ── Helpers ─────────────────────────────────────────────────────

  MediaType _inferirMediaType(String nombre) {
    final lower = nombre.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  Map<String, dynamic> _decodificarMapa(http.Response respuesta) {
    _verificarStatus(respuesta);
    final cuerpo = jsonDecode(respuesta.body);
    if (cuerpo is! Map<String, dynamic>) {
      throw const OrdenesServiceException(mensaje: 'Respuesta inesperada.');
    }
    return cuerpo;
  }

  void _verificarStatus(http.Response respuesta) {
    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) return;
    var mensaje = respuesta.body;
    try {
      final cuerpo = jsonDecode(respuesta.body);
      if (cuerpo is Map<String, dynamic> && cuerpo['detail'] != null) {
        mensaje = cuerpo['detail'].toString();
      }
    } catch (_) {
      // Se conserva el cuerpo crudo si no es JSON.
    }
    throw OrdenesServiceException(
      statusCode: respuesta.statusCode,
      mensaje: mensaje,
    );
  }
}

/// Excepción tipada para respuestas de error del backend de órdenes.
class OrdenesServiceException implements Exception {
  const OrdenesServiceException({this.statusCode, required this.mensaje});

  final int? statusCode;
  final String mensaje;

  @override
  String toString() {
    final codigo = statusCode == null ? '' : 'Error del servidor ($statusCode): ';
    return '$codigo$mensaje';
  }
}
