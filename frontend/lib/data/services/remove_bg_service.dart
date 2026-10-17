import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/app_config.dart';

/// Servicio stateless que encapsula la comunicación HTTP con el backend.
/// Retorna bytes crudos o lanza [RemoveBgServiceException].
class RemoveBgService {
  RemoveBgService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Uint8List> procesarImagen(
    Uint8List bytes,
    String nombreArchivo,
  ) async {
    final uri = Uri.parse(AppConfig.removeBgUrl);

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'archivo',
          bytes,
          filename: nombreArchivo,
          contentType: _inferirMediaType(nombreArchivo),
        ),
      );

    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode == 200) {
      return streamedResponse.stream.toBytes();
    }

    final body = await streamedResponse.stream.bytesToString();
    throw RemoveBgServiceException(
      statusCode: streamedResponse.statusCode,
      mensaje: body,
    );
  }

  MediaType _inferirMediaType(String nombre) {
    final lower = nombre.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }
}

/// Excepción tipada para respuestas de error del backend.
class RemoveBgServiceException implements Exception {
  const RemoveBgServiceException({
    required this.statusCode,
    required this.mensaje,
  });

  final int statusCode;
  final String mensaje;

  @override
  String toString() => 'Error del servidor ($statusCode): $mensaje';
}
