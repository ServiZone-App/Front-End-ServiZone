import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/models/booking_model.dart';
import 'package:servizone_app/domain/repositories/booking_repository.dart';
import 'package:servizone_app/presentation/viewmodels/base_view_model.dart';

class BookingViewModel extends BaseViewModel {
  final BookingRepository _repo;

  BookingViewModel(this._repo);

  List<BookingModel> bookings = const [];

  Future<ApiResult<List<BookingModel>>> loadProviderPending(
    int proveedorId, {
    String query = '',
    DateTime? date,
    String? serviceName,
  }) async {
    setBusy(true);
    clearError();
    final res = await _repo.getProviderPendingRequests(
      proveedorId: proveedorId,
      query: query,
      date: date,
      serviceName: serviceName,
    );
    if (res.success && res.data != null) {
      bookings = res.data!;
    } else {
      setError(res.message);
    }
    setBusy(false);
    return res;
  }

  Future<ApiResult<List<BookingModel>>> loadProviderBookings(int proveedorId) async {
    setBusy(true);
    clearError();
    final res = await _repo.getProviderBookings(proveedorId: proveedorId);
    if (res.success && res.data != null) {
      bookings = res.data!;
    } else {
      setError(res.message);
    }
    setBusy(false);
    return res;
  }

  Future<ApiResult<List<BookingModel>>> loadClientBookings(int clienteId) async {
    setBusy(true);
    clearError();
    final res = await _repo.getClientBookings(clienteId: clienteId);
    if (res.success && res.data != null) {
      bookings = res.data!;
    } else {
      setError(res.message);
    }
    setBusy(false);
    return res;
  }

  Future<ApiResult<void>> confirm(String bookingId, int proveedorId, DateTime date, String address) async {
    setBusy(true);
    clearError();
    final res = await _repo.confirmBooking(bookingId: bookingId, proveedorId: proveedorId, date: date, address: address);
    if (!res.success) setError(res.message);
    setBusy(false);
    return res;
  }

  Future<ApiResult<void>> complete(String bookingId, int proveedorId) async {
    setBusy(true);
    clearError();
    final res = await _repo.completeBooking(bookingId: bookingId, proveedorId: proveedorId);
    if (!res.success) setError(res.message);
    setBusy(false);
    return res;
  }

  Future<ApiResult<void>> reject(String bookingId, int proveedorId, String reason) async {
    setBusy(true);
    clearError();
    final res = await _repo.rejectBooking(bookingId: bookingId, proveedorId: proveedorId, reason: reason);
    if (!res.success) setError(res.message);
    setBusy(false);
    return res;
  }

  Future<ApiResult<void>> cancel(String bookingId, int clienteId, String reason) async {
    setBusy(true);
    clearError();
    final res = await _repo.cancelBooking(bookingId: bookingId, clienteId: clienteId, reason: reason);
    if (!res.success) setError(res.message);
    setBusy(false);
    return res;
  }

  Future<ApiResult<void>> rate(String bookingId, int clienteId, double rating, String review) async {
    setBusy(true);
    clearError();
    final res = await _repo.rateBooking(bookingId: bookingId, clienteId: clienteId, rating: rating, review: review);
    if (!res.success) setError(res.message);
    setBusy(false);
    return res;
  }
}
