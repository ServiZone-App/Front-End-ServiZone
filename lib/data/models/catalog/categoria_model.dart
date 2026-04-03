/// Modelo de Categoría — soporta PascalCase y camelCase del backend.
class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;

  const Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: ((json['Id'] ?? json['id']) as num).toInt(),
        nombre: (json['Nombre'] ?? json['nombre']) as String,
        descripcion: (json['Descripcion'] ?? json['descripcion']) as String?,
      );

  /// Serializa para POST/PUT — el backend acepta PascalCase.
  Map<String, dynamic> toJson() => {
        'Nombre': nombre,
        if (descripcion != null) 'Descripcion': descripcion,
      };

  @override
  String toString() => 'Categoria(id: $id, nombre: $nombre)';
}
