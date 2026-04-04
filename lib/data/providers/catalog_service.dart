import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:servizone_app/core/network/api_client.dart';
import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/models/catalog/categoria_model.dart';
import 'package:servizone_app/data/models/catalog/subcategoria_model.dart';
import 'package:servizone_app/data/models/catalog/tipo_servicio_model.dart';
import 'package:servizone_app/data/models/catalog/servicio_proveedor_model.dart';

/// Capa de datos del catálogo — única responsable de:
///   1. Ejecutar la petición HTTP (token adjunto por ApiClient.send)
///   2. Parsear el envelope { Success, Data, Message } — PascalCase obligatorio
///   3. Retornar ApiResult<T> tipado — nunca Map<String, dynamic> a la UI
class CatalogService {
  final ApiClient _client;

  CatalogService(this._client);

  // ════════════════════════════════════════════════════════════
  // CATEGORÍAS
  // ════════════════════════════════════════════════════════════

  Future<ApiResult<List<Categoria>>> getCategorias() => _safeCallList(
        label: 'getCategorias',
        call: () => _client.getRequest('/categorias'),
        fromItem: (e) => Categoria.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<Categoria>> getCategoria(int id) => _safeCallSingle(
        label: 'getCategoria($id)',
        call: () => _client.getRequest('/categorias/$id'),
        fromItem: (e) => Categoria.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<Categoria>> createCategoria({
    required String nombre,
    String? descripcion,
  }) =>
      _safeCallSingle(
        label: 'createCategoria',
        call: () => _client.postRequest('/categorias', {
          'Nombre': nombre,
          if (descripcion != null && descripcion.isNotEmpty)
            'Descripcion': descripcion,
        }),
        fromItem: (e) => Categoria.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<Categoria>> updateCategoria(
    int id, {
    required String nombre,
    String? descripcion,
  }) =>
      _safeCallSingle(
        label: 'updateCategoria($id)',
        call: () => _client.patchRequest('/categorias/$id', {
          'Nombre': nombre,
          if (descripcion != null && descripcion.isNotEmpty)
            'Descripcion': descripcion,
        }),
        fromItem: (e) => Categoria.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<void>> deleteCategoria(int id) => _safeCallVoid(
        label: 'deleteCategoria($id)',
        call: () => _client.deleteRequest('/categorias/$id'),
      );

  // ════════════════════════════════════════════════════════════
  // SUBCATEGORÍAS
  // ════════════════════════════════════════════════════════════

  /// Obtiene todas las subcategorías del sistema (para listas admin).
  Future<ApiResult<List<Subcategoria>>> getSubcategorias() => _safeCallList(
        label: 'getSubcategorias',
        call: () => _client.getRequest('/subcategorias'),
        fromItem: (e) => Subcategoria.fromJson(e as Map<String, dynamic>),
      );

  /// Obtiene subcategorías filtradas por categoría (para navegación cliente).
  Future<ApiResult<List<Subcategoria>>> getSubcategoriasPorCategoria(
          int categoriaId) =>
      _safeCallList(
        label: 'getSubcategorias(categoriaId=$categoriaId)',
        call: () =>
            _client.getRequest('/subcategorias?categoriaId=$categoriaId'),
        fromItem: (e) => Subcategoria.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<Subcategoria>> getSubcategoria(int id) => _safeCallSingle(
        label: 'getSubcategoria($id)',
        call: () => _client.getRequest('/subcategorias/$id'),
        fromItem: (e) => Subcategoria.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<Subcategoria>> createSubcategoria({
    required String nombre,
    String? descripcion,
    required int categoriaId,
  }) =>
      _safeCallSingle(
        label: 'createSubcategoria',
        call: () => _client.postRequest('/subcategorias', {
          'Nombre': nombre,
          if (descripcion != null && descripcion.isNotEmpty)
            'Descripcion': descripcion,
          'CategoriaId': categoriaId,
        }),
        fromItem: (e) => Subcategoria.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<Subcategoria>> updateSubcategoria(
    int id, {
    required String nombre,
    String? descripcion,
    required int categoriaId,
  }) =>
      _safeCallSingle(
        label: 'updateSubcategoria($id)',
        call: () => _client.patchRequest('/subcategorias/$id', {
          'Nombre': nombre,
          if (descripcion != null && descripcion.isNotEmpty)
            'Descripcion': descripcion,
          'CategoriaId': categoriaId,
        }),
        fromItem: (e) => Subcategoria.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<void>> deleteSubcategoria(int id) => _safeCallVoid(
        label: 'deleteSubcategoria($id)',
        call: () => _client.deleteRequest('/subcategorias/$id'),
      );

  // ════════════════════════════════════════════════════════════
  // TIPOS DE SERVICIO
  // ════════════════════════════════════════════════════════════

  /// Obtiene todos los tipos de servicio del sistema (para listas admin).
  Future<ApiResult<List<TipoServicio>>> getTiposServicio() => _safeCallList(
        label: 'getTiposServicio',
        call: () => _client.getRequest('/tipos-servicio'),
        fromItem: (e) => TipoServicio.fromJson(e as Map<String, dynamic>),
      );

  /// Obtiene tipos de servicio filtrados por subcategoría (para navegación cliente).
  Future<ApiResult<List<TipoServicio>>> getTiposServicioPorSubcategoria(
          int subcategoriaId) =>
      _safeCallList(
        label: 'getTiposServicio(subcategoriaId=$subcategoriaId)',
        call: () => _client
            .getRequest('/tipos-servicio?subcategoriaId=$subcategoriaId'),
        fromItem: (e) => TipoServicio.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<TipoServicio>> getTipoServicio(int id) => _safeCallSingle(
        label: 'getTipoServicio($id)',
        call: () => _client.getRequest('/tipos-servicio/$id'),
        fromItem: (e) => TipoServicio.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<TipoServicio>> createTipoServicio({
    required String nombre,
    String? descripcion,
    required int subcategoriaId,
  }) =>
      _safeCallSingle(
        label: 'createTipoServicio',
        call: () => _client.postRequest('/tipos-servicio', {
          'Nombre': nombre,
          if (descripcion != null && descripcion.isNotEmpty)
            'Descripcion': descripcion,
          'SubcategoriaId': subcategoriaId,
        }),
        fromItem: (e) => TipoServicio.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<TipoServicio>> updateTipoServicio(
    int id, {
    required String nombre,
    String? descripcion,
    required int subcategoriaId,
  }) =>
      _safeCallSingle(
        label: 'updateTipoServicio($id)',
        call: () => _client.patchRequest('/tipos-servicio/$id', {
          'Nombre': nombre,
          if (descripcion != null && descripcion.isNotEmpty)
            'Descripcion': descripcion,
          'SubcategoriaId': subcategoriaId,
        }),
        fromItem: (e) => TipoServicio.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<void>> deleteTipoServicio(int id) => _safeCallVoid(
        label: 'deleteTipoServicio($id)',
        call: () => _client.deleteRequest('/tipos-servicio/$id'),
      );

  // ════════════════════════════════════════════════════════════
  // SERVICIOS DE PROVEEDOR
  // ════════════════════════════════════════════════════════════

  /// Obtiene todos los servicios del sistema (sin filtro).
  Future<ApiResult<List<ServicioProveedor>>> getAllServiciosProveedor() =>
      _safeCallList(
        label: 'getAllServiciosProveedor',
        call: () => _client.getRequest('/servicios-proveedor'),
        fromItem: (e) =>
            ServicioProveedor.fromJson(e as Map<String, dynamic>),
      );

  /// Obtiene servicios filtrados por tipo de servicio (navegación cliente).
  Future<ApiResult<List<ServicioProveedor>>> getServiciosPorTipoServicio(
          int tipoServicioId) =>
      _safeCallList(
        label: 'getServiciosPorTipoServicio($tipoServicioId)',
        call: () =>
            _client.getRequest('/servicios-proveedor?tipoServicioId=$tipoServicioId'),
        fromItem: (e) => ServicioProveedor.fromJson(e as Map<String, dynamic>),
      );

  /// Obtiene servicios del proveedor autenticado, filtrado por su proveedorId.
  Future<ApiResult<List<ServicioProveedor>>> getServiciosDelProveedor(
          int proveedorId) =>
      getMisServicios();

  Future<ApiResult<List<ServicioProveedor>>> buscarServiciosProveedor(
          String busqueda) =>
      _safeCallList(
        label: 'buscarServiciosProveedor',
        call: () => _client.getRequest(
          '/servicios-proveedor?${Uri(queryParameters: {'busqueda': busqueda}).query}',
        ),
        fromItem: (e) => ServicioProveedor.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<List<ServicioProveedor>>> getMisServicios() => _safeCallList(
        label: 'getMisServicios',
        call: () => _client.getRequest('/servicios-proveedor/mis-servicios'),
        fromItem: (e) => ServicioProveedor.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<ServicioProveedor>> getServicioProveedor(int id) =>
      _safeCallSingle(
        label: 'getServicioProveedor($id)',
        call: () => _client.getRequest('/servicios-proveedor/$id'),
        fromItem: (e) =>
            ServicioProveedor.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<ServicioProveedor>> createServicioProveedor({
    required int tipoServicioId,
    required int proveedorId,
    required double precioBase,
    required bool estado,
    String? descripcion,
  }) =>
      _safeCallSingle(
        label: 'createServicioProveedor',
        call: () {
          final body = <String, dynamic>{
            'TipoServicioId': tipoServicioId,
            'ProveedorId': proveedorId,
            'PrecioBase': precioBase,
            'Estado': estado,
          };
          final d = descripcion?.trim();
          if (d != null && d.isNotEmpty) body['Descripcion'] = d;
          return _client.postRequest('/servicios-proveedor', body);
        },
        fromItem: (e) =>
            ServicioProveedor.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<ServicioProveedor>> createMisServicioProveedor({
    required int tipoServicioId,
    required double precioBase,
    required bool estado,
    String? descripcion,
  }) =>
      _safeCallSingle(
        label: 'createMisServicioProveedor',
        call: () {
          final body = <String, dynamic>{
            'TipoServicioId': tipoServicioId,
            'PrecioBase': precioBase,
            'Estado': estado,
            'EstaActivo': estado,
          };
          final d = descripcion?.trim();
          if (d != null && d.isNotEmpty) body['Descripcion'] = d;
          return _client.postRequest('/servicios-proveedor/mis-servicios', body);
        },
        fromItem: (e) => ServicioProveedor.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<ServicioProveedor>> updateServicioProveedor(
    int id, {
    required int tipoServicioId,
    required int proveedorId,
    required double precioBase,
    required bool estado,
    String? descripcion,
  }) =>
      _safeCallSingle(
        label: 'updateServicioProveedor($id)',
        call: () {
          final body = <String, dynamic>{
            'TipoServicioId': tipoServicioId,
            'ProveedorId': proveedorId,
            'PrecioBase': precioBase,
            'Estado': estado,
          };
          final d = descripcion?.trim();
          if (d != null && d.isNotEmpty) body['Descripcion'] = d;
          return _client.patchRequest('/servicios-proveedor/$id', body);
        },
        fromItem: (e) =>
            ServicioProveedor.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<ServicioProveedor>> updateMisServicioProveedor(
    int id, {
    required int tipoServicioId,
    required double precioBase,
    required bool estado,
    String? descripcion,
  }) =>
      _safeCallSingle(
        label: 'updateMisServicioProveedor($id)',
        call: () {
          final body = <String, dynamic>{
            'TipoServicioId': tipoServicioId,
            'PrecioBase': precioBase,
            'Estado': estado,
            'EstaActivo': estado,
          };
          final d = descripcion?.trim();
          if (d != null && d.isNotEmpty) body['Descripcion'] = d;
          return _client.patchRequest(
              '/servicios-proveedor/mis-servicios/$id', body);
        },
        fromItem: (e) => ServicioProveedor.fromJson(e as Map<String, dynamic>),
      );

  Future<ApiResult<void>> deleteServicioProveedor(int id) => _safeCallVoid(
        label: 'deleteServicioProveedor($id)',
        call: () => _client.deleteRequest('/servicios-proveedor/$id'),
      );

  Future<ApiResult<void>> deleteMisServicioProveedor(int id) => _safeCallVoid(
        label: 'deleteMisServicioProveedor($id)',
        call: () => _client.deleteRequest('/servicios-proveedor/mis-servicios/$id'),
      );

  // ════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ════════════════════════════════════════════════════════════

  /// Lista de items tipados.
  Future<ApiResult<List<T>>> _safeCallList<T>({
    required String label,
    required Future<http.Response> Function() call,
    required T Function(dynamic item) fromItem,
  }) async {
    try {
      final response = await call();
      return _parseEnvelopeList<T>(response, fromItem);
    } catch (e, st) {
      if (e.toString().contains('SocketException')) {
        return ApiResult.failure(
            message: 'Sin conexión a Internet. Verifica tu red.');
      }
      debugPrint('[CatalogService.$label] Error inesperado: $e\n$st');
      return ApiResult.failure(message: 'Error inesperado. Intenta de nuevo.');
    }
  }

  /// Un solo objeto tipado (POST/PUT/GET by ID).
  Future<ApiResult<T>> _safeCallSingle<T>({
    required String label,
    required Future<http.Response> Function() call,
    required T Function(dynamic item) fromItem,
  }) async {
    try {
      final response = await call();
      return _parseEnvelopeSingle<T>(response, fromItem);
    } catch (e, st) {
      if (e.toString().contains('SocketException')) {
        return ApiResult.failure(
            message: 'Sin conexión a Internet. Verifica tu red.');
      }
      debugPrint('[CatalogService.$label] Error inesperado: $e\n$st');
      return ApiResult.failure(message: 'Error inesperado. Intenta de nuevo.');
    }
  }

  /// Sin datos en la respuesta (DELETE).
  Future<ApiResult<void>> _safeCallVoid({
    required String label,
    required Future<http.Response> Function() call,
  }) async {
    try {
      final response = await call();
      return _parseEnvelopeVoid(response);
    } catch (e, st) {
      if (e.toString().contains('SocketException')) {
        return ApiResult.failure(
            message: 'Sin conexión a Internet. Verifica tu red.');
      }
      debugPrint('[CatalogService.$label] Error inesperado: $e\n$st');
      return ApiResult.failure(message: 'Error inesperado. Intenta de nuevo.');
    }
  }

  // ── Parsers de envelope ──────────────────────────────────────────────

  /// Decodifica body respetando UTF-8 y eliminando BOM.
  String _decodeBody(http.Response response) {
    String body;
    try {
      body = utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (_) {
      body = response.body;
    }
    body = body.trim();
    if (body.startsWith('\uFEFF')) body = body.substring(1).trim();
    return body;
  }

  Map<String, dynamic>? _decodeEnvelope(
      String body, int sc, String label) {
    if (body.isEmpty) {
      if (kDebugMode) {
        debugPrint('[CatalogService.$label] body vacío (sc=$sc)');
      }
      return null;
    }
    try {
      final decoded = jsonDecode(body);
      
      // Si es un Map, lo devolvemos tal cual (puede ser un envelope o un objeto directo)
      if (decoded is Map<String, dynamic>) {
        // Si no tiene estructura de envelope, lo envolvemos para compatibilidad
        if (!decoded.containsKey('Success') && !decoded.containsKey('success') &&
            !decoded.containsKey('Data') && !decoded.containsKey('data')) {
          return {
            'Success': true,
            'Data': decoded,
            'Message': ''
          };
        }
        return decoded;
      }
      
      // Si es una List, la envolvemos en un envelope sintético
      if (decoded is List) {
        return {
          'Success': true,
          'Data': decoded,
          'Message': ''
        };
      }
      
      if (kDebugMode) {
        debugPrint('[CatalogService.$label] Tipo inesperado: ${decoded.runtimeType}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CatalogService.$label] jsonDecode error: $e');
      }
      if (sc >= 400) {
        return {
          'Success': false,
          'Data': null,
          'Message': _fallbackMessage(sc),
        };
      }
      return null;
    }
  }

  ApiResult<List<T>> _parseEnvelopeList<T>(
    http.Response response,
    T Function(dynamic item) fromItem,
  ) {
    final int sc = response.statusCode;
    final body = _decodeBody(response);
    if (kDebugMode) {
      debugPrint('[CatalogService] sc=$sc | body(${body.length}): '
          '${body.length > 200 ? body.substring(0, 200) : body}');
    }

    if (sc == 401) {
      return ApiResult.failure(
          message: 'Sesión expirada. Inicia sesión nuevamente.',
          statusCode: sc);
    }
    if (sc == 403) {
      return ApiResult.failure(
          message: 'No tienes permisos para acceder a este recurso.',
          statusCode: sc);
    }

    if (sc >= 200 && sc < 300 && body.isEmpty) {
      return ApiResult.success(data: <T>[], statusCode: sc);
    }

    final envelope = _decodeEnvelope(body, sc, 'list');
    if (envelope == null) {
      return ApiResult.failure(
          message: 'No se pudo interpretar la respuesta del servidor.',
          statusCode: sc);
    }

    final bool success =
        envelope['Success'] == true || envelope['success'] == true;
    final String message =
        ((envelope['Message'] ?? envelope['message']) as String?) ?? '';

    if (!success) {
      return ApiResult.failure(
          message: message.isNotEmpty ? message : _fallbackMessage(sc),
          statusCode: sc);
    }

    final dynamic rawData = envelope['Data'] ?? envelope['data'];
    if (rawData == null) {
      return ApiResult.success(data: <T>[], statusCode: sc);
    }

    if (rawData is! List) {
      if (rawData is Map<String, dynamic>) {
        try {
          return ApiResult.success(
              data: [fromItem(rawData)], statusCode: sc);
        } catch (e) {
          debugPrint('[CatalogService] rawData no es lista ni item válido: $e');
        }
      }
      return ApiResult.failure(
          message: 'Los datos recibidos no tienen el formato esperado.',
          statusCode: sc);
    }

    try {
      return ApiResult.success(
          data: rawData.map<T>(fromItem).toList(),
          message: message,
          statusCode: sc);
    } catch (e, st) {
      debugPrint('[CatalogService] Deserialización fallida: $e\n$st');
      return ApiResult.failure(
          message: 'Error al procesar los datos del servidor.',
          statusCode: sc);
    }
  }

  ApiResult<T> _parseEnvelopeSingle<T>(
    http.Response response,
    T Function(dynamic item) fromItem,
  ) {
    final int sc = response.statusCode;
    final body = _decodeBody(response);
    if (kDebugMode) {
      debugPrint('[CatalogService] sc=$sc | body(${body.length}): '
          '${body.length > 200 ? body.substring(0, 200) : body}');
    }

    if (sc == 401) {
      return ApiResult.failure(
          message: 'Sesión expirada. Inicia sesión nuevamente.',
          statusCode: sc);
    }
    if (sc == 403) {
      return ApiResult.failure(
          message: 'No tienes permisos para acceder a este recurso.',
          statusCode: sc);
    }

    final envelope = _decodeEnvelope(body, sc, 'single');
    if (envelope == null) {
      return ApiResult.failure(
          message: 'No se pudo interpretar la respuesta del servidor.',
          statusCode: sc);
    }

    final bool success =
        envelope['Success'] == true || envelope['success'] == true;
    final String message =
        ((envelope['Message'] ?? envelope['message']) as String?) ?? '';

    if (!success) {
      return ApiResult.failure(
          message: message.isNotEmpty ? message : _fallbackMessage(sc),
          statusCode: sc);
    }

    final dynamic rawData = envelope['Data'] ?? envelope['data'];
    if (rawData == null) {
      return ApiResult.failure(
          message: 'El servidor no devolvió datos.',
          statusCode: sc);
    }

    try {
      return ApiResult.success(
          data: fromItem(rawData), message: message, statusCode: sc);
    } catch (e, st) {
      debugPrint('[CatalogService] Deserialización single fallida: $e\n$st');
      return ApiResult.failure(
          message: 'Error al procesar los datos del servidor.',
          statusCode: sc);
    }
  }

  ApiResult<void> _parseEnvelopeVoid(http.Response response) {
    final int sc = response.statusCode;
    final body = _decodeBody(response);
    if (kDebugMode) {
      debugPrint('[CatalogService] DELETE sc=$sc');
    }

    if (sc == 401) {
      return ApiResult.failure(
          message: 'Sesión expirada. Inicia sesión nuevamente.',
          statusCode: sc);
    }
    if (sc == 403) {
      return ApiResult.failure(
          message: 'No tienes permisos para eliminar este recurso.',
          statusCode: sc);
    }

    // 204 No Content → éxito sin body
    if (sc == 204) return ApiResult.success(data: null, statusCode: sc);

    if (body.isEmpty) {
      return sc >= 200 && sc < 300
          ? ApiResult.success(data: null, statusCode: sc)
          : ApiResult.failure(
              message: _fallbackMessage(sc), statusCode: sc);
    }

    final envelope = _decodeEnvelope(body, sc, 'void');
    if (envelope == null) {
      return sc >= 200 && sc < 300
          ? ApiResult.success(data: null, statusCode: sc)
          : ApiResult.failure(
              message: 'Error al procesar la respuesta.', statusCode: sc);
    }

    final bool success =
        envelope['Success'] == true || envelope['success'] == true;
    final String message =
        ((envelope['Message'] ?? envelope['message']) as String?) ?? '';

    return success
        ? ApiResult.success(data: null, message: message, statusCode: sc)
        : ApiResult.failure(
            message: message.isNotEmpty ? message : _fallbackMessage(sc),
            statusCode: sc);
  }

  String _fallbackMessage(int sc) {
    if (sc == 400) return 'Solicitud incorrecta. Verifica los datos enviados.';
    if (sc == 404) return 'El recurso solicitado no fue encontrado.';
    if (sc == 409) return 'Conflicto: el elemento ya existe o tiene dependencias.';
    if (sc >= 500) return 'Error interno del servidor. Intenta más tarde.';
    return 'Error desconocido (código $sc).';
  }
}
