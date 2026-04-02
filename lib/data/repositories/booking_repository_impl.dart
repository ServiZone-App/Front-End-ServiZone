import 'dart:convert';
import 'package:servizone_app/core/network/api_client.dart';
import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/mappers/booking_mapper.dart';
import 'package:servizone_app/data/models/booking_model.dart';
import 'package:servizone_app/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final ApiClient _client;

  BookingRepositoryImpl(this._client);

  Future<ApiResult<List<BookingModel>>> _getList(String endpoint) async {
    try {
      final response = await _client.getRequest(endpoint);
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseMessage(response.body, sc), statusCode: sc);
      }
      final decoded = _decodeJson(response.body);
      final data = _extractList(decoded);
      final mapped = data.map((e) => BookingMapper.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      return ApiResult.success(data: mapped, statusCode: sc);
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  Future<ApiResult<void>> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _client.postRequest(endpoint, body);
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseMessage(response.body, sc), statusCode: sc);
      }
      return ApiResult.success(data: null, statusCode: sc);
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  List _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final data = decoded['Data'] ?? decoded['data'] ?? decoded['items'] ?? decoded['Items'];
      if (data is List) return data;
      if (data is Map) return [data];
    }
    return const [];
  }

  String _parseMessage(String body, int sc) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final msg = decoded['message'] ?? decoded['Message'] ?? decoded['error'] ?? decoded['title'];
        if (msg != null) return msg.toString();
      }
      if (decoded is String) return decoded;
    } catch (_) {}
    if (sc == 404) return 'Recurso no encontrado.';
    if (sc == 401) return 'Sesión expirada. Inicia sesión nuevamente.';
    if (sc == 403) return 'No tienes permisos para esta operación.';
    if (sc == 409) return 'Conflicto: operación no permitida.';
    if (sc >= 500) return 'Error interno del servidor.';
    return 'Error desconocido (código $sc).';
  }

  @override
  Future<ApiResult<List<BookingModel>>> getProviderPendingRequests({
    required int proveedorId,
    String query = '',
    DateTime? date,
    String? serviceName,
  }) {
    final qp = <String, String>{
      'proveedorId': proveedorId.toString(),
      'estado': 'pendiente',
      if (query.isNotEmpty) 'q': query,
      if (serviceName != null && serviceName.isNotEmpty) 'serviceName': serviceName,
      if (date != null) 'date': date.toIso8601String(),
    };
    final uri = Uri(path: '/reservas', queryParameters: qp);
    final endpoint = uri.toString();
    return _getList(endpoint);
  }

  @override
  Future<ApiResult<List<BookingModel>>> getProviderBookings({
    required int proveedorId,
    bool includePending = false,
  }) {
    final qp = <String, String>{
      'proveedorId': proveedorId.toString(),
      if (!includePending) 'exclude': 'pendiente',
    };
    final uri = Uri(path: '/reservas', queryParameters: qp);
    return _getList(uri.toString());
  }

  @override
  Future<ApiResult<List<BookingModel>>> getClientBookings({required int clienteId}) {
    final uri = Uri(path: '/reservas', queryParameters: {'clienteId': clienteId.toString()});
    return _getList(uri.toString());
  }

  @override
  Future<ApiResult<void>> confirmBooking({
    required String bookingId,
    required int proveedorId,
    required DateTime date,
    required String address,
  }) {
    return _post('/reservas/$bookingId/confirmar', {
      'proveedorId': proveedorId,
      'fecha': date.toIso8601String(),
      'direccion': address,
    });
  }

  @override
  Future<ApiResult<void>> completeBooking({
    required String bookingId,
    required int proveedorId,
  }) {
    return _post('/reservas/$bookingId/completar', {
      'proveedorId': proveedorId,
    });
  }

  @override
  Future<ApiResult<void>> rejectBooking({
    required String bookingId,
    required int proveedorId,
    required String reason,
  }) {
    return _post('/reservas/$bookingId/rechazar', {
      'proveedorId': proveedorId,
      'motivo': reason,
    });
  }

  @override
  Future<ApiResult<void>> cancelBooking({
    required String bookingId,
    required int clienteId,
    required String reason,
  }) {
    return _post('/reservas/$bookingId/cancelar', {
      'clienteId': clienteId,
      'motivo': reason,
    });
  }

  @override
  Future<ApiResult<void>> rateBooking({
    required String bookingId,
    required int clienteId,
    required double rating,
    required String review,
  }) {
    return _post('/reservas/$bookingId/calificar', {
      'clienteId': clienteId,
      'calificacion': rating,
      'resena': review,
    });
  }
}
