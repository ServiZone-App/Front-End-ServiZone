import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/core/routes/app_routes.dart';
import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/domain/repositories/auth_repository.dart';
import 'package:servizone_app/presentation/viewmodels/auth_view_model.dart';
import 'package:servizone_app/presentation/views/splash/splash_screen.dart';

class _TestAuthRepo implements AuthRepository {
  @override
  bool get isLoggedIn => false;

  @override
  String? get currentRole => null;

  @override
  Map<String, dynamic>? get currentUserProfile => null;

  @override
  Future<ApiResult<bool>> autoLogin() async => ApiResult.success(data: false, statusCode: 200);

  @override
  Future<ApiResult<Map<String, dynamic>>> fetchAndStoreProfile() async =>
      ApiResult.success(data: {}, statusCode: 200);

  @override
  Future<ApiResult<List<Map<String, dynamic>>>> getAllUsuarios() async =>
      ApiResult.success(data: const [], statusCode: 200);

  @override
  Future<ApiResult<int?>> getCurrentClienteId() async => ApiResult.success(data: null, statusCode: 200);

  @override
  Future<ApiResult<int?>> getCurrentProveedorId() async => ApiResult.success(data: null, statusCode: 200);

  @override
  Future<ApiResult<List<Map<String, dynamic>>>> getProveedoresVerificados() async =>
      ApiResult.success(data: const [], statusCode: 200);

  @override
  Future<ApiResult<List<Map<String, dynamic>>>> getSolicitudesProveedor() async =>
      ApiResult.success(data: const [], statusCode: 200);

  @override
  Future<ApiResult<Map<String, dynamic>>> login({required String email, required String password}) async =>
      ApiResult.failure(message: 'no', statusCode: 401);

  @override
  Future<ApiResult<void>> logout() async => ApiResult.success(data: null, statusCode: 200);

  @override
  Future<ApiResult<void>> procesarSolicitudProveedor(int solicitudId, bool aprobado) async =>
      ApiResult.success(data: null, statusCode: 200);

  @override
  Future<ApiResult<void>> actualizarEstadoProveedor(int proveedorId, String nuevoEstado) async =>
      ApiResult.success(data: null, statusCode: 200);

  @override
  Future<ApiResult<Map<String, dynamic>>> switchRole(String targetRole) async =>
      ApiResult.failure(message: 'no', statusCode: 400);
}

void main() {
  testWidgets('ServiZone splash screen test', (WidgetTester tester) async {
    await locator.reset();
    locator.registerLazySingleton<AuthRepository>(() => _TestAuthRepo());
    locator.registerFactory<AuthViewModel>(() => AuthViewModel(locator<AuthRepository>()));

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const Scaffold(body: Text('LOGIN')),
        },
      ),
    );

    expect(find.byIcon(Icons.handyman), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
