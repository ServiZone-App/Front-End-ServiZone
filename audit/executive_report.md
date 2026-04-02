# Auditoría del Código Base — ServiZone (Flutter)

Fecha: 2026-04-02  
Alcance: módulos Admin, Proveedor y Cliente (Flutter/Dart), capa de red, configuración de entorno, rutas y tests.

## Resumen Ejecutivo

El proyecto tiene una base funcional sólida (separación parcial por capas, DI con GetIt, `ApiClient` con refresh token) pero presenta riesgos de seguridad y estabilidad típicos de apps móviles en fase de integración:

- Riesgo crítico de **tráfico en claro** (HTTP/cleartext) en configuración por defecto, con impacto directo en credenciales/tokens.
- Riesgo alto de **exposición de PII/tokens en logs** (debug prints) y rutas sin guard consistente para cliente/proveedor.
- Riesgo alto de **funcionalidad no conectada a backend** en el módulo proveedor (reservas/solicitudes via `ProviderBookingService` en memoria).
- Estado de calidad: `flutter test` pasa; `flutter analyze` aún reporta warnings/info (principalmente imports/fields no usados y APIs deprecadas).

## Hallazgos Priorizados (Severidad)

### Crítico
1) Tráfico en claro (HTTP) habilitado por defecto (MITM/robo de sesión).
   - Evidencia: `EnvironmentConfig` usa `http://...` por defecto; Android permite cleartext.
   - Estado: mitigación implementada con `--dart-define=API_BASE_URL` y `--dart-define=ALLOW_CLEARTEXT=false` (ver `EnvironmentConfig`).
   - Remediación recomendada: separar entornos por flavors (dev/stage/prod) con manifest overlay y TLS obligatorio en release.

2) Reintentos en `ApiClient.send` podían reusar el mismo request (riesgo de runtime “stream already listened”).
   - Evidencia: loop de retry reusaba el `BaseRequest`.
   - Estado: corregido clonando el request por intento.

### Alto
3) Logging de PII y potencialmente tokens en consola.
   - Evidencia: prints de perfil y respuestas crudas.
   - Estado: removido o acotado a `kDebugMode` en Auth/Catalog/ApiClient.

4) Guard de rutas incompleto para cliente/proveedor.
   - Evidencia: solo `/admin/*` estaba protegido.
   - Estado: se añadió guard para `/client/*` y `/provider/*` en `AppRoutes`.

5) Módulo proveedor con datos en memoria (sin API real) para solicitudes/reservas.
   - Evidencia: `ProviderBookingService` contiene lista en memoria con reservas.
   - Estado: no se migró por falta de endpoints de reservas confirmados; requiere definición del contrato backend.

### Medio
6) Dark mode/persistencia de tema no está activo (ThemeMode fijo en light).
   - Evidencia: `main.dart` fija `themeMode: ThemeMode.light` y el provider fue removido.
   - Remediación recomendada: reintroducir gestor de tema persistente (preferiblemente sin romper web).

7) Inconsistencia de contrato de API (envelopes/casing y paths con mayúsculas/minúsculas).
   - Evidencia: `/Solicitud/*` vs `/solicitud/*` y envelopes `Data/data`, `Message/message`.
   - Remediación recomendada: normalizar en backend o documentar y mapear de forma centralizada.

### Bajo
8) Deudas de lint/compatibilidad (imports no usados, miembros deprecados, funciones no usadas).
   - Evidencia: `flutter analyze` reporta 64 issues (mayoría warnings/info).
   - Remediación recomendada: limpieza incremental + migración de APIs deprecadas (RadioGroup, withValues, etc.).

## Estado de Verificación
- `flutter test`: OK
- `flutter analyze`: warnings/info pendientes (no bloqueantes, pero deben cerrarse para CI “clean”).

## Recomendación de Próximo Paso (Bloqueo)
Para completar la migración “100% sin mocks” en proveedor/cliente, se requiere:
- Acceso al contrato backend de **reservas/solicitudes proveedor** (paths, payloads, estados, errores).
- En caso de existir GraphQL u otros servicios: documentación o introspección del schema.

