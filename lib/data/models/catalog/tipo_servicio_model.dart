/// Modelo de Tipo de Servicio — soporta PascalCase y camelCase del backend.
class TipoServicio {
  final int id;
  final String nombre;
  final String? descripcion;
  final int subcategoriaId;

  const TipoServicio({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.subcategoriaId,
  });

  factory TipoServicio.fromJson(Map<String, dynamic> json) => TipoServicio(
        id: ((json['Id'] ?? json['id']) as num).toInt(),
        nombre: (json['Nombre'] ?? json['nombre']) as String,
        descripcion: (json['Descripcion'] ?? json['descripcion']) as String?,
        subcategoriaId: ((json['SubcategoriaId'] ?? json['subcategoriaId']) as num).toInt(),
      );

  /// Serializa para POST/PUT — el backend acepta PascalCase.
  Map<String, dynamic> toJson() => {
        'Nombre': nombre,
        if (descripcion != null) 'Descripcion': descripcion,
        'SubcategoriaId': subcategoriaId,
      };

  @override
  String toString() => 'TipoServicio(id: $id, nombre: $nombre, subcategoriaId: $subcategoriaId)';
}
