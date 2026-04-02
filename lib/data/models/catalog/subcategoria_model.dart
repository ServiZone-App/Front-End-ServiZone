/// Modelo de Subcategoría — serialización exclusiva PascalCase (backend .NET).
class Subcategoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final int categoriaId;

  const Subcategoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.categoriaId,
  });

  /// Construye desde JSON con claves PascalCase del backend.
  factory Subcategoria.fromJson(Map<String, dynamic> json) => Subcategoria(
        id: (json['Id'] as num).toInt(),
        nombre: json['Nombre'] as String,
        descripcion: json['Descripcion'] as String?,
        categoriaId: (json['CategoriaId'] as num).toInt(),
      );

  /// Serializa para POST/PUT — el backend acepta PascalCase.
  Map<String, dynamic> toJson() => {
        'Nombre': nombre,
        if (descripcion != null) 'Descripcion': descripcion,
        'CategoriaId': categoriaId,
      };

  @override
  String toString() =>
      'Subcategoria(id: $id, nombre: $nombre, categoriaId: $categoriaId)';
}
