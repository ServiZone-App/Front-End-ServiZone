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
  bool isVerified;
  final DateTime joinDate;

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
    required this.isVerified,
    DateTime? joinDate,
  }) : joinDate = joinDate ?? DateTime.now();

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '0',
      name: json['nombre'] ?? json['Nombre'] ?? 'Proveedor',
      email: json['correo'] ?? json['Correo'] ?? '',
      phone: json['telefono'] ?? json['Telefono'] ?? '',
      category: json['categoria'] ?? json['Categoria'] ?? 'Sin categoría',
      address: json['direccion'] ?? json['Direccion'] ?? '',
      rating: (json['calificacion'] ?? json['Calificacion'] ?? 0.0).toDouble(),
      completedServices: json['serviciosCompletados'] ?? json['ServiciosCompletados'] ?? 0,
      isActive: json['esActivo'] ?? json['EsActivo'] ?? true,
      isVerified: json['esVerificado'] ?? json['EsVerificado'] ?? true,
      joinDate: json['fechaRegistro'] != null 
          ? DateTime.parse(json['fechaRegistro']) 
          : (json['FechaRegistro'] != null 
              ? DateTime.parse(json['FechaRegistro']) 
              : DateTime.now()),
    );
  }
}


