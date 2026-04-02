/// Modelo de Categoría — serialización exclusiva PascalCase (backend .NET).
class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;

  const Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  /// Construye desde JSON con claves PascalCase del backend.
  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: (json['Id'] as num).toInt(),
        nombre: json['Nombre'] as String,
        descripcion: json['Descripcion'] as String?,
      );

  /// Serializa para POST/PUT — el backend acepta PascalCase.
  Map<String, dynamic> toJson() => {
        'Nombre': nombre,
        if (descripcion != null) 'Descripcion': descripcion,
      };

  @override
  String toString() => 'Categoria(id: $id, nombre: $nombre)';
}
