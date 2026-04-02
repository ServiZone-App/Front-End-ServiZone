# Implementación de Arquitectura (UI → ViewModels → Repos → ApiClient)

## Objetivo
Separar completamente UI de la lógica de estado/casos de uso, unificando contratos de API y retornos en `ApiResult<T>`, con repositorios inyectables para testabilidad.

## Estructura

### 1) Presentación (UI)
Ubicación: `lib/presentation/views/**`
- Las pantallas no deberían llamar a servicios HTTP ni a providers de datos directamente.
- Las pantallas consumen un `ViewModel` (ChangeNotifier) que expone:
  - estado (`isBusy`, `error`)
  - colecciones (`bookings`, `categorias`, etc.)
  - acciones (`load`, `confirm`, `cancel`, etc.)

### 2) ViewModels
Ubicación: `lib/presentation/viewmodels/**`
- `BaseViewModel`: estado base común (`isBusy`, `error`).
- `AuthViewModel`: login/autologin/switchRole/logout.
- `BookingViewModel`: listado/acciones sobre reservas.
- `CatalogViewModel`: carga de catálogo (categorías/subcategorías/tipos/servicios).

### 3) Contratos de Repositorio (Interfaces)
Ubicación: `lib/domain/repositories/**`
- `AuthRepository`
- `CatalogRepository`
- `BookingRepository`

Todos los métodos retornan `Future<ApiResult<T>>`.

### 4) Implementaciones de Repositorio
Ubicación: `lib/data/repositories/**`
- `AuthRepositoryImpl`: adapta `AuthService` a `ApiResult`.
- `CatalogRepositoryImpl`: adapta `CatalogService` a `ApiResult`.
- `BookingRepositoryImpl`: ejecuta llamadas HTTP via `ApiClient` (sin listas en memoria).

### 5) ApiClient
Ubicación: `lib/core/network/api_client.dart`
- Centraliza headers, retries, timeout y refresh token.
- Expone helpers `getRequest/postRequest/putRequest/patchRequest/deleteRequest`.

### 6) Mappers (DTO/Transformación)
Ubicación: `lib/data/mappers/**`
- `BookingMapper`: mapea JSON (camelCase/PascalCase mixto) a `BookingModel`.

## DI Container
Ubicación: `lib/core/locator.dart`
- Registra:
  - Infra: `ApiClient`, `AuthService`, `CatalogService`
  - Repos: `AuthRepository`, `CatalogRepository`, `BookingRepository`
  - ViewModels: factories (`AuthViewModel`, `CatalogViewModel`, `BookingViewModel`)

## Ejemplo de uso en UI
Patrón (StatefulWidget):
1. `final vm = locator<BookingViewModel>();`
2. `vm.addListener(() => setState(() {}));`
3. `await vm.load...();`
4. UI renderiza `vm.isBusy`, `vm.error`, `vm.bookings`.

## Pruebas
Ubicación: `test/`
- `test/data/mappers/booking_mapper_test.dart`
- `test/presentation/viewmodels/booking_view_model_test.dart`
- `test/widget_test.dart` (splash)

