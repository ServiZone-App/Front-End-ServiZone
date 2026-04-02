# Endpoints Consumidos por la App (Inventario)

Base URL (runtime):
- `EnvironmentConfig.apiBaseUrl` (por defecto): `http://192.168.1.5:5059/api` (móvil) / `http://localhost:5059/api` (web)
- Override (recomendado): `--dart-define=API_BASE_URL=https://...`

Headers comunes:
- `Authorization: Bearer <accessToken>` (cuando exista token)
- `Content-Type: application/json` (POST/PATCH/PUT)
- `Accept: application/json`

## Auth API (camelCase en respuestas)

### POST `/auth/login`
Body:
```json
{ "correo": "user@correo.com", "contrasena": "secret" }
```
Respuesta esperada (ejemplo):
```json
{
  "accessToken": "jwt...",
  "refreshToken": "jwt...",
  "role": "cliente",
  "rolesDisponibles": ["cliente", "proveedor"]
}
```

### POST `/auth/register`
Body: (según formulario)
```json
{ "correo": "user@correo.com", "contrasena": "secret", "nombre": "Juan" }
```
Respuesta: 200/201 sin contrato fijo (la app valida status).

### POST `/auth/switch-role`
Body (string JSON puro):
```json
"Proveedor"
```
Respuesta esperada (ejemplo):
```json
{
  "success": true,
  "token": "jwt...",
  "refreshToken": "jwt...",
  "activeRole": "proveedor",
  "rolesDisponibles": ["cliente", "proveedor"],
  "message": "Cambio de rol exitoso"
}
```

### POST `/auth/refresh`
Body:
```json
{ "accessToken": "jwt...", "refreshToken": "jwt..." }
```
Respuesta esperada:
```json
{ "accessToken": "jwt...", "refreshToken": "jwt..." }
```

### GET `/perfil/cliente`
Respuesta: objeto o envelope con `Data/data`.

### GET `/perfil/proveedor`
Respuesta: objeto o envelope con `Data/data`.

### PATCH `/perfil/cliente`
Body: objeto parcial (campos no nulos).

### PATCH `/perfil/proveedor`
Body: objeto parcial (campos no nulos).

### POST `/solicitud/Enviar_Solicitud` (Multipart)
Fields:
- `DescripcionPerfil` (string)
- `AnosExperiencia` (string/int)
- `Documentos` (files[])

## Admin Auth API (camelCase / mixto)

### GET `/Solicitud/listar-solicitudes`
Respuesta (ejemplo):
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "usuarioNombre": "Ana",
      "usuarioCorreo": "ana@correo.com",
      "usuarioTelefono": "300...",
      "descripcionPerfil": "Perfil...",
      "anosExperiencia": 3,
      "documentos": ["https://..."],
      "fechaSolicitud": "2026-04-01T00:00:00Z",
      "estado": "Pendiente"
    }
  ],
  "message": ""
}
```

### PUT `/Solicitud/Gestionar_solicitudes/{id}`
Body (string JSON puro):
```json
"Aprobada"
```
o
```json
"Rechazada"
```

### GET `/admin/usuarios`
Respuesta: lista dentro de `Data/data` o lista directa.

### GET `/admin/proveedores`
Respuesta: lista dentro de `Data/data` o lista directa.

### PUT `/admin/proveedores/{id}/estado`
Body:
```json
{ "estado": "activo" }
```

## Catalog API (PascalCase en JSON)

Contrato esperado: envelope PascalCase
```json
{ "Success": true, "Data": [], "Message": "" }
```

### Categorías
- GET `/categorias`
- GET `/categorias/{id}`
- POST `/categorias` — Body:
```json
{ "Nombre": "Belleza", "Descripcion": "..." }
```
- PUT `/categorias/{id}` — Body: igual a POST
- DELETE `/categorias/{id}`

### Subcategorías
- GET `/subcategorias`
- GET `/subcategorias?categoriaId={id}`
- GET `/subcategorias/{id}`
- POST `/subcategorias` — Body:
```json
{ "Nombre": "Uñas", "Descripcion": "...", "CategoriaId": 1 }
```
- PUT `/subcategorias/{id}`
- DELETE `/subcategorias/{id}`

### Tipos de Servicio
- GET `/tipos-servicio`
- GET `/tipos-servicio?subcategoriaId={id}`
- GET `/tipos-servicio/{id}`
- POST `/tipos-servicio` — Body:
```json
{ "Nombre": "Manicure", "Descripcion": "...", "SubcategoriaId": 2 }
```
- PUT `/tipos-servicio/{id}`
- DELETE `/tipos-servicio/{id}`

### Servicios Proveedor
- GET `/servicios-proveedor`
- GET `/servicios-proveedor?tipoServicioId={id}`
- GET `/servicios-proveedor?proveedorId={id}`
- GET `/servicios-proveedor/{id}`
- POST `/servicios-proveedor` — Body:
```json
{ "TipoServicioId": 3, "ProveedorId": 8, "PrecioBase": 35000, "Estado": true }
```
- PUT `/servicios-proveedor/{id}`
- DELETE `/servicios-proveedor/{id}`

