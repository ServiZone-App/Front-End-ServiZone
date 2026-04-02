# Arquitectura — Actual vs Recomendada

## Actual (observada)

```mermaid
flowchart LR
  UI[Presentation\nScreens/Widgets] -->|locator<T>()| DI[GetIt Service Locator]
  DI --> Auth[AuthService]
  DI --> CatalogN[CatalogNotifier]
  DI --> CatalogS[CatalogService]
  DI --> Api[ApiClient]
  Auth --> Api
  CatalogN --> CatalogS
  CatalogS --> Api
  Api -->|HTTP REST| Backend[(Auth/Catalog API)]
  Auth --> Secure[(FlutterSecureStorage)]
  UI --> Prefs[(SharedPreferences)]
```

Características:
- UI llama directamente a servicios via locator (acoplamiento alto).
- `AuthService` retorna `Map` dinámicos; `CatalogService` retorna `ApiResult<T>`.
- Manejo de entorno y base URL vía `EnvironmentConfig`.

## Recomendada (objetivo)

```mermaid
flowchart LR
  UI[Presentation] --> VM[Controllers/ViewModels\n(estado + casos de uso)]
  VM --> RepoI[Interfaces\nAuthRepository/CatalogRepository/BookingRepository]
  RepoI --> Repo[Implementaciones\n*Repository]
  Repo --> Api[ApiClient]
  Repo --> Mappers[DTO/Mapper Layer]
  Api --> Backend[(APIs)]
  Repo --> Cache[Cache/Storage]
  Cache --> Secure[(SecureStorage/Prefs)]
  subgraph DI[DI Container]
    RepoI
    Repo
    Api
    Mappers
  end
```

Cambios clave:
- Introducir “Repositories” (interfaces) para testabilidad y DIP.
- Unificar shape de respuestas (`ApiResult`) para Auth y Catalog.
- Centralizar contratos (endpoints, casing, errores) en una sola capa.
- Preparar “BookingRepository” para eliminar servicios en memoria en proveedor/cliente.

