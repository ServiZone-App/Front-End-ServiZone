import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/network/api_client.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  bool _isLoggedIn = false;
  String? _currentRole;
  Map<String, dynamic>? currentUserProfile;
  List<String> rolesDisponibles = [];

  bool get isLoggedIn => _isLoggedIn;
  String? get currentRole => _currentRole;

  Future<bool> autoLogin() async {
    final results = await Future.wait([
      _storage.read(key: StorageKeys.token),
      _storage.read(key: StorageKeys.role),
    ]);
    final token = results[0];
    final role = results[1];
    
    if (token != null && role != null) {
      _currentRole = role;
      
      final res = await fetchAndStoreProfile();
      final bool isValid = res['success'] == true;
      final int statusCode = res['statusCode'] is int ? res['statusCode'] as int : 0;
      final bool isAuthError = statusCode == 401 || statusCode == 403;

      if (isValid) {
        // Perfil obtenido correctamente — sesión válida
        _isLoggedIn = true;
        return true;
      } else if (isAuthError) {
        // Token expirado o sin permisos — cerrar sesión
        await logout();
        return false;
      } else {
        // Error de red o del servidor (500, timeout, etc.)
        // No cerrar sesión pero tampoco autenticar automáticamente
        await logout();
        return false;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>> fetchAndStoreProfile() async {
    _currentRole ??=
        (await _storage.read(key: StorageKeys.role))?.toLowerCase();
    if (_currentRole == 'cliente') {
      final res = await getPerfilCliente();
      if (res['success']) {
        currentUserProfile = res['data'];
      }
      return res;
    } else if (_currentRole == 'proveedor') {
      final res = await getPerfilProveedor();
      if (res['success']) {
        currentUserProfile = res['data'];
      }
      return res;
    }
    return {'success': true, 'statusCode': 200}; // Admin fallback
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // El login puede no necesitar token, pero lo enviamos por el cliente normal
      // o usamos http sin interceptor si queremos asegurarnos. El interceptor es seguro.
      final response = await _apiClient.postRequest('/Auth/login', {
        'correo': email,
        'contrasena': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['accessToken'] != null) {
          final accessToken = data['accessToken']?.toString() ?? '';
          await _storage.write(key: StorageKeys.token, value: accessToken);
          
          final roleStr = data['role']?.toString().toLowerCase() ?? 'cliente';
          await _storage.write(key: StorageKeys.role, value: roleStr);

          final payload = parseJwt(accessToken);
          final userId = payload['nameid']?.toString();
          if (userId != null && userId.isNotEmpty) {
            await _storage.write(key: StorageKeys.userId, value: userId);
          }
          
          if (data['rolesDisponibles'] is List) {
            rolesDisponibles = List<String>.from(data['rolesDisponibles']);
          }

          _isLoggedIn = true;
          _currentRole = roleStr;
          
          await fetchAndStoreProfile();
          
          return {'success': true, 'role': roleStr};
        }
      }
      return {'success': false, 'message': _parseError(response.body)};
    } catch (e) {
      return {'success': false, 'message': 'Falló la conexión al servidor: $e'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.postRequest('/Auth/register', userData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false, 'message': _parseError(response.body)};
    } catch (e) {
      return {'success': false, 'message': 'Ocurrió un error al registrar: $e'};
    }
  }

  Future<Map<String, dynamic>> switchRole(String targetRole) async {
    try {
      final response =
          await _apiClient.postRequest('/Auth/switch-role', targetRole.toLowerCase());

      // Parsear SIEMPRE el body como JSON independientemente del statusCode
      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is String) {
          data = {'message': decoded};
        }
      } catch (e) {
        data = {'message': response.body};
      }

      // ── CASO ÉXITO: success == true o status 200 ────────────────────────────
      if ((data['success'] == true || response.statusCode == 200) && data.containsKey('token')) {
        final String? newToken = data['token']?.toString();
        final String? newActiveRole = data['activeRole']?.toString();

        if (newToken == null || newToken.isEmpty) {
          return {
            'success': false,
            'message': 'El servidor no devolvió un token válido tras el cambio',
          };
        }

        // Reemplazar tokens
        await _storage.delete(key: StorageKeys.token);
        await _storage.write(key: StorageKeys.token, value: newToken);

        final payload = parseJwt(newToken);
        final userId = payload['nameid']?.toString();
        if (userId != null && userId.isNotEmpty) {
          await _storage.write(key: StorageKeys.userId, value: userId);
        }

        final String finalRole = newActiveRole != null
            ? newActiveRole.toLowerCase()
            : targetRole.toLowerCase();
        await _storage.write(key: StorageKeys.role, value: finalRole);
        _currentRole = finalRole;

        if (data['rolesDisponibles'] is List) {
          rolesDisponibles = List<String>.from(data['rolesDisponibles']);
        }

        // Sincronizar perfil en memoria con el nuevo rol
        await fetchAndStoreProfile();

        return {
          'success': true,
          'role': _currentRole,
          'rolesDisponibles': rolesDisponibles,
          'message': data['message'] ?? 'Cambio de rol exitoso',
        };
      }

      // ── CASO FALLO ──────────────────────────────────────────────────────────
      final String errorMessage = data['message'] ?? data['error'] ?? 'No tienes permisos para activar este rol.';
      
      // Decidir si mostrar el formulario basado en el mensaje o roles disponibles
      final List<String> rolesDisp = data['rolesDisponibles'] is List
          ? List<String>.from(data['rolesDisponibles'])
          : rolesDisponibles;

      final bool tieneRolProveedor = rolesDisp.any((r) => r.toLowerCase() == 'proveedor');

      bool needsApplication = errorMessage
              .toLowerCase()
              .contains('debes completar tu registro de proveedor primero') ||
          response.statusCode == 403;

      if (!needsApplication && !tieneRolProveedor) {
        needsApplication = true;
      }

      return {
        'success': false,
        'requiresProviderApplication': needsApplication,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'requiresProviderApplication': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  int? _tryParseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return {};
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    try {
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      return json is Map<String, dynamic> ? json : {};
    } catch (e) {
      debugPrint('[AuthService] JWT parse error: $e');
      return {};
    }
  }

  Future<void> _persistTokenFromResponse(http.Response response) async {
    String? token;

    final authHeader = response.headers['authorization'] ??
        response.headers['Authorization'];
    if (authHeader != null && authHeader.trim().isNotEmpty) {
      final v = authHeader.trim();
      if (v.toLowerCase().startsWith('bearer ')) {
        token = v.substring(7).trim();
      } else {
        token = v;
      }
    }

    if (token == null || token.isEmpty) {
      final raw = response.body.trim();
      if (raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          dynamic body = decoded;
          if (decoded is Map &&
              (decoded.containsKey('Data') || decoded.containsKey('data'))) {
            body = decoded['Data'] ?? decoded['data'];
          }
          if (body is Map) {
            token = (body['accessToken'] ??
                    body['AccessToken'] ??
                    body['token'] ??
                    body['Token'])
                ?.toString();
          }
        } catch (_) {}
      }
    }

    final t = token?.trim();
    if (t == null || t.isEmpty) return;

    await _storage.write(key: StorageKeys.token, value: t);

    final payload = parseJwt(t);
    final userId = payload['nameid']?.toString() ??
        payload['NameId']?.toString() ??
        payload['sub']?.toString();
    if (userId != null && userId.isNotEmpty) {
      await _storage.write(key: StorageKeys.userId, value: userId);
    }
  }

  Future<int?> getCurrentProveedorId() async {
    final storedUserId = await _storage.read(key: StorageKeys.userId);
    final storedParsed = _tryParseInt(storedUserId);
    if (storedParsed != null) return storedParsed;

    final data = currentUserProfile;
    if (data is Map<String, dynamic>) {
      final direct = _tryParseInt(
        data['Id'] ??
            data['id'] ??
            data['ProveedorId'] ??
            data['proveedorId'] ??
            data['idProveedor'] ??
            data['id_proveedor'],
      );
      if (direct != null) return direct;

      final nested = data['proveedor'] ?? data['Proveedor'];
      if (nested is Map<String, dynamic>) {
        final nestedId = _tryParseInt(nested['Id'] ?? nested['id'] ?? nested['proveedorId']);
        if (nestedId != null) return nestedId;
      }
    }

    final token = await _storage.read(key: StorageKeys.token);
    if (token == null || token.isEmpty) return null;
    final payload = parseJwt(token);
    final claim = _tryParseInt(payload['nameid'] ?? payload['NameId'] ?? payload['sub']);
    return claim;
  }

  Future<int?> getCurrentClienteId() async {
    final storedUserId = await _storage.read(key: StorageKeys.userId);
    final storedParsed = _tryParseInt(storedUserId);
    if (storedParsed != null) return storedParsed;

    final data = currentUserProfile;
    if (data is Map<String, dynamic>) {
      final direct = _tryParseInt(
        data['Id'] ??
            data['id'] ??
            data['ClienteId'] ??
            data['clienteId'] ??
            data['idCliente'] ??
            data['id_cliente'],
      );
      if (direct != null) return direct;

      final nested = data['cliente'] ?? data['Cliente'];
      if (nested is Map<String, dynamic>) {
        final nestedId = _tryParseInt(nested['Id'] ?? nested['id'] ?? nested['clienteId']);
        if (nestedId != null) return nestedId;
      }
    }

    final token = await _storage.read(key: StorageKeys.token);
    if (token == null || token.isEmpty) return null;
    final payload = parseJwt(token);
    final claim = _tryParseInt(payload['nameid'] ?? payload['NameId'] ?? payload['sub']);
    return claim;
  }

  // Profile Endpoints
  Future<Map<String, dynamic>> getPerfilCliente() async {
    try {
      final response = await _apiClient.getRequest('/perfil/cliente');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Extraer Data si viene envuelto, sino usar el objeto directo
        final data = (decoded is Map && (decoded.containsKey('Data') || decoded.containsKey('data')))
            ? (decoded['Data'] ?? decoded['data'])
            : decoded;
        return {'success': true, 'data': data};
      }
      return {'success': false, 'statusCode': response.statusCode, 'message': 'Error obteniendo perfil: ${response.statusCode}'};
    } catch(e) {
      return {'success': false, 'statusCode': 0, 'message': 'Sin red o error interno'};
    }
  }

  Future<Map<String, dynamic>> getPerfilProveedor() async {
    try {
      final response = await _apiClient.getRequest('/perfil/proveedor');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Extraer Data si viene envuelto, sino usar el objeto directo
        final data = (decoded is Map && (decoded.containsKey('Data') || decoded.containsKey('data')))
            ? (decoded['Data'] ?? decoded['data'])
            : decoded;
        return {'success': true, 'data': data};
      }
      return {'success': false, 'statusCode': response.statusCode, 'message': 'Error obteniendo perfil: ${response.statusCode}'};
    } catch(e) {
      return {'success': false, 'statusCode': 0, 'message': 'Sin red o error interno'};
    }
  }

  Future<Map<String, dynamic>> updatePerfilCliente(Map<String, dynamic> data) async {
    try {
      // Remover valores nulos o claves vacías para no romper la deserialización del backend
      final cleanedData = Map<String, dynamic>.from(data)
        ..removeWhere((key, value) => value == null || key.isEmpty);
        
      final response = await _apiClient.patchRequest('/perfil/cliente', cleanedData);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _persistTokenFromResponse(response);
        await fetchAndStoreProfile();
        return {'success': true};
      }
      
      // Solo en caso de error 401 real de autenticación (no un error de negocio),
      // dejamos que el ApiClient maneje el logout o devolvemos el error.
      // El ApiClient ya maneja el 401 expirado.
      return {
        'success': false, 
        'statusCode': response.statusCode,
        'message': _parseError(response.body)
      };
    } catch(e) {
      return {'success': false, 'message': 'Error al actualizar perfil: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePerfilProveedor(Map<String, dynamic> data) async {
    try {
      // Remover nulos
      final cleanedData = Map<String, dynamic>.from(data)
        ..removeWhere((key, value) => value == null || key.isEmpty);

      final response = await _apiClient.patchRequest('/perfil/proveedor', cleanedData);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _persistTokenFromResponse(response);
        await fetchAndStoreProfile();
        return {'success': true};
      }
      
      return {
        'success': false, 
        'statusCode': response.statusCode,
        'message': _parseError(response.body)
      };
    } catch(e) {
      return {'success': false, 'message': 'Error al actualizar perfil: $e'};
    }
  }

  // Enviar Solicitud Proveedor (Multipart) - Cross Platform
  Future<Map<String, dynamic>> enviarSolicitudProveedor({
    required String descripcion, 
    required String experiencia, 
    required List<PlatformFile> files
  }) async {
    try {
      final uri = Uri.parse('${_apiClient.baseUrl}/Solicitud/Enviar_Solicitud');
      final request = http.MultipartRequest('POST', uri);

      final token = await _storage.read(key: StorageKeys.token);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.fields['DescripcionPerfil'] = descripcion;
      request.fields['AnosExperiencia'] = experiencia;

      for (var file in files) {
        if (kIsWeb) {
          // En Web usamos los bytes directamente
          if (file.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes(
              'Documentos', 
              file.bytes!, 
              filename: file.name
            ));
          }
        } else {
          // En móvil usamos el path
          if (file.path != null) {
            request.files.add(await http.MultipartFile.fromPath('Documentos', file.path!));
          }
        }
      }

      final streamedResponse = await _apiClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false, 'message': _parseError(response.body)};
    } catch (e) {
      return {'success': false, 'message': 'Error al enviar solicitud: $e'};
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.token);
    await _storage.delete(key: StorageKeys.role);
    await _storage.delete(key: StorageKeys.userId);
    _isLoggedIn = false;
    _currentRole = null;
    currentUserProfile = null;
  }

  // ── Gestión Administrativa ──────────────────────────────────────────
  
  Future<Map<String, dynamic>> getAllUsuarios() async {
    try {
      final response = await _apiClient.getRequest('/admin/usuarios');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = (decoded is Map && (decoded.containsKey('Data') || decoded.containsKey('data')))
            ? (decoded['Data'] ?? decoded['data'])
            : decoded;
        if (data is Map) {
          // If it's a map with another key, try to extract the first list
          for (var value in data.values) {
            if (value is List) return {'success': true, 'data': value};
          }
        }
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': _parseError(response.body)};
    } catch (e) {
      debugPrint("Error en getAllUsuarios: $e");
      return {'success': false, 'message': 'Error de red'};
    }
  }

  Future<Map<String, dynamic>> getSolicitudesProveedor() async {
    try {
      final response = await _apiClient.getRequest('/Solicitud/listar-solicitudes');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = (decoded is Map && (decoded.containsKey('Data') || decoded.containsKey('data')))
            ? (decoded['Data'] ?? decoded['data'])
            : decoded;
        if (data is Map) {
          for (var value in data.values) {
            if (value is List) return {'success': true, 'data': value};
          }
        }
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': _parseError(response.body)};
    } catch (e) {
      debugPrint("Error en getSolicitudesProveedor: $e");
      return {'success': false, 'message': 'Error de red'};
    }
  }

  Future<Map<String, dynamic>> procesarSolicitudProveedor(int solicitudId, bool aprobado) async {
    try {
      final String action = aprobado ? "Aprobada" : "Rechazada";
      final response = await _apiClient.patchRequest('/Solicitud/Gestionar_solicitudes/$solicitudId', action);
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Solicitud $action correctamente'};
      }
      return {'success': false, 'message': _parseError(response.body)};
    } catch (e) {
      return {'success': false, 'message': 'Error de red'};
    }
  }

  Future<Map<String, dynamic>> actualizarEstadoProveedor(int proveedorId, String nuevoEstado) async {
    // nuevoEstado debe ser "activo", "inactivo" o "bloqueado" según requerimiento.
    try {
      final response = await _apiClient.putRequest('/admin/proveedores/$proveedorId/estado', nuevoEstado.toLowerCase());
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Estado actualizado a $nuevoEstado'};
      }
      return {'success': false, 'message': _parseError(response.body)};
    } catch (e) {
      return {'success': false, 'message': 'Error de red'};
    }
  }

  Future<Map<String, dynamic>> getProveedoresVerificados() async {
    try {
      final response = await _apiClient.getRequest('/admin/proveedores/Lista-de-Proveedores');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = (decoded is Map && (decoded.containsKey('Data') || decoded.containsKey('data')))
            ? (decoded['Data'] ?? decoded['data'])
            : decoded;
        if (data is Map) {
          for (var value in data.values) {
            if (value is List) return {'success': true, 'data': value};
          }
        }
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': _parseError(response.body)};
    } catch (e) {
      debugPrint("Error en getProveedoresVerificados: $e");
      return {'success': false, 'message': 'Error de red'};
    }
  }

  Future<Map<String, dynamic>> suspenderUsuario(int usuarioId) async {
    // Implementación real pendiente de endpoint admin usuarios estado
    return {'success': false, 'message': 'Funcionalidad en desarrollo'};
  }

  Future<Map<String, dynamic>> eliminarUsuario(int usuarioId) async {
    return {'success': false, 'message': 'Funcionalidad en desarrollo'};
  }

  String _parseError(String body) {
    if (body.isEmpty) return 'Error desconocido en el servidor';
    
    try {
      final decoded = jsonDecode(body);
      
      // Caso 1: Estructura { "message": "..." } o { "error": "..." }
      if (decoded is Map) {
        if (decoded.containsKey('message')) return decoded['message'].toString();
        if (decoded.containsKey('error')) return decoded['error'].toString();
        if (decoded.containsKey('title')) return decoded['title'].toString();
        
        // Caso 2: Estructura { "errors": { "field": ["err1", "err2"] } } (.NET ValidationErrors)
        if (decoded.containsKey('errors') && decoded['errors'] is Map) {
          final Map<String, dynamic> errors = decoded['errors'];
          if (errors.isNotEmpty) {
            final firstErrorEntry = errors.values.first;
            if (firstErrorEntry is List && firstErrorEntry.isNotEmpty) {
              return firstErrorEntry.first.toString();
            }
            return firstErrorEntry.toString();
          }
        }
      }
      
      // Caso 3: Es un string simple
      if (decoded is String) return decoded;
      
      return 'Error del servidor (formato no reconocido)';
    } catch (_) {
      // Si no es JSON, devolvemos el body tal cual si no es muy largo, o un genérico
      if (body.length < 100) return body;
      return 'Error desconocido en el servidor';
    }
  }
}
