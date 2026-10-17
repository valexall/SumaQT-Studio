/// Configuración global de la aplicación.
/// Centraliza URLs de entorno y constantes de la API.
class AppConfig {
  AppConfig._();

  // ── Backend ─────────────────────────────────────────────────────
  static const String _backendBaseUrl = 'http://127.0.0.1:8000';

  // ── Endpoints ───────────────────────────────────────────────────
  static const String _removeBgPath = '/api/v1/imagenes/quitar-fondo';

  // ── URLs completas ──────────────────────────────────────────────
  static String get removeBgUrl => '$_backendBaseUrl$_removeBgPath';
}
