/// DTO que representa una reseña dejada por un cliente tras completar una reserva.
class ResenaDto {
  final int id;
  final int solicitudId;
  final int clienteId;
  final String? clienteNombre;
  final int proveedorId;
  final int servicioProveedorId;
  final int calificacion;
  final String? comentario;
  final DateTime fechaCreacion;

  const ResenaDto({
    required this.id,
    required this.solicitudId,
    required this.clienteId,
    this.clienteNombre,
    required this.proveedorId,
    required this.servicioProveedorId,
    required this.calificacion,
    this.comentario,
    required this.fechaCreacion,
  });

  factory ResenaDto.fromJson(Map<String, dynamic> json) {
    return ResenaDto(
      id: _parseInt(json['id'] ?? json['Id'] ?? json['resenaId'] ?? json['ResenaId']) ?? 0,
      solicitudId: _parseInt(json['solicitudId'] ?? json['SolicitudId']) ?? 0,
      clienteId: _parseInt(json['clienteId'] ?? json['ClienteId']) ?? 0,
      clienteNombre: _str(json['clienteNombre'] ?? json['ClienteNombre'] ?? json['nombreCliente'] ?? json['NombreCliente']),
      proveedorId: _parseInt(json['proveedorId'] ?? json['ProveedorId']) ?? 0,
      servicioProveedorId: _parseInt(json['servicioProveedorId'] ?? json['ServicioProveedorId']) ?? 0,
      calificacion: _parseInt(json['calificacion'] ?? json['Calificacion'] ?? json['rating'] ?? json['Rating']) ?? 0,
      comentario: _str(json['comentario'] ?? json['Comentario'] ?? json['comment'] ?? json['Comment']),
      fechaCreacion: _parseDate(json['fechaCreacion'] ?? json['FechaCreacion'] ?? json['fecha'] ?? json['Fecha']),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String? _str(dynamic v) => v?.toString().trim().isEmpty == true ? null : v?.toString();

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}
