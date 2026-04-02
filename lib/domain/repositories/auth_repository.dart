import 'package:servizone_app/core/network/api_result.dart';

abstract class AuthRepository {
  Future<ApiResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  });

  Future<ApiResult<void>> logout();

  Future<ApiResult<bool>> autoLogin();

  Future<ApiResult<Map<String, dynamic>>> fetchAndStoreProfile();

  Future<ApiResult<Map<String, dynamic>>> switchRole(String targetRole);

  Future<ApiResult<List<Map<String, dynamic>>>> getAllUsuarios();

  Future<ApiResult<List<Map<String, dynamic>>>> getProveedoresVerificados();

  Future<ApiResult<List<Map<String, dynamic>>>> getSolicitudesProveedor();

  Future<ApiResult<void>> procesarSolicitudProveedor(int solicitudId, bool aprobado);

  Future<ApiResult<void>> actualizarEstadoProveedor(int proveedorId, String nuevoEstado);

  Future<ApiResult<int?>> getCurrentProveedorId();
  Future<ApiResult<int?>> getCurrentClienteId();

  bool get isLoggedIn;
  String? get currentRole;
  Map<String, dynamic>? get currentUserProfile;
}
