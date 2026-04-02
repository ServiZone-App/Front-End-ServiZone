/// Modelo de Servicio de Proveedor — serialización exclusiva PascalCase (backend .NET).
class ServicioProveedor {
  final int id;
  final int tipoServicioId;
  final String? tipoServicioNombre;
  final int proveedorId;
  final String? proveedorNombre;
  final double precioBase;
  final bool estado;
  final String? descripcion;
  final int duracionEstimadaMin;
  final double ratingMedia;
  final bool estaActivo;
  final DateTime? fechaCreacion;

  const ServicioProveedor({
    required this.id,
    required this.tipoServicioId,
    this.tipoServicioNombre,
    required this.proveedorId,
    this.proveedorNombre,
    required this.precioBase,
    required this.estado,
    this.descripcion,
    this.duracionEstimadaMin = 60,
    this.ratingMedia = 0.0,
    this.estaActivo = true,
    this.fechaCreacion,
  });

  /// Construye desde JSON con claves PascalCase del backend.
  factory ServicioProveedor.fromJson(Map<String, dynamic> json) =>
      ServicioProveedor(
        id: (json['Id'] ?? json['id'] as num).toInt(),
        tipoServicioId: (json['TipoServicioId'] ?? json['tipoServicioId'] as num).toInt(),
        tipoServicioNombre: (json['TipoServicioNombre'] ?? json['tipoServicioNombre']) as String?,
        proveedorId: (json['ProveedorId'] ?? json['proveedorId'] as num).toInt(),
        proveedorNombre: (json['ProveedorNombre'] ?? json['proveedorNombre']) as String?,
        precioBase: (json['PrecioBase'] ?? json['precioBase'] as num).toDouble(),
        estado: (json['Estado'] ?? json['estado']) as bool,
        descripcion: (json['Descripcion'] ?? json['descripcion']) as String?,
        duracionEstimadaMin: (json['DuracionEstimadaMin'] ?? json['duracionEstimadaMin'] ?? 60) as int,
        ratingMedia: (json['RatingMedia'] ?? json['ratingMedia'] ?? 0.0) as double,
        estaActivo: (json['EstaActivo'] ?? json['estaActivo'] ?? true) as bool,
        fechaCreacion: (json['FechaCreacion'] ?? json['fechaCreacion']) != null
            ? DateTime.tryParse((json['FechaCreacion'] ?? json['fechaCreacion']) as String)
            : null,
      );

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
    int? proveedorId,
    String? proveedorNombre,
    double? precioBase,
    bool? estado,
    String? descripcion,
    int? duracionEstimadaMin,
    double? ratingMedia,
    bool? estaActivo,
    DateTime? fechaCreacion,
  }) =>
      ServicioProveedor(
        id: id ?? this.id,
        tipoServicioId: tipoServicioId ?? this.tipoServicioId,
        tipoServicioNombre: tipoServicioNombre ?? this.tipoServicioNombre,
        proveedorId: proveedorId ?? this.proveedorId,
        proveedorNombre: proveedorNombre ?? this.proveedorNombre,
        precioBase: precioBase ?? this.precioBase,
        estado: estado ?? this.estado,
        descripcion: descripcion ?? this.descripcion,
        duracionEstimadaMin: duracionEstimadaMin ?? this.duracionEstimadaMin,
        ratingMedia: ratingMedia ?? this.ratingMedia,
        estaActivo: estaActivo ?? this.estaActivo,
        fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      );

  @override
  String toString() =>
      'ServicioProveedor(id: $id, tipoServicioId: $tipoServicioId, precioBase: $precioBase, estado: $estado)';
}
