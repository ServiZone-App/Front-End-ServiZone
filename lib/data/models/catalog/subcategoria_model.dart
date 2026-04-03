/// Modelo de Subcategoría — soporta PascalCase y camelCase del backend.
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

  factory Subcategoria.fromJson(Map<String, dynamic> json) => Subcategoria(
        id: ((json['Id'] ?? json['id']) as num).toInt(),
        nombre: (json['Nombre'] ?? json['nombre']) as String,
        descripcion: (json['Descripcion'] ?? json['descripcion']) as String?,
        categoriaId: ((json['CategoriaId'] ?? json['categoriaId']) as num).toInt(),
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
