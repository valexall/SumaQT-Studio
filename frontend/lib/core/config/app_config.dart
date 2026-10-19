/// Configuración global de la aplicación.
/// Centraliza URLs de entorno y constantes de la API.
class AppConfig {
  AppConfig._();

  // ── Backend ─────────────────────────────────────────────────────
  static const String _backendBaseUrl = 'http://127.0.0.1:8000';

  // ── Endpoints ───────────────────────────────────────────────────
  static const String _removeBgPath = '/api/v1/imagenes/quitar-fondo';
  static const String _ordenesPath = '/api/v1/ordenes';

  // ── URLs completas ──────────────────────────────────────────────
  static String get removeBgUrl => '$_backendBaseUrl$_removeBgPath';
  static String get ordenesUrl => '$_backendBaseUrl$_ordenesPath';

  static String ordenDetalleUrl(String id) => '$ordenesUrl/$id';
  static String ordenArchivosUrl(String id) => '$ordenesUrl/$id/archivos';
  static String ordenCerrarUrl(String id) => '$ordenesUrl/$id/cerrar';
  static String ordenDescargarArchivoUrl(String ordenId, String archivoId) =>
      '$ordenesUrl/$ordenId/archivos/$archivoId/descargar';
  static String ordenDescargarZipUrl(String ordenId) =>
      '$ordenesUrl/$ordenId/descargar-zip';
  static String get ordenesMetricasUrl => '$ordenesUrl/metricas';
}
