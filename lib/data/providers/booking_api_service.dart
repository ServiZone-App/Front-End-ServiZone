import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:servizone_app/core/network/api_client.dart';
import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/models/booking/api_response_dto.dart';
import 'package:servizone_app/data/models/booking/solicitud_servicio_dto.dart';
import 'package:servizone_app/data/models/booking/reserva_dto.dart';
import 'package:servizone_app/data/models/booking/resena_dto.dart';

class BookingApiService {
  final ApiClient _client;

  BookingApiService(this._client);

  // ─── Helpers ──────────────────────────────────────────────────────────────

  ApiResponseDto? _decodeEnvelope(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return ApiResponseDto.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[BookingApiService] decodeEnvelope error: $e');
    }
    return null;
  }

  String _parseError(String body, int sc) {
    if (body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          final msg = decoded['message'] ?? decoded['Message'] ??
              decoded['error'] ?? decoded['Error'] ?? decoded['title'];
          if (msg != null) return msg.toString();
        }
        if (decoded is String) return decoded;
      } catch (_) {}
    }
    if (sc == 400) return 'Solicitud inválida.';
    if (sc == 401) return 'Sesión expirada. Inicia sesión nuevamente.';
    if (sc == 403) return 'No tienes permisos para esta operación.';
    if (sc == 404) return 'Recurso no encontrado.';
    if (sc == 409) return 'Conflicto: operación no permitida en el estado actual.';
    if (sc >= 500) return 'Error interno del servidor.';
    return 'Error desconocido (código $sc).';
  }

  List<T> _mapList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  // ─── SOLICITUDES ─────────────────────────────────────────────────────────

  /// POST /api/solicitudes — cliente crea una solicitud de servicio.
  Future<ApiResult<SolicitudServicioDto>> crearSolicitud(int servicioProveedorId) async {
    try {
      final response = await _client.postRequest(
        '/solicitudes',
        {'servicioProveedorId': servicioProveedorId},
      );
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      final envelope = _decodeEnvelope(response.body);
      if (envelope != null && envelope.data is Map) {
        final dto = SolicitudServicioDto.fromJson(Map<String, dynamic>.from(envelope.data as Map));
        return ApiResult.success(data: dto, statusCode: sc, message: envelope.message);
      }
      return ApiResult.failure(message: 'Respuesta inesperada del servidor.', statusCode: sc);
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  /// GET /api/solicitudes/proveedor/pendientes — proveedor obtiene sus solicitudes pendientes.
  Future<ApiResult<List<SolicitudServicioDto>>> getSolicitudesPendientes() async {
    try {
      final response = await _client.getRequest('/solicitudes/proveedor/pendientes');
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      final envelope = _decodeEnvelope(response.body);
      final list = _mapList<SolicitudServicioDto>(
        envelope?.data,
        SolicitudServicioDto.fromJson,
      );
      return ApiResult.success(data: list, statusCode: sc, message: envelope?.message ?? '');
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  /// PATCH /api/solicitudes/{id}/aceptar — proveedor acepta una solicitud.
  Future<ApiResult<void>> aceptarSolicitud(int id) async {
    try {
      final response = await _client.patchRequest('/solicitudes/$id/aceptar', {});
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      return ApiResult.success(data: null, statusCode: sc);
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  /// PATCH /api/solicitudes/{id}/rechazar — proveedor rechaza una solicitud.
  Future<ApiResult<void>> rechazarSolicitud(int id) async {
    try {
      final response = await _client.patchRequest('/solicitudes/$id/rechazar', {});
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      return ApiResult.success(data: null, statusCode: sc);
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  // ─── RESERVAS ─────────────────────────────────────────────────────────────

  /// GET /api/reservas/mis-bookings — cliente obtiene todas sus reservas.
  Future<ApiResult<List<ReservaDto>>> getMisBookings() async {
    try {
      final response = await _client.getRequest('/reservas/mis-bookings');
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      final envelope = _decodeEnvelope(response.body);
      final list = _mapList<ReservaDto>(envelope?.data, ReservaDto.fromJson);
      return ApiResult.success(data: list, statusCode: sc, message: envelope?.message ?? '');
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  /// GET /api/reservas/mis-bookings/{solicitudId} — cliente obtiene detalle de una reserva.
  Future<ApiResult<ReservaDto>> getMiBookingDetalle(int solicitudId) async {
    try {
      final response = await _client.getRequest('/reservas/mis-bookings/$solicitudId');
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      final envelope = _decodeEnvelope(response.body);
      if (envelope != null && envelope.data is Map) {
        final dto = ReservaDto.fromJson(Map<String, dynamic>.from(envelope.data as Map));
        return ApiResult.success(data: dto, statusCode: sc, message: envelope.message);
      }
      return ApiResult.failure(message: 'Respuesta inesperada del servidor.', statusCode: sc);
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  /// GET /api/reservas/proveedor — proveedor obtiene todas sus reservas.
  Future<ApiResult<List<ReservaDto>>> getReservasProveedor() async {
    try {
      final response = await _client.getRequest('/reservas/proveedor');
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      final envelope = _decodeEnvelope(response.body);
      final list = _mapList<ReservaDto>(envelope?.data, ReservaDto.fromJson);
      return ApiResult.success(data: list, statusCode: sc, message: envelope?.message ?? '');
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  /// PATCH /api/reservas/proveedor/{solicitudId}/completar-datos
  /// Proveedor completa los datos logísticos de la reserva.
  Future<ApiResult<void>> completarDatosReserva({
    required int solicitudId,
    required double precioAcordado,
    required String direccionCliente,
    required DateTime fechaHoraReserva,
  }) async {
    try {
      final response = await _client.patchRequest(
        '/reservas/proveedor/$solicitudId/completar-datos',
        {
          'precioAcordado': precioAcordado,
          'direccionCliente': direccionCliente,
          'fechaHoraReserva': fechaHoraReserva.toIso8601String(),
        },
      );
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      return ApiResult.success(data: null, statusCode: sc);
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  /// PATCH /api/reservas/proveedor/{solicitudId}/completar — proveedor marca la reserva como completada.
  Future<ApiResult<void>> completarReserva(int solicitudId) async {
    try {
      final response = await _client.patchRequest('/reservas/proveedor/$solicitudId/completar', {});
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      return ApiResult.success(data: null, statusCode: sc);
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  /// PATCH /api/reservas/proveedor/{solicitudId}/cancelar — proveedor cancela la reserva.
  Future<ApiResult<void>> cancelarReserva(int solicitudId) async {
    try {
      final response = await _client.patchRequest('/reservas/proveedor/$solicitudId/cancelar', {});
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      return ApiResult.success(data: null, statusCode: sc);
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  // ─── RESEÑAS ──────────────────────────────────────────────────────────────

  /// POST /api/resenas/{solicitudId} — cliente deja una reseña tras completar la reserva.
  /// [calificacion] debe estar entre 1 y 5.
  Future<ApiResult<ResenaDto>> crearResena({
    required int solicitudId,
    required int calificacion,
    String? comentario,
  }) async {
    try {
      final body = <String, dynamic>{'calificacion': calificacion};
      if (comentario != null && comentario.trim().isNotEmpty) {
        body['comentario'] = comentario.trim();
      }
      final response = await _client.postRequest('/resenas/$solicitudId', body);
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      final envelope = _decodeEnvelope(response.body);
      if (envelope != null && envelope.data is Map) {
        final dto = ResenaDto.fromJson(Map<String, dynamic>.from(envelope.data as Map));
        return ApiResult.success(data: dto, statusCode: sc, message: envelope.message);
      }
      return ApiResult.failure(message: 'Respuesta inesperada del servidor.', statusCode: sc);
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  /// GET /api/resenas/proveedor/mis-resenas — proveedor obtiene las reseñas recibidas.
  Future<ApiResult<List<ResenaDto>>> getMisResenasProveedor() async {
    try {
      final response = await _client.getRequest('/resenas/proveedor/mis-resenas');
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      final envelope = _decodeEnvelope(response.body);
      final list = _mapList<ResenaDto>(envelope?.data, ResenaDto.fromJson);
      return ApiResult.success(data: list, statusCode: sc, message: envelope?.message ?? '');
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }

  /// GET /api/resenas/servicio/{servicioProveedorId} — obtiene reseñas de un servicio específico.
  Future<ApiResult<List<ResenaDto>>> getResenasServicio(int servicioProveedorId) async {
    try {
      final response = await _client.getRequest('/resenas/servicio/$servicioProveedorId');
      final sc = response.statusCode;
      if (sc < 200 || sc >= 300) {
        return ApiResult.failure(message: _parseError(response.body, sc), statusCode: sc);
      }
      final envelope = _decodeEnvelope(response.body);
      final list = _mapList<ResenaDto>(envelope?.data, ResenaDto.fromJson);
      return ApiResult.success(data: list, statusCode: sc, message: envelope?.message ?? '');
    } catch (e) {
      return ApiResult.failure(message: 'Error de red: $e', statusCode: 0);
    }
  }
}
