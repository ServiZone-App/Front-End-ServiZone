import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/models/booking_model.dart';

abstract class BookingRepository {
  Future<ApiResult<List<BookingModel>>> getProviderPendingRequests({
    required int proveedorId,
    String query = '',
    DateTime? date,
    String? serviceName,
  });

  Future<ApiResult<List<BookingModel>>> getProviderBookings({
    required int proveedorId,
    bool includePending = false,
  });

  Future<ApiResult<List<BookingModel>>> getClientBookings({
    required int clienteId,
  });

  Future<ApiResult<void>> confirmBooking({
    required String bookingId,
    required int proveedorId,
    required DateTime date,
    required String address,
  });

  Future<ApiResult<void>> completeBooking({
    required String bookingId,
    required int proveedorId,
  });

  Future<ApiResult<void>> rejectBooking({
    required String bookingId,
    required int proveedorId,
    required String reason,
  });

  Future<ApiResult<void>> cancelBooking({
    required String bookingId,
    required int clienteId,
    required String reason,
  });

  Future<ApiResult<void>> rateBooking({
    required String bookingId,
    required int clienteId,
    required double rating,
    required String review,
  });
}
