# Plan de Remediación (sin mocks / seguridad / calidad)

Escala de esfuerzo: XS (≤1 día), S (1–2), M (3–5), L (6–10), XL (>10) días de trabajo efectivo.

## Fase 0 — Bloqueos (Necesario para cerrar “sin mocks”)
- Definir contrato backend para reservas/solicitudes proveedor/cliente (endpoints, modelos, errores, auth). (M)
- Entregar documentación técnica y/o colección Postman/OpenAPI del backend. (S)

## Fase 1 — Seguridad (OWASP) y Endurecimiento (Release)
- Separar entornos por flavors (dev/stage/prod) y deshabilitar cleartext en release. (M)
- Implementar `network_security_config` en Android para permitir solo dominios explícitos en debug. (S)
- Revisar almacenamiento de tokens en Flutter Web y definir estrategia (session-only o cifrado/rotación). (M)
- Añadir rate limit UX (backoff global) ante 429 y bloqueo temporal en login (si backend lo soporta). (M)

## Fase 2 — Integración Real (Proveedor/Cliente)
- Sustituir `ProviderBookingService` por `BookingService` (API real) + `BookingNotifier` / estado unificado. (L)
- Persistencia y sincronización (cache TTL, reintentos idempotentes). (M)
- Manejo consistente de errores (usar `message` del JSON y fallback por status). (S)

## Fase 3 — Arquitectura / SOLID / Testabilidad
- Introducir repositorios e interfaces (`AuthRepository`, `CatalogRepository`, `BookingRepository`) sin romper UI. (M)
- Unificar modelos de respuesta (`ApiResult`) para Auth y Catalog. (M)
- Reducir uso directo de locator en UI (inyección por constructor o wrappers). (L)

## Fase 4 — Calidad (Lint, Deprecations, CI)
- Resolver warnings principales (`unused_*`, imports duplicados, código muerto). (S)
- Migrar APIs deprecadas (RadioGroup, propiedades de FormField, etc.). (M)
- Configurar CI mínimo: `flutter test` + `flutter analyze` como gate. (S)

## Fase 5 — UX/Accesibilidad
- Reintroducir ThemeMode persistente (dark/light/system) sin flicker. (S)
- Verificar contrastes AA y overflow (móvil <320px) con golden tests básicos. (M)

