/// Modelo de Servicio de Proveedor — serialización exclusiva PascalCase (backend .NET).
class ServicioProveedor {
  final int id;
  final int tipoServicioId;
  final String? tipoServicioNombre;
  final String? tipoServicioDescripcion;
  final int proveedorId;
  final String? proveedorNombre;
  final double precioBase;
  final bool estado;
  final String? descripcion;
  final int duracionEstimadaMin;
  final double ratingMedia;
  final double? ratingPromedio;
  final bool estaActivo;
  final DateTime? fechaCreacion;

  const ServicioProveedor({
    required this.id,
    required this.tipoServicioId,
    this.tipoServicioNombre,
    this.tipoServicioDescripcion,
    required this.proveedorId,
    this.proveedorNombre,
    required this.precioBase,
    required this.estado,
    this.descripcion,
    this.duracionEstimadaMin = 60,
    this.ratingMedia = 0.0,
    this.ratingPromedio,
    this.estaActivo = true,
    this.fechaCreacion,
  });

  factory ServicioProveedor.fromJson(Map<String, dynamic> json) {
    final rawFecha = json['FechaCreacion'] ?? json['fechaCreacion'];
    return ServicioProveedor(
      id: ((json['Id'] ?? json['id']) as num).toInt(),
      tipoServicioId: ((json['TipoServicioId'] ?? json['tipoServicioId']) as num).toInt(),
      tipoServicioNombre: (json['TipoServicioNombre'] ?? json['tipoServicioNombre']) as String?,
      tipoServicioDescripcion: (json['TipoServicioDescripcion'] ?? json['tipoServicioDescripcion']) as String?,
      proveedorId: ((json['ProveedorId'] ?? json['proveedorId']) as num).toInt(),
      proveedorNombre: (json['ProveedorNombre'] ?? json['proveedorNombre']) as String?,
      precioBase: ((json['PrecioBase'] ?? json['precioBase']) as num).toDouble(),
      estado: _parseBool(json['Estado'] ?? json['estado'], fallback: true),
      descripcion: (json['Descripcion'] ?? json['descripcion']) as String?,
      duracionEstimadaMin: ((json['DuracionEstimadaMin'] ?? json['duracionEstimadaMin'] ?? 60) as num).toInt(),
      ratingMedia: ((json['RatingMedia'] ?? json['ratingMedia'] ?? 0.0) as num).toDouble(),
      ratingPromedio: (json['RatingPromedio'] ?? json['ratingPromedio']) != null
          ? ((json['RatingPromedio'] ?? json['ratingPromedio']) as num).toDouble()
          : null,
      estaActivo: _parseBool(json['EstaActivo'] ?? json['estaActivo'], fallback: true),
      fechaCreacion: rawFecha != null ? DateTime.tryParse(rawFecha.toString()) : null,
    );
  }

  static bool _parseBool(dynamic value, {required bool fallback}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    final s = value.toString().toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'activo') return true;
    if (s == 'false' || s == '0' || s == 'inactivo') return false;
    return fallback;
  }

  /// Serializa para POST/PUT — el backend acepta PascalCase.
  Map<String, dynamic> toJson() => {
        'TipoServicioId': tipoServicioId,
        'ProveedorId': proveedorId,
        'PrecioBase': precioBase,
        'Estado': estado,
        'Descripcion': descripcion,
        'DuracionEstimadaMin': duracionEstimadaMin,
        'EstaActivo': estaActivo,
      };

  /// Nombre seguro para la UI: nunca null, nunca lanza excepción.
  String get nombreMostrado {
    final n = tipoServicioNombre?.trim();
    return (n != null && n.isNotEmpty) ? n : 'Servicio sin nombre';
  }

  /// Copia con campos modificados.
  ServicioProveedor copyWith({
    int? id,
    int? tipoServicioId,
    String? tipoServicioNombre,
    String? tipoServicioDescripcion,
    int? proveedorId,
    String? proveedorNombre,
    double? precioBase,
    bool? estado,
    String? descripcion,
    int? duracionEstimadaMin,
    double? ratingMedia,
    double? ratingPromedio,
    bool? estaActivo,
    DateTime? fechaCreacion,
  }) =>
      ServicioProveedor(
        id: id ?? this.id,
        tipoServicioId: tipoServicioId ?? this.tipoServicioId,
        tipoServicioNombre: tipoServicioNombre ?? this.tipoServicioNombre,
        tipoServicioDescripcion: tipoServicioDescripcion ?? this.tipoServicioDescripcion,
        proveedorId: proveedorId ?? this.proveedorId,
        proveedorNombre: proveedorNombre ?? this.proveedorNombre,
        precioBase: precioBase ?? this.precioBase,
        estado: estado ?? this.estado,
        descripcion: descripcion ?? this.descripcion,
        duracionEstimadaMin: duracionEstimadaMin ?? this.duracionEstimadaMin,
        ratingMedia: ratingMedia ?? this.ratingMedia,
        ratingPromedio: ratingPromedio ?? this.ratingPromedio,
        estaActivo: estaActivo ?? this.estaActivo,
        fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      );

  @override
  String toString() =>
      'ServicioProveedor(id: $id, tipoServicioId: $tipoServicioId, precioBase: $precioBase, estado: $estado)';
}
