import 'package:servizone_app/data/models/booking_model.dart';

class BookingMapper {
  static BookingStatus _parseStatus(dynamic v) {
    final s = (v ?? '').toString().toLowerCase().trim();
    if (s == 'pendiente') return BookingStatus.pendiente;
    if (s == 'confirmada') return BookingStatus.confirmada;
    if (s == 'completada') return BookingStatus.completada;
    if (s == 'cancelada') return BookingStatus.cancelada;
    if (s == 'rechazada') return BookingStatus.rechazada;
    return BookingStatus.pendiente;
  }

  static double? _tryDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    final parsed = DateTime.tryParse(v.toString());
    return parsed ?? DateTime.now();
  }

  static BookingModel fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['Id'] ?? json['bookingId'] ?? json['BookingId']).toString();

    final clientId = (json['clientId'] ?? json['ClienteId'] ?? json['clienteId'] ?? json['ClientId']).toString();
    final providerId = (json['providerId'] ?? json['ProveedorId'] ?? json['proveedorId'] ?? json['ProviderId']).toString();

    final clientName = (json['clientName'] ?? json['ClienteNombre'] ?? json['clienteNombre'] ?? json['ClientName'] ?? '').toString();
    final providerName = (json['providerName'] ?? json['ProveedorNombre'] ?? json['proveedorNombre'] ?? json['ProviderName'])?.toString();

    final serviceType = (json['serviceType'] ?? json['TipoServicio'] ?? json['tipoServicio'] ?? json['ServiceType'] ?? '').toString();
    final serviceName = (json['serviceName'] ?? json['Servicio'] ?? json['servicio'] ?? json['ServiceName'] ?? '').toString();

    final date = _parseDate(json['date'] ?? json['Fecha'] ?? json['fecha'] ?? json['Date']);
    final address = (json['address'] ?? json['Direccion'] ?? json['direccion'] ?? json['Address'] ?? '').toString();

    final price = _tryDouble(json['price'] ?? json['Precio'] ?? json['precio'] ?? json['Price']) ?? 0.0;
    final status = _parseStatus(json['status'] ?? json['Estado'] ?? json['estado'] ?? json['Status']);

    final cancellationReason = (json['cancellationReason'] ?? json['MotivoCancelacion'] ?? json['motivoCancelacion'])?.toString();
    final rating = _tryDouble(json['rating'] ?? json['Calificacion'] ?? json['calificacion']);
    final review = (json['review'] ?? json['Resena'] ?? json['resena'])?.toString();

    return BookingModel(
      id: id,
      clientId: clientId,
      providerId: providerId,
      clientName: clientName,
      providerName: providerName,
      serviceType: serviceType,
      serviceName: serviceName,
      date: date,
      address: address,
      price: price,
      status: status,
      cancellationReason: cancellationReason,
      rating: rating,
      review: review,
    );
  }
}
