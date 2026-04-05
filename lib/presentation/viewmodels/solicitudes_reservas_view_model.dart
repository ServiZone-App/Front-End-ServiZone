import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/models/booking/solicitud_servicio_dto.dart';
import 'package:servizone_app/data/models/booking/reserva_dto.dart';
import 'package:servizone_app/data/models/booking/resena_dto.dart';
import 'package:servizone_app/data/providers/booking_api_service.dart';
import 'package:servizone_app/presentation/viewmodels/base_view_model.dart';

/// ViewModel para el flujo de solicitudes, reservas y reseñas.
///
/// Estados del flujo:
///   pendiente → en_revision → en_proceso → completado
///                                         → cancelado
///              → rechazada
///
/// Rol CLIENTE : solicitarServicio, cargarMisBookings,
///               cargarBookingDetalle, dejarResena
/// Rol PROVEEDOR: cargarSolicitudesPendientes, aceptarSolicitud,
///               rechazarSolicitud, completarDatosReserva,
///               completarReserva, cancelarReserva,
///               cargarReservasProveedor, cargarMisResenasProveedor
class SolicitudesReservasViewModel extends BaseViewModel {
  final BookingApiService _service;

  SolicitudesReservasViewModel(this._service);

  // ─── Estado ──────────────────────────────────────────────────────────────

  /// Solicitudes en estado "pendiente" visibles para el proveedor.
  List<SolicitudServicioDto> solicitudesPendientes = const [];

  /// Reservas del cliente autenticado (todos los estados).
  List<ReservaDto> misBookings = const [];

  /// Detalle de una reserva específica del cliente.
  ReservaDto? bookingDetalle;

  /// Reservas asignadas al proveedor autenticado (todos los estados).
  List<ReservaDto> reservasProveedor = const [];

  /// Reseñas recibidas por el proveedor autenticado.
  List<ResenaDto> misResenasProveedor = const [];

  /// Último código HTTP de error (401 / 403 / 404 / …).
  /// La vista puede usarlo para diferenciar entre "sesión expirada",
  /// "sin permisos" y "recurso no encontrado".
  int? lastErrorCode;

  // ─── Helpers internos ────────────────────────────────────────────────────

  void _handleFailure(ApiResult<dynamic> res) {
    lastErrorCode = res.statusCode;
    setError(_friendlyMessage(res.message, res.statusCode));
  }

  String _friendlyMessage(String raw, int code) {
    if (code == 401) return 'Sesión expirada. Inicia sesión nuevamente.';
    if (code == 403) return 'No tienes permisos para realizar esta acción.';
    if (code == 404) return 'No se encontró el recurso solicitado.';
    return raw.isNotEmpty ? raw : 'Ocurrió un error inesperado.';
  }

  // ─── CLIENTE ─────────────────────────────────────────────────────────────

  /// Crea una solicitud de servicio.
  /// Estado resultante: **pendiente**.
  Future<ApiResult<SolicitudServicioDto>> solicitarServicio(
      int servicioProveedorId) async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.crearSolicitud(servicioProveedorId);
    if (!res.success) _handleFailure(res);
    setBusy(false);
    return res;
  }

  /// Carga todas las reservas del cliente (cualquier estado).
  Future<ApiResult<List<ReservaDto>>> cargarMisBookings() async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.getMisBookings();
    if (res.success && res.data != null) {
      misBookings = res.data!;
    } else {
      _handleFailure(res);
    }
    setBusy(false);
    return res;
  }

  /// Carga el detalle de una reserva específica del cliente.
  Future<ApiResult<ReservaDto>> cargarBookingDetalle(int solicitudId) async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.getMiBookingDetalle(solicitudId);
    if (res.success && res.data != null) {
      bookingDetalle = res.data;
    } else {
      _handleFailure(res);
    }
    setBusy(false);
    return res;
  }

  /// Deja una reseña. Solo válido cuando estado == "completado".
  /// [calificacion] debe estar entre 1 y 5.
  Future<ApiResult<ResenaDto>> dejarResena({
    required int solicitudId,
    required int calificacion,
    String? comentario,
  }) async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.crearResena(
      solicitudId: solicitudId,
      calificacion: calificacion,
      comentario: comentario,
    );
    if (!res.success) _handleFailure(res);
    setBusy(false);
    return res;
  }

  // ─── PROVEEDOR ───────────────────────────────────────────────────────────

  /// Carga las solicitudes en estado "pendiente" del proveedor.
  Future<ApiResult<List<SolicitudServicioDto>>>
      cargarSolicitudesPendientes() async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.getSolicitudesPendientes();
    if (res.success && res.data != null) {
      solicitudesPendientes = res.data!;
    } else {
      _handleFailure(res);
    }
    setBusy(false);
    return res;
  }

  /// Acepta una solicitud pendiente.
  /// Estado resultante: **en_revision** (se crea la reserva asociada).
  Future<ApiResult<void>> aceptarSolicitud(int id) async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.aceptarSolicitud(id);
    if (res.success) {
      // Remueve la solicitud aceptada de la lista local para reflejar el cambio inmediatamente.
      solicitudesPendientes =
          solicitudesPendientes.where((s) => s.id != id).toList();
      notifyListeners();
    } else {
      _handleFailure(res);
    }
    setBusy(false);
    return res;
  }

  /// Rechaza una solicitud pendiente.
  /// Estado resultante: **rechazada**.
  Future<ApiResult<void>> rechazarSolicitud(int id) async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.rechazarSolicitud(id);
    if (res.success) {
      solicitudesPendientes =
          solicitudesPendientes.where((s) => s.id != id).toList();
      notifyListeners();
    } else {
      _handleFailure(res);
    }
    setBusy(false);
    return res;
  }

  /// Carga todas las reservas del proveedor (cualquier estado).
  Future<ApiResult<List<ReservaDto>>> cargarReservasProveedor() async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.getReservasProveedor();
    if (res.success && res.data != null) {
      reservasProveedor = res.data!;
    } else {
      _handleFailure(res);
    }
    setBusy(false);
    return res;
  }

  /// Completa los datos logísticos de la reserva.
  /// Estado resultante: **en_proceso**.
  Future<ApiResult<void>> completarDatosReserva({
    required int solicitudId,
    required double precioAcordado,
    required String direccionCliente,
    required DateTime fechaHoraReserva,
  }) async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.completarDatosReserva(
      solicitudId: solicitudId,
      precioAcordado: precioAcordado,
      direccionCliente: direccionCliente,
      fechaHoraReserva: fechaHoraReserva,
    );
    if (!res.success) _handleFailure(res);
    setBusy(false);
    return res;
  }

  /// Marca la reserva como completada.
  /// Estado resultante: **completado**.
  Future<ApiResult<void>> completarReserva(int solicitudId) async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.completarReserva(solicitudId);
    if (!res.success) _handleFailure(res);
    setBusy(false);
    return res;
  }

  /// Cancela la reserva.
  /// Estado resultante: **cancelado**.
  Future<ApiResult<void>> cancelarReserva(int solicitudId) async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.cancelarReserva(solicitudId);
    if (!res.success) _handleFailure(res);
    setBusy(false);
    return res;
  }

  /// Carga las reseñas recibidas por el proveedor autenticado.
  Future<ApiResult<List<ResenaDto>>> cargarMisResenasProveedor() async {
    setBusy(true);
    clearError();
    lastErrorCode = null;
    final res = await _service.getMisResenasProveedor();
    if (res.success && res.data != null) {
      misResenasProveedor = res.data!;
    } else {
      _handleFailure(res);
    }
    setBusy(false);
    return res;
  }
}
