class User {
  final String id;
  String name;
  String email;
  String phone;
  String address;
  int age;
  bool isActive;
  bool isVerified;
  bool isPremium;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.age,
    required this.isActive,
    required this.isVerified,
    required this.isPremium,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '0',
      name: json['nombre'] ?? json['Nombre'] ?? 'Usuario',
      email: json['correo'] ?? json['Correo'] ?? '',
      phone: json['telefono'] ?? json['Telefono'] ?? '',
      address: json['direccion'] ?? json['Direccion'] ?? '',
      age: json['edad'] ?? json['Edad'] ?? 0,
      isActive: json['esActivo'] ?? json['EsActivo'] ?? true,
      isVerified: json['esVerificado'] ?? json['EsVerificado'] ?? false,
      isPremium: json['esPremium'] ?? json['EsPremium'] ?? false,
      createdAt: json['fechaCreacion'] != null 
          ? DateTime.parse(json['fechaCreacion']) 
          : (json['FechaCreacion'] != null 
              ? DateTime.parse(json['FechaCreacion']) 
              : DateTime.now()),
    );
  }
}


