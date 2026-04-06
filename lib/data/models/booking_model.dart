
enum BookingStatus {
  pendiente,
  enRevision,
  enProceso,
  confirmada,
  completada,
  cancelada,
  rechazada,
}

class BookingModel {
  final String id;
  final int servicioProveedorId;
  final String clientId;
  final String providerId;
  final String clientName;
  final String? providerName;
  final String serviceType;
  final String serviceName;
  final DateTime date;
  final String address;
  final double price;
  final BookingStatus status;
  final String? cancellationReason;
  final double? rating;
  final String? review;

  BookingModel({
    required this.id,
    this.servicioProveedorId = 0,
    required this.clientId,
    required this.providerId,
    required this.clientName,
    required this.serviceType,
    required this.serviceName,
    required this.date,
    required this.address,
    required this.price,
    required this.status,
    this.providerName,
    this.cancellationReason,
    this.rating,
    this.review,
  });

  BookingModel copyWith({
    String? id,
    int? servicioProveedorId,
    String? clientId,
    String? providerId,
    String? clientName,
    String? providerName,
    String? serviceType,
    String? serviceName,
    DateTime? date,
    String? address,
    double? price,
    BookingStatus? status,
    String? cancellationReason,
    double? rating,
    String? review,
  }) {
    return BookingModel(
      id: id ?? this.id,
      servicioProveedorId: servicioProveedorId ?? this.servicioProveedorId,
      clientId: clientId ?? this.clientId,
      providerId: providerId ?? this.providerId,
      clientName: clientName ?? this.clientName,
      providerName: providerName ?? this.providerName,
      serviceType: serviceType ?? this.serviceType,
      serviceName: serviceName ?? this.serviceName,
      date: date ?? this.date,
      address: address ?? this.address,
      price: price ?? this.price,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }
}


