/// Modelo de Tipo de Servicio — serialización exclusiva PascalCase (backend .NET).
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

  /// Construye desde JSON con claves PascalCase del backend.
  factory TipoServicio.fromJson(Map<String, dynamic> json) => TipoServicio(
        id: (json['Id'] as num).toInt(),
        nombre: json['Nombre'] as String,
        descripcion: json['Descripcion'] as String?,
        subcategoriaId: (json['SubcategoriaId'] as num).toInt(),
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
