import 'package:flutter_test/flutter_test.dart';
import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/models/booking_model.dart';
import 'package:servizone_app/domain/repositories/booking_repository.dart';
import 'package:servizone_app/presentation/viewmodels/booking_view_model.dart';

class _FakeBookingRepo implements BookingRepository {
  List<BookingModel> items = const [];
  bool fail = false;

  @override
  Future<ApiResult<void>> cancelBooking({required String bookingId, required int clienteId, required String reason}) async {
    return fail ? ApiResult.failure(message: 'fail', statusCode: 400) : ApiResult.success(data: null, statusCode: 200);
  }

  @override
  Future<ApiResult<void>> confirmBooking({required String bookingId, required int proveedorId, required DateTime date, required String address}) async {
    return fail ? ApiResult.failure(message: 'fail', statusCode: 400) : ApiResult.success(data: null, statusCode: 200);
  }

  @override
  Future<ApiResult<void>> completeBooking({required String bookingId, required int proveedorId}) async {
    return fail ? ApiResult.failure(message: 'fail', statusCode: 400) : ApiResult.success(data: null, statusCode: 200);
  }

  @override
  Future<ApiResult<List<BookingModel>>> getClientBookings({required int clienteId}) async {
    return fail ? ApiResult.failure(message: 'fail', statusCode: 400) : ApiResult.success(data: items, statusCode: 200);
  }

  @override
  Future<ApiResult<List<BookingModel>>> getProviderBookings({required int proveedorId, bool includePending = false}) async {
    return fail ? ApiResult.failure(message: 'fail', statusCode: 400) : ApiResult.success(data: items, statusCode: 200);
  }

  @override
  Future<ApiResult<List<BookingModel>>> getProviderPendingRequests({required int proveedorId, String query = '', DateTime? date, String? serviceName}) async {
    return fail ? ApiResult.failure(message: 'fail', statusCode: 400) : ApiResult.success(data: items, statusCode: 200);
  }

  @override
  Future<ApiResult<void>> rejectBooking({required String bookingId, required int proveedorId, required String reason}) async {
    return fail ? ApiResult.failure(message: 'fail', statusCode: 400) : ApiResult.success(data: null, statusCode: 200);
  }

  @override
  Future<ApiResult<void>> rateBooking({required String bookingId, required int clienteId, required double rating, required String review}) async {
    return fail ? ApiResult.failure(message: 'fail', statusCode: 400) : ApiResult.success(data: null, statusCode: 200);
  }
}

void main() {
  test('BookingViewModel loads provider pending', () async {
    final repo = _FakeBookingRepo()
      ..items = [
        BookingModel(
          id: '1',
          clientId: 'C1',
          providerId: 'P1',
          clientName: 'Ana',
          serviceType: 'S',
          serviceName: 'X',
          date: DateTime.parse('2026-04-01T10:00:00Z'),
          address: 'D',
          price: 1,
          status: BookingStatus.pendiente,
        ),
      ];
    final vm = BookingViewModel(repo);
    final res = await vm.loadProviderPending(10);
    expect(res.success, true);
    expect(vm.bookings.length, 1);
    expect(vm.error, isNull);
  });

  test('BookingViewModel propagates error', () async {
    final repo = _FakeBookingRepo()..fail = true;
    final vm = BookingViewModel(repo);
    final res = await vm.loadClientBookings(1);
    expect(res.success, false);
    expect(vm.error, 'fail');
  });
}
