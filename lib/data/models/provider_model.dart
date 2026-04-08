class ProviderModel {
  final String id;
  String name;
  String email;
  String phone;
  String category;
  String address;
  double rating;
  int completedServices;
  bool isActive;
  String estado;
  bool isVerified;
  final DateTime joinDate;
  final int? anosExperiencia;

  ProviderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.category,
    required this.address,
    required this.rating,
    required this.completedServices,
    required this.isActive,
    this.estado = 'activo',
    required this.isVerified,
    DateTime? joinDate,
    this.anosExperiencia,
  }) : joinDate = joinDate ?? DateTime.now();

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    // usuarioId es el campo primario en el response del endpoint de lista
    final id = json['usuarioId']?.toString() ??
        json['UsuarioId']?.toString() ??
        json['id']?.toString() ??
        json['Id']?.toString() ??
        '0';

    final estadoRaw = json['estado'] ?? json['Estado'];
    String estado;
    if (estadoRaw != null) {
      final s = estadoRaw.toString().toLowerCase();
      if (s == 'bloqueado' || s == '2') {
        estado = 'bloqueado';
      } else if (s == 'inactivo' || s == '1') {
        estado = 'inactivo';
      } else {
        estado = 'activo';
      }
    } else {
      final active = json['esActivo'] ?? json['EsActivo'] ?? true;
      estado = (active == true) ? 'activo' : 'inactivo';
    }

    DateTime joinDate;
    try {
      final raw = json['fechaRegistro'] ?? json['FechaRegistro'];
      joinDate = raw != null ? DateTime.parse(raw.toString()) : DateTime.now();
    } catch (_) {
      joinDate = DateTime.now();
    }

    return ProviderModel(
      id: id,
      name: json['nombreCompleto'] ?? json['NombreCompleto'] ?? json['nombre'] ?? json['Nombre'] ?? 'Proveedor',
      email: json['correo'] ?? json['Correo'] ?? '',
      phone: json['telefono'] ?? json['Telefono'] ?? '',
      category: json['categoria'] ?? json['Categoria'] ?? 'Sin categoría',
      address: json['direccion'] ?? json['Direccion'] ?? '',
      rating: (json['ratingPromedio'] ?? json['RatingPromedio'] ?? json['calificacion'] ?? json['Calificacion'] ?? 0.0).toDouble(),
      completedServices: json['serviciosCompletados'] ?? json['ServiciosCompletados'] ?? 0,
      isActive: estado == 'activo',
      estado: estado,
      isVerified: json['esVerificado'] ?? json['EsVerificado'] ?? true,
      joinDate: joinDate,
      anosExperiencia: json['anosExperiencia'] ?? json['AnosExperiencia'] ?? json['años_experiencia'],
    );
  }
}


