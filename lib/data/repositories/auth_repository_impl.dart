import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _service;

  AuthRepositoryImpl(this._service);

  @override
  Future<ApiResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final res = await _service.login(email, password);
    if (res['success'] == true) {
      return ApiResult.success(
        data: Map<String, dynamic>.from(res),
        message: res['message']?.toString() ?? '',
        statusCode: res['statusCode'] is int ? res['statusCode'] as int : 200,
      );
    }
    return ApiResult.failure(
      message: res['message']?.toString() ?? 'Error de autenticación.',
      statusCode: res['statusCode'] is int ? res['statusCode'] as int : 0,
    );
  }

  @override
  Future<ApiResult<void>> logout() async {
    await _service.logout();
    return ApiResult.success(data: null, statusCode: 200);
  }

  @override
  Future<ApiResult<bool>> autoLogin() async {
    final ok = await _service.autoLogin();
    return ApiResult.success(data: ok, statusCode: 200);
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> fetchAndStoreProfile() async {
    final res = await _service.fetchAndStoreProfile();
    if (res['success'] == true) {
      return ApiResult.success(
        data: Map<String, dynamic>.from(res),
        message: res['message']?.toString() ?? '',
        statusCode: res['statusCode'] is int ? res['statusCode'] as int : 200,
      );
    }
    return ApiResult.failure(
      message: res['message']?.toString() ?? 'Error cargando perfil.',
      statusCode: res['statusCode'] is int ? res['statusCode'] as int : 0,
    );
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> switchRole(String targetRole) async {
    final res = await _service.switchRole(targetRole);
    if (res['success'] == true) {
      return ApiResult.success(
        data: Map<String, dynamic>.from(res),
        message: res['message']?.toString() ?? '',
        statusCode: res['statusCode'] is int ? res['statusCode'] as int : 200,
      );
    }
    return ApiResult.failure(
      message: res['message']?.toString() ?? 'No se pudo cambiar el rol.',
      statusCode: res['statusCode'] is int ? res['statusCode'] as int : 0,
    );
  }

  @override
  Future<ApiResult<List<Map<String, dynamic>>>> getAllUsuarios() async {
    final res = await _service.getAllUsuarios();
    if (res['success'] == true) {
      final data = (res['data'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return ApiResult.success(data: data, statusCode: res['statusCode'] is int ? res['statusCode'] as int : 200);
    }
    return ApiResult.failure(message: res['message']?.toString() ?? 'Error cargando usuarios.', statusCode: res['statusCode'] is int ? res['statusCode'] as int : 0);
  }

  @override
  Future<ApiResult<List<Map<String, dynamic>>>> getProveedoresVerificados() async {
    final res = await _service.getProveedoresVerificados();
    if (res['success'] == true) {
      final data = (res['data'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return ApiResult.success(data: data, statusCode: res['statusCode'] is int ? res['statusCode'] as int : 200);
    }
    return ApiResult.failure(message: res['message']?.toString() ?? 'Error cargando proveedores.', statusCode: res['statusCode'] is int ? res['statusCode'] as int : 0);
  }

  @override
  Future<ApiResult<List<Map<String, dynamic>>>> getSolicitudesProveedor() async {
    final res = await _service.getSolicitudesProveedor();
    if (res['success'] == true) {
      final data = (res['data'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return ApiResult.success(data: data, statusCode: res['statusCode'] is int ? res['statusCode'] as int : 200);
    }
    return ApiResult.failure(message: res['message']?.toString() ?? 'Error cargando solicitudes.', statusCode: res['statusCode'] is int ? res['statusCode'] as int : 0);
  }

  @override
  Future<ApiResult<void>> procesarSolicitudProveedor(int solicitudId, bool aprobado) async {
    final res = await _service.procesarSolicitudProveedor(solicitudId, aprobado);
    if (res['success'] == true) return ApiResult.success(data: null, statusCode: res['statusCode'] is int ? res['statusCode'] as int : 200);
    return ApiResult.failure(message: res['message']?.toString() ?? 'Error actualizando solicitud.', statusCode: res['statusCode'] is int ? res['statusCode'] as int : 0);
  }

  @override
  Future<ApiResult<void>> actualizarEstadoProveedor(int proveedorId, String nuevoEstado) async {
    final res = await _service.actualizarEstadoProveedor(proveedorId, nuevoEstado);
    if (res['success'] == true) return ApiResult.success(data: null, statusCode: res['statusCode'] is int ? res['statusCode'] as int : 200);
    return ApiResult.failure(message: res['message']?.toString() ?? 'Error actualizando estado.', statusCode: res['statusCode'] is int ? res['statusCode'] as int : 0);
  }

  @override
  Future<ApiResult<int?>> getCurrentProveedorId() async {
    final id = await _service.getCurrentProveedorId();
    return ApiResult.success(data: id, statusCode: 200);
  }

  @override
  Future<ApiResult<int?>> getCurrentClienteId() async {
    final id = await _service.getCurrentClienteId();
    return ApiResult.success(data: id, statusCode: 200);
  }

  @override
  bool get isLoggedIn => _service.isLoggedIn;

  @override
  String? get currentRole => _service.currentRole;

  @override
  Map<String, dynamic>? get currentUserProfile => _service.currentUserProfile;
}
