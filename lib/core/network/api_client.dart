import 'dart:convert';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:servizone_app/core/constants/app_constants.dart';

class ApiClient extends http.BaseClient {
  final String baseUrl;
  final http.Client _inner;
  final FlutterSecureStorage _storage;

  ApiClient({
    required this.baseUrl,
    http.Client? inner,
    FlutterSecureStorage? storage,
  })  : _inner = inner ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  // Callbacks globales para manejar errores comunes a nivel de app
  Function()? onSessionExpired;
  Function(String)? onForbidden;
  Function()? onTooManyRequests;
  Function(String)? onServerError;

  Uri _buildUri(String endpoint) {
    final ep = endpoint.trim();
    if (baseUrl.trim().isEmpty) {
      throw Exception('BASE URL vacía');
    }
    if (ep.isEmpty) {
      throw Exception('Endpoint vacío');
    }
    final normalizedEndpoint = ep.startsWith('/') ? ep : '/$ep';
    final raw = '${baseUrl.trim()}$normalizedEndpoint';
    final uri = Uri.parse(raw);
    debugPrint('BASE URL: ${baseUrl.trim()}');
    debugPrint('ENDPOINT: $normalizedEndpoint');
    debugPrint('URL FINAL: $uri');
    return uri;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    int retryCount = 0;
    const int maxRetries = 3;
    final originalRequest = request;

    while (retryCount <= maxRetries) {
      try {
        final attemptRequest =
            retryCount == 0 ? originalRequest : _cloneRequest(originalRequest);

        final token = await _storage.read(key: StorageKeys.token);
        attemptRequest.headers['Accept'] = 'application/json';
        if (attemptRequest is! http.MultipartRequest) {
          attemptRequest.headers['Content-Type'] = 'application/json';
        }
        if (token != null && token.isNotEmpty) {
          attemptRequest.headers['Authorization'] = 'Bearer $token';
        }

        // 2. Enviar petición inicial con timeout extendido (cold start en Render)
        var response = await _inner.send(attemptRequest).timeout(
          const Duration(seconds: 90),
          onTimeout: () {
            if (kDebugMode) {
              debugPrint('==== TIMEOUT DETECTADO EN API CLIENT ====');
              debugPrint('URL: ${attemptRequest.url}');
            }
            throw http.ClientException('La conexión ha excedido el tiempo de espera (90s).');
          },
        );

        if (kDebugMode) {
          debugPrint('==== RESPUESTA RECIBIDA ====');
          debugPrint('Status: ${response.statusCode}');
        }

        // 3. Interceptar 401 Unauthorized
        if (response.statusCode == 401) {
          final path = attemptRequest.url.path.toLowerCase();
          final isAuthEndpoint = path.contains('/auth/login') ||
              path.contains('/auth/register');
          if (!path.contains('/perfil/') && !isAuthEndpoint) {
            await _clearSession();
            onSessionExpired?.call();
          }
          return response;
        } 
        // 4. Interceptar 403 Forbidden
        else if (response.statusCode == 403) {
          onForbidden?.call('No tienes permisos suficientes (403)');
        } 
        // 5. Interceptar 429 Too Many Requests
        else if (response.statusCode == 429) {
          onTooManyRequests?.call();
        }
        // 6. Interceptar 5xx Server Error
        else if (response.statusCode >= 500 && response.statusCode < 600) {
          onServerError?.call('Error del servidor (${response.statusCode})');
        }

        return response;
      } catch (e) {
        // En Web, SocketException no existe. Capturamos errores de red genéricos.
        retryCount++;
        if (kDebugMode) {
          debugPrint('==== ERROR DE RED/CONEXIÓN (Intento $retryCount/$maxRetries) ====');
          debugPrint('URL: ${originalRequest.url}');
          debugPrint('Error: $e');
        }

        if (retryCount > maxRetries) {
          if (kIsWeb) {
            throw Exception('Error de red. Verifica que el servidor sea accesible y que CORS esté habilitado.');
          } else {
            throw Exception('Sin conexión a Internet. Verifica que el dispositivo esté en la misma red Wi-Fi que el servidor ($baseUrl)');
          }
        }
        await Future.delayed(Duration(seconds: retryCount)); // Exponential backoff simple
      }
    }
    throw Exception('Error desconocido en el envío de la petición');
  }

  http.BaseRequest _cloneRequest(http.BaseRequest request) {
    if (request is http.Request) {
      final newReq = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
      return newReq;
    } else if (request is http.MultipartRequest) {
      final newReq = http.MultipartRequest(request.method, request.url)
        ..headers.addAll(request.headers)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
      return newReq;
    } else {
      throw UnimplementedError('Cloning not implemented for ${request.runtimeType}');
    }
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: StorageKeys.token);
    await _storage.delete(key: StorageKeys.role);
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }

  // Helpers HTTP
  Future<http.Response> getRequest(String endpoint) async {
    return await http.Response.fromStream(
      await send(http.Request('GET', _buildUri(endpoint)))
    );
  }

  Future<http.Response> postRequest(String endpoint, dynamic body) async {
    final req = http.Request('POST', _buildUri(endpoint))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);
    return await http.Response.fromStream(await send(req));
  }

  Future<http.Response> patchRequest(String endpoint, dynamic body) async {
    final req = http.Request('PATCH', _buildUri(endpoint))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);
    return await http.Response.fromStream(await send(req));
  }

  Future<http.Response> putRequest(String endpoint, dynamic body) async {
    final req = http.Request('PUT', _buildUri(endpoint))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);
    return await http.Response.fromStream(await send(req));
  }

  Future<http.Response> deleteRequest(String endpoint) async {
    final req = http.Request('DELETE', _buildUri(endpoint));
    return await http.Response.fromStream(await send(req));
  }
}
