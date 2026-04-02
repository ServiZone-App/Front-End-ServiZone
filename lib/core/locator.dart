import 'package:get_it/get_it.dart';
import 'package:servizone_app/config/api_config.dart';
import 'package:servizone_app/core/network/api_client.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/data/providers/catalog_service.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/data/providers/admin_audit_service.dart';
import 'package:servizone_app/data/repositories/auth_repository_impl.dart';
import 'package:servizone_app/data/repositories/catalog_repository_impl.dart';
import 'package:servizone_app/data/repositories/booking_repository_impl.dart';
import 'package:servizone_app/domain/repositories/auth_repository.dart';
import 'package:servizone_app/domain/repositories/catalog_repository.dart';
import 'package:servizone_app/domain/repositories/booking_repository.dart';
import 'package:servizone_app/presentation/viewmodels/auth_view_model.dart';
import 'package:servizone_app/presentation/viewmodels/catalog_view_model.dart';
import 'package:servizone_app/presentation/viewmodels/booking_view_model.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: ApiConfig.authBaseUrl),
    instanceName: 'auth',
  );
  locator.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: ApiConfig.catalogBaseUrl),
    instanceName: 'catalog',
  );

  locator.registerLazySingleton<AuthService>(
      () => AuthService(locator<ApiClient>(instanceName: 'auth')));
  locator.registerLazySingleton<CatalogService>(
      () => CatalogService(locator<ApiClient>(instanceName: 'catalog')));
  locator.registerLazySingleton<CatalogNotifier>(
      () => CatalogNotifier(locator<CatalogService>()));
  locator.registerLazySingleton<AdminAuditService>(() => AdminAuditService());

  locator.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(locator<AuthService>()));
  locator.registerLazySingleton<CatalogRepository>(() => CatalogRepositoryImpl(locator<CatalogService>()));
  locator.registerLazySingleton<BookingRepository>(
      () => BookingRepositoryImpl(locator<ApiClient>(instanceName: 'auth')));

  locator.registerFactory<AuthViewModel>(() => AuthViewModel(locator<AuthRepository>()));
  locator.registerFactory<CatalogViewModel>(() => CatalogViewModel(locator<CatalogRepository>()));
  locator.registerFactory<BookingViewModel>(() => BookingViewModel(locator<BookingRepository>()));
}
