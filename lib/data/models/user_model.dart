class User {
  final String id;
  String name;
  String email;
  String phone;
  String documento;
  String address;
  int age;
  bool isActive;
  String estado;
  bool isVerified;
  bool isPremium;
  List<String> roles;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.documento,
    this.address = '',
    this.age = 0,
    required this.isActive,
    this.estado = 'activo',
    this.isVerified = false,
    this.isPremium = false,
    this.roles = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => v == null ? '' : v.toString();

    final nombre = str(json['nombre'] ?? json['Nombre']).trim();
    final apellido = str(json['apellido'] ?? json['Apellido']).trim();
    final fullName = [nombre, apellido].where((s) => s.isNotEmpty).join(' ');

    List<String> roles = [];
    final rolesRaw = json['rolesDisponibles'] ?? json['RolesDisponibles'];
    if (rolesRaw is List) {
      roles = rolesRaw.map((e) => e.toString()).toList();
    }

    DateTime createdAt;
    try {
      final raw = json['fechaCreacion'] ?? json['FechaCreacion'];
      createdAt = raw != null ? DateTime.parse(raw.toString()) : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }

    // Determinar estado real: prioriza campo numérico 'estado' (0=activo,1=inactivo,2=bloqueado)
    // Si no existe, deduce de 'esActivo' bool.
    final estadoRaw = json['estado'] ?? json['Estado'];
    String estado;
    if (estadoRaw != null) {
      final estadoInt = estadoRaw is int ? estadoRaw : int.tryParse(estadoRaw.toString());
      if (estadoInt == 2) {
        estado = 'bloqueado';
      } else if (estadoInt == 1) {
        estado = 'inactivo';
      } else {
        estado = 'activo';
      }
    } else {
      final active = json['esActivo'] ?? json['EsActivo'] ?? true;
      estado = (active == true) ? 'activo' : 'inactivo';
    }

    return User(
      id: str(json['id'] ?? json['Id']).isEmpty ? '0' : str(json['id'] ?? json['Id']),
      name: fullName.isNotEmpty ? fullName : 'Usuario',
      email: str(json['correo'] ?? json['Correo']),
      phone: str(json['celular'] ?? json['Celular'] ?? json['telefono'] ?? json['Telefono']),
      documento: str(json['documento'] ?? json['Documento']),
      address: str(json['direccion'] ?? json['Direccion']),
      age: (json['edad'] ?? json['Edad'] ?? 0) is int ? (json['edad'] ?? json['Edad'] ?? 0) : 0,
      isActive: estado == 'activo',
      estado: estado,
      isVerified: json['esVerificado'] ?? json['EsVerificado'] ?? false,
      isPremium: json['esPremium'] ?? json['EsPremium'] ?? false,
      roles: roles,
      createdAt: createdAt,
    );
  }
}
