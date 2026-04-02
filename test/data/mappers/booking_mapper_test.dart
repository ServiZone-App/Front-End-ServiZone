import 'package:flutter_test/flutter_test.dart';
import 'package:servizone_app/data/mappers/booking_mapper.dart';
import 'package:servizone_app/data/models/booking_model.dart';

void main() {
  test('BookingMapper parses minimal json', () {
    final booking = BookingMapper.fromJson({
      'id': 'b1',
      'clienteId': 1,
      'proveedorId': 2,
      'clienteNombre': 'Ana',
      'proveedorNombre': 'Oscar',
      'tipoServicio': 'Plomería',
      'servicio': 'Fuga de agua',
      'fecha': '2026-04-01T10:00:00Z',
      'direccion': 'Calle 1',
      'precio': 45000,
      'estado': 'confirmada',
      'calificacion': 4.5,
      'resena': 'Ok',
    });

    expect(booking.id, 'b1');
    expect(booking.clientId, '1');
    expect(booking.providerId, '2');
    expect(booking.clientName, 'Ana');
    expect(booking.providerName, 'Oscar');
    expect(booking.serviceType, 'Plomería');
    expect(booking.serviceName, 'Fuga de agua');
    expect(booking.address, 'Calle 1');
    expect(booking.price, 45000);
    expect(booking.status, BookingStatus.confirmada);
    expect(booking.rating, 4.5);
    expect(booking.review, 'Ok');
  });

  test('BookingMapper defaults unknown status to pendiente', () {
    final booking = BookingMapper.fromJson({
      'id': 'b2',
      'clientId': 'C1',
      'providerId': 'P1',
      'clientName': 'A',
      'serviceType': 'S',
      'serviceName': 'X',
      'date': '2026-04-01T10:00:00Z',
      'address': 'D',
      'price': 1,
      'status': 'otro',
    });
    expect(booking.status, BookingStatus.pendiente);
  });
}

