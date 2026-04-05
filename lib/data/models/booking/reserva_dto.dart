/// DTO que representa una reserva confirmada o en proceso.
class ReservaDto {
  final int id;
  final int solicitudId;
  final int servicioProveedorId;
  final String? nombreServicio;
  final String? categoria;
  final int clienteId;
  final String clienteNombre;
  final int proveedorId;
  final String? proveedorNombre;
  final double? precioAcordado;
  final String? direccionCliente;
  final DateTime? fechaHoraReserva;
  final String estado;
  final DateTime fechaCreacion;

  const ReservaDto({
    required this.id,
    required this.solicitudId,
    required this.servicioProveedorId,
    this.nombreServicio,
    this.categoria,
    required this.clienteId,
    required this.clienteNombre,
    required this.proveedorId,
    this.proveedorNombre,
    this.precioAcordado,
    this.direccionCliente,
    this.fechaHoraReserva,
    required this.estado,
    required this.fechaCreacion,
  });

  factory ReservaDto.fromJson(Map<String, dynamic> json) {
    return ReservaDto(
      id: _parseInt(json['id'] ?? json['Id'] ?? json['reservaId'] ?? json['ReservaId']) ?? 0,
      solicitudId: _parseInt(json['solicitudId'] ?? json['SolicitudId']) ?? 0,
      servicioProveedorId: _parseInt(json['servicioProveedorId'] ?? json['ServicioProveedorId']) ?? 0,
      nombreServicio: _str(json['nombreServicio'] ?? json['NombreServicio'] ?? json['servicio'] ?? json['Servicio']),
      categoria: _str(json['categoria'] ?? json['Categoria'] ?? json['tipoServicio'] ?? json['TipoServicio'] ?? json['categoryName'] ?? json['CategoryName']),
      clienteId: _parseInt(json['clienteId'] ?? json['ClienteId']) ?? 0,
      clienteNombre: _str(json['clienteNombre'] ?? json['ClienteNombre'] ?? json['nombreCliente'] ?? json['NombreCliente']) ?? '',
      proveedorId: _parseInt(json['proveedorId'] ?? json['ProveedorId']) ?? 0,
      proveedorNombre: _str(json['proveedorNombre'] ?? json['ProveedorNombre'] ?? json['nombreProveedor'] ?? json['NombreProveedor']),
      precioAcordado: _parseDouble(json['precioAcordado'] ?? json['PrecioAcordado'] ?? json['precio'] ?? json['Precio']),
      direccionCliente: _str(json['direccionCliente'] ?? json['DireccionCliente'] ?? json['direccion'] ?? json['Direccion']),
      fechaHoraReserva: _parseDate(json['fechaHoraReserva'] ?? json['FechaHoraReserva'] ?? json['fechaReserva'] ?? json['FechaReserva']),
      estado: _str(json['estado'] ?? json['Estado']) ?? 'pendiente',
      fechaCreacion: _parseDate(json['fechaCreacion'] ?? json['FechaCreacion'] ?? json['fecha'] ?? json['Fecha']) ?? DateTime.now(),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String? _str(dynamic v) => v?.toString().trim().isEmpty == true ? null : v?.toString();

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
