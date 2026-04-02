/// Modelo de Solicitud de Proveedor — serialización exclusiva camelCase (Auth API).
class SolicitudDto {
  final int id;
  final String usuarioNombre;
  final String usuarioCorreo;
  final String usuarioTelefono;
  final String descripcionPerfil;
  final int anosExperiencia;
  final List<String> documentos;
  final DateTime fechaSolicitud;
  final String estado;

  const SolicitudDto({
    required this.id,
    required this.usuarioNombre,
    required this.usuarioCorreo,
    required this.usuarioTelefono,
    required this.descripcionPerfil,
    required this.anosExperiencia,
    required this.documentos,
    required this.fechaSolicitud,
    required this.estado,
  });

  /// Construye desde JSON con claves camelCase del backend Auth.
  factory SolicitudDto.fromJson(Map<String, dynamic> json) {
    var docs = json['documentos'] ?? json['Documentos'];
    List<String> docList = [];
    if (docs is List) {
      docList = docs.map((e) => e.toString()).toList();
    }

    return SolicitudDto(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      usuarioNombre: (json['nombreCliente'] ?? json['NombreCliente'] ?? json['usuarioNombre'] ?? json['UsuarioNombre'] ?? 'Usuario') as String,
      usuarioCorreo: (json['correo'] ?? json['Correo'] ?? json['usuarioCorreo'] ?? json['UsuarioCorreo'] ?? '') as String,
      usuarioTelefono: (json['celular'] ?? json['Celular'] ?? json['telefono'] ?? json['Telefono'] ?? json['usuarioTelefono'] ?? json['UsuarioTelefono'] ?? 'No proporcionado') as String,
      descripcionPerfil: (json['descripcionPerfil'] ?? json['DescripcionPerfil'] ?? '') as String,
      anosExperiencia: (json['anosExperiencia'] ?? json['AnosExperiencia'] ?? 0) as int,
      documentos: docList,
      fechaSolicitud: json['fechaSolicitud'] != null 
          ? DateTime.parse(json['fechaSolicitud'] as String) 
          : (json['FechaSolicitud'] != null 
              ? DateTime.parse(json['FechaSolicitud'] as String) 
              : DateTime.now()),
      estado: (json['estado'] ?? json['Estado'] ?? 'Pendiente') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuarioNombre': usuarioNombre,
    'usuarioCorreo': usuarioCorreo,
    'usuarioTelefono': usuarioTelefono,
    'descripcionPerfil': descripcionPerfil,
    'anosExperiencia': anosExperiencia,
    'documentos': documentos,
    'fechaSolicitud': fechaSolicitud.toIso8601String(),
    'estado': estado,
  };
}
