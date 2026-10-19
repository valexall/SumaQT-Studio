/// Estados posibles de una orden de trabajo.
enum EstadoOrden { pendiente, procesando, entregada }

/// Estados posibles de un archivo dentro de una orden.
enum EstadoArchivo { procesado, error }

/// Modelo de dominio que representa una orden de trabajo (solicitud de
/// servicio del cliente): el evento de negocio inicial del flujo E2E.
class Orden {
  const Orden({
    required this.id,
    required this.nombreProyecto,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.totalImagenes,
    required this.imagenesProcesadas,
    required this.estado,
    required this.createdAt,
    this.cerradaEn,
    this.archivos = const [],
  });

  final String id;
  final String nombreProyecto;
  final String clienteNombre;
  final String clienteEmail;
  final int totalImagenes;
  final int imagenesProcesadas;
  final EstadoOrden estado;
  final DateTime createdAt;
  final DateTime? cerradaEn;
  final List<ArchivoOrden> archivos;

  bool get estaEntregada => estado == EstadoOrden.entregada;

  /// Progreso de imágenes procesadas respecto a las solicitadas (0.0 - 1.0).
  double get progreso =>
      totalImagenes == 0 ? 0 : imagenesProcesadas / totalImagenes;

  factory Orden.fromJson(Map<String, dynamic> json) {
    return Orden(
      id: json['id'] as String,
      nombreProyecto: json['nombre_proyecto'] as String,
      clienteNombre: json['cliente_nombre'] as String,
      clienteEmail: json['cliente_email'] as String,
      totalImagenes: json['total_imagenes'] as int,
      imagenesProcesadas: json['imagenes_procesadas'] as int? ?? 0,
      estado: estadoOrdenDesdeString(json['estado'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
      cerradaEn: DateTime.tryParse(json['cerrada_en'] as String? ?? ''),
      archivos: (json['archivos'] as List<dynamic>? ?? [])
          .map((a) => ArchivoOrden.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Un archivo (imagen) subido a una orden: viaja del cliente al backend,
/// se procesa con rembg y queda registrado con su URL en Supabase Storage.
class ArchivoOrden {
  const ArchivoOrden({
    required this.id,
    required this.ordenId,
    required this.nombreOriginal,
    required this.estado,
    this.urlOriginal,
    this.urlResultado,
    this.imagenBase64,
    this.storagePathOriginal,
    this.storagePathResultado,
    this.createdAt,
  });

  final String id;
  final String ordenId;
  final String nombreOriginal;
  final EstadoArchivo estado;
  final String? urlOriginal;
  final String? urlResultado;
  final String? imagenBase64;
  final String? storagePathOriginal;
  final String? storagePathResultado;
  final DateTime? createdAt;

  factory ArchivoOrden.fromJson(Map<String, dynamic> json) {
    return ArchivoOrden(
      id: json['id'] as String,
      ordenId: json['orden_id'] as String,
      nombreOriginal: json['nombre_original'] as String,
      estado: (json['estado'] as String?) == 'error'
          ? EstadoArchivo.error
          : EstadoArchivo.procesado,
      urlOriginal: json['url_original'] as String?,
      urlResultado: json['url_resultado'] as String?,
      imagenBase64: json['imagen_base64'] as String?,
      storagePathOriginal: json['storage_path_original'] as String?,
      storagePathResultado: json['storage_path_resultado'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

/// Métricas del flujo (resultado medible de la exposición).
class MetricasOrdenes {
  const MetricasOrdenes({
    required this.ordenesCerradas,
    required this.imagenesProcesadas,
    required this.segPromedioEntrega,
  });

  final int ordenesCerradas;
  final int imagenesProcesadas;
  final double segPromedioEntrega;

  factory MetricasOrdenes.fromJson(Map<String, dynamic> json) {
    return MetricasOrdenes(
      ordenesCerradas: (json['ordenes_cerradas'] as num?)?.toInt() ?? 0,
      imagenesProcesadas: (json['imagenes_procesadas'] as num?)?.toInt() ?? 0,
      segPromedioEntrega:
          (json['seg_promedio_entrega'] as num?)?.toDouble() ?? 0,
    );
  }
}

EstadoOrden estadoOrdenDesdeString(String valor) {
  switch (valor) {
    case 'procesando':
      return EstadoOrden.procesando;
    case 'entregada':
      return EstadoOrden.entregada;
    default:
      return EstadoOrden.pendiente;
  }
}
