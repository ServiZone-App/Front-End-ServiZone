/// DTO que representa una solicitud de servicio entre cliente y proveedor.
/// Distinto de [SolicitudDto] en `data/models/auth/`, que es para postulaciones
/// de proveedores (flujo admin).
class SolicitudServicioDto {
  final int id;
  final int servicioProveedorId;
  final String? nombreServicio;
  final int clienteId;
  final String clienteNombre;
  final int proveedorId;
  final String? proveedorNombre;
  final String estado;
  final DateTime fechaCreacion;

  const SolicitudServicioDto({
    required this.id,
    required this.servicioProveedorId,
    this.nombreServicio,
    required this.clienteId,
    required this.clienteNombre,
    required this.proveedorId,
    this.proveedorNombre,
    required this.estado,
    required this.fechaCreacion,
  });

  factory SolicitudServicioDto.fromJson(Map<String, dynamic> json) {
    return SolicitudServicioDto(
      id: _parseInt(json['id'] ?? json['Id'] ?? json['solicitudId'] ?? json['SolicitudId']) ?? 0,
      servicioProveedorId: _parseInt(json['servicioProveedorId'] ?? json['ServicioProveedorId']) ?? 0,
      nombreServicio: _str(json['nombreServicio'] ?? json['NombreServicio'] ?? json['servicio'] ?? json['Servicio']),
      clienteId: _parseInt(json['clienteId'] ?? json['ClienteId']) ?? 0,
      clienteNombre: _str(json['clienteNombre'] ?? json['ClienteNombre'] ?? json['nombreCliente'] ?? json['NombreCliente']) ?? '',
      proveedorId: _parseInt(json['proveedorId'] ?? json['ProveedorId']) ?? 0,
      proveedorNombre: _str(json['proveedorNombre'] ?? json['ProveedorNombre'] ?? json['nombreProveedor'] ?? json['NombreProveedor']),
      estado: _str(json['estado'] ?? json['Estado']) ?? 'pendiente',
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
