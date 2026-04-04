import 'package:flutter/foundation.dart';
import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/models/catalog/categoria_model.dart';
import 'package:servizone_app/data/models/catalog/subcategoria_model.dart';
import 'package:servizone_app/data/models/catalog/tipo_servicio_model.dart';
import 'package:servizone_app/data/models/catalog/servicio_proveedor_model.dart';
import 'package:servizone_app/data/providers/catalog_service.dart';

enum CatalogLoadState { idle, loading, success, error }

/// Notifier que gestiona el estado del catálogo para toda la app.
///
/// Responsabilidades:
/// - Navegación cliente: categorías → subcategorías → tipos → servicios (con caché por ID)
/// - Listados admin: categorías, subcategorías y tipos SIN filtro (para dropdowns y gestión)
/// - Panel proveedor: servicios del proveedor autenticado (filtrados por proveedorId)
/// - CRUD completo para cada recurso con invalidación de caché y notificación reactiva
/// - Anti-duplicate, control de concurrencia, dispose-safe
class CatalogNotifier extends ChangeNotifier {
  final CatalogService _service;
  bool _disposed = false;

  CatalogNotifier(this._service);

  static const Duration _cacheTtl = Duration(seconds: 15);

  // ── Estado CRUD compartido ───────────────────────────────────────────
  bool isSubmitting = false;
  String lastOperationError = '';

  // ── Categorías (navegación cliente + admin) ──────────────────────────
  CatalogLoadState categoriasState = CatalogLoadState.idle;
  List<Categoria> categorias = const <Categoria>[];
  String categoriasError = '';
  bool _loadingCategorias = false;
  DateTime? _categoriasFetchedAt;

  // ── Subcategorías (navegación cliente, caché por categoriaId) ─────────
  CatalogLoadState subcategoriasState = CatalogLoadState.idle;
  List<Subcategoria> subcategorias = const <Subcategoria>[];
  String subcategoriasError = '';
  int? _loadedCategoriaId;
  DateTime? _subcategoriasFetchedAt;
  int _subcatGen = 0;

  // ── Todas las subcategorías (admin, sin filtro) ───────────────────────
  CatalogLoadState allSubcategoriasState = CatalogLoadState.idle;
  List<Subcategoria> allSubcategorias = const <Subcategoria>[];
  String allSubcategoriasError = '';

  // ── Tipos de Servicio (navegación cliente, caché por subcategoriaId) ──
  CatalogLoadState tiposState = CatalogLoadState.idle;
  List<TipoServicio> tipos = const <TipoServicio>[];
  String tiposError = '';
  int? _loadedSubcategoriaId;
  DateTime? _tiposFetchedAt;
  int _tiposGen = 0;

  // ── Todos los tipos de servicio (admin, sin filtro) ──────────────────
  CatalogLoadState allTiposState = CatalogLoadState.idle;
  List<TipoServicio> allTipos = const <TipoServicio>[];
  String allTiposError = '';

  // ── Todos los servicios del sistema (admin, sin filtro) ─────────────
  CatalogLoadState allServiciosState = CatalogLoadState.idle;
  List<ServicioProveedor> allServicios = const <ServicioProveedor>[];
  String allServiciosError = '';

  // ── Servicios (navegación cliente, caché por tipoServicioId) ─────────
  CatalogLoadState serviciosState = CatalogLoadState.idle;
  List<ServicioProveedor> servicios = const <ServicioProveedor>[];
  String serviciosError = '';
  int? _loadedTipoId;
  int _serviciosGen = 0;

  // ── Servicios del proveedor (panel proveedor) ─────────────────────────
  CatalogLoadState serviciosProveedorState = CatalogLoadState.idle;
  List<ServicioProveedor> serviciosProveedor = const <ServicioProveedor>[];
  String serviciosProveedorError = '';

  // ── Notificación segura ─────────────────────────────────────────────
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // CATEGORÍAS — LECTURA
  // ════════════════════════════════════════════════════════════

  Future<void> loadCategorias({bool forceRefresh = false}) async {
    if (_loadingCategorias) return;
    if (!forceRefresh &&
        categoriasState == CatalogLoadState.success &&
        categorias.isNotEmpty &&
        _categoriasFetchedAt != null &&
        DateTime.now().difference(_categoriasFetchedAt!) < _cacheTtl) {
      return;
    }
    _loadingCategorias = true;
    categoriasState = CatalogLoadState.loading;
    categoriasError = '';
    _safeNotify();

    final result = await _service.getCategorias();

    _loadingCategorias = false;
    if (!_disposed) {
      if (result.success && result.data != null) {
        categorias = result.data!;
        categoriasState = CatalogLoadState.success;
        _categoriasFetchedAt = DateTime.now();
      } else {
        categorias = const [];
        categoriasError = result.message;
        categoriasState = CatalogLoadState.error;
        _categoriasFetchedAt = null;
      }
      _safeNotify();
    }
  }

  Future<void> retryCategorias() async {
    _loadingCategorias = false;
    categoriasState = CatalogLoadState.idle;
    categorias = const [];
    categoriasError = '';
    _safeNotify();
    await loadCategorias();
  }

  // ════════════════════════════════════════════════════════════
  // SUBCATEGORÍAS — LECTURA (navegación cliente)
  // ════════════════════════════════════════════════════════════

  Future<void> loadSubcategorias(int categoriaId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _loadedCategoriaId == categoriaId &&
        subcategoriasState == CatalogLoadState.success &&
        _subcategoriasFetchedAt != null &&
        DateTime.now().difference(_subcategoriasFetchedAt!) < _cacheTtl) {
      return;
    }
    if (_loadedCategoriaId != categoriaId) {
      subcategorias = const [];
      subcategoriasState = CatalogLoadState.idle;
      _loadedCategoriaId = categoriaId;
      _subcategoriasFetchedAt = null;
    }
    final int thisGen = ++_subcatGen;
    subcategoriasState = CatalogLoadState.loading;
    subcategoriasError = '';
    _safeNotify();

    final result = await _service.getSubcategoriasPorCategoria(categoriaId);

    if (thisGen != _subcatGen || _disposed) return;
    if (result.success && result.data != null) {
      subcategorias = result.data!;
      subcategoriasState = CatalogLoadState.success;
      _subcategoriasFetchedAt = DateTime.now();
    } else {
      subcategorias = const [];
      subcategoriasError = result.message;
      subcategoriasState = CatalogLoadState.error;
      _subcategoriasFetchedAt = null;
    }
    _safeNotify();
  }

  Future<void> retrySubcategorias(int categoriaId) async {
    _loadedCategoriaId = null;
    subcategoriasState = CatalogLoadState.idle;
    subcategorias = const [];
    subcategoriasError = '';
    _safeNotify();
    await loadSubcategorias(categoriaId);
  }

  // ── Todas las subcategorías (admin) ──────────────────────────────────

  Future<void> loadAllSubcategorias() async {
    if (allSubcategoriasState == CatalogLoadState.success &&
        allSubcategorias.isNotEmpty) {
      return;
    }
    allSubcategoriasState = CatalogLoadState.loading;
    allSubcategoriasError = '';
    _safeNotify();

    final result = await _service.getSubcategorias();
    if (_disposed) return;
    if (result.success && result.data != null) {
      allSubcategorias = result.data!;
      allSubcategoriasState = CatalogLoadState.success;
    } else {
      allSubcategorias = const [];
      allSubcategoriasError = result.message;
      allSubcategoriasState = CatalogLoadState.error;
    }
    _safeNotify();
  }

  Future<void> retryAllSubcategorias() async {
    allSubcategoriasState = CatalogLoadState.idle;
    allSubcategorias = const [];
    allSubcategoriasError = '';
    _safeNotify();
    await loadAllSubcategorias();
  }

  // ════════════════════════════════════════════════════════════
  // TIPOS DE SERVICIO — LECTURA (navegación cliente)
  // ════════════════════════════════════════════════════════════

  Future<void> loadTiposServicio(int subcategoriaId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _loadedSubcategoriaId == subcategoriaId &&
        tiposState == CatalogLoadState.success &&
        _tiposFetchedAt != null &&
        DateTime.now().difference(_tiposFetchedAt!) < _cacheTtl) {
      return;
    }
    if (_loadedSubcategoriaId != subcategoriaId) {
      tipos = const [];
      tiposState = CatalogLoadState.idle;
      _loadedSubcategoriaId = subcategoriaId;
      _tiposFetchedAt = null;
      servicios = const [];
      serviciosState = CatalogLoadState.idle;
      _loadedTipoId = null;
    }
    final int thisGen = ++_tiposGen;
    tiposState = CatalogLoadState.loading;
    tiposError = '';
    _safeNotify();

    final result = await _service.getTiposServicioPorSubcategoria(subcategoriaId);

    if (thisGen != _tiposGen || _disposed) return;
    if (result.success && result.data != null) {
      tipos = result.data!;
      tiposState = CatalogLoadState.success;
      _tiposFetchedAt = DateTime.now();
    } else {
      tipos = const [];
      tiposError = result.message;
      tiposState = CatalogLoadState.error;
      _tiposFetchedAt = null;
    }
    _safeNotify();
  }

  Future<void> retryTiposServicio(int subcategoriaId) async {
    _loadedSubcategoriaId = null;
    tiposState = CatalogLoadState.idle;
    tipos = const [];
    tiposError = '';
    _safeNotify();
    await loadTiposServicio(subcategoriaId);
  }

  // ── Todos los tipos de servicio (admin) ──────────────────────────────

  Future<void> loadAllTiposServicio() async {
    if (allTiposState == CatalogLoadState.success && allTipos.isNotEmpty) {
      return;
    }
    allTiposState = CatalogLoadState.loading;
    allTiposError = '';
    _safeNotify();

    final result = await _service.getTiposServicio();
    if (_disposed) return;
    if (result.success && result.data != null) {
      allTipos = result.data!;
      allTiposState = CatalogLoadState.success;
    } else {
      allTipos = const [];
      allTiposError = result.message;
      allTiposState = CatalogLoadState.error;
    }
    _safeNotify();
  }

  Future<void> retryAllTiposServicio() async {
    allTiposState = CatalogLoadState.idle;
    allTipos = const [];
    allTiposError = '';
    _safeNotify();
    await loadAllTiposServicio();
  }

  // ── Todos los servicios (admin) ─────────────────────────────────────

  Future<void> loadAllServicios() async {
    if (allServiciosState == CatalogLoadState.success && allServicios.isNotEmpty) {
      return;
    }
    allServiciosState = CatalogLoadState.loading;
    allServiciosError = '';
    _safeNotify();

    final result = await _service.getAllServiciosProveedor();
    if (_disposed) return;
    if (result.success && result.data != null) {
      allServicios = result.data!;
      allServiciosState = CatalogLoadState.success;
    } else {
      allServicios = const [];
      allServiciosError = result.message;
      allServiciosState = CatalogLoadState.error;
    }
    _safeNotify();
  }

  Future<void> retryAllServicios() async {
    allServiciosState = CatalogLoadState.idle;
    allServicios = const [];
    allServiciosError = '';
    _safeNotify();
    await loadAllServicios();
  }

  // ════════════════════════════════════════════════════════════
  // SERVICIOS DE PROVEEDOR — LECTURA (navegación cliente)
  // ════════════════════════════════════════════════════════════

  Future<void> loadServiciosPorTipo(int tipoServicioId) async {
    if (_loadedTipoId == tipoServicioId &&
        serviciosState == CatalogLoadState.success) {
      return;
    }
    if (_loadedTipoId != tipoServicioId) {
      servicios = const [];
      serviciosState = CatalogLoadState.idle;
      _loadedTipoId = tipoServicioId;
    }
    final int thisGen = ++_serviciosGen;
    serviciosState = CatalogLoadState.loading;
    serviciosError = '';
    _safeNotify();

    final result = await _service.getServiciosPorTipoServicio(tipoServicioId);

    if (thisGen != _serviciosGen || _disposed) return;
    if (result.success && result.data != null) {
      // Solo servicios activos para el cliente
      servicios = result.data!
          .where((s) => s.estado && s.tipoServicioId == tipoServicioId)
          .toList();
      serviciosState = CatalogLoadState.success;
    } else {
      servicios = const [];
      serviciosError = result.message;
      serviciosState = CatalogLoadState.error;
    }
    _safeNotify();
  }

  Future<void> loadServiciosPorTipos(List<int> tipoServicioIds) async {
    final ids = tipoServicioIds
        .where((id) => id > 0)
        .toSet()
        .toList()
      ..sort();

    if (ids.isEmpty) {
      servicios = const [];
      serviciosState = CatalogLoadState.success;
      serviciosError = '';
      _loadedTipoId = null;
      _safeNotify();
      return;
    }

    final int thisGen = ++_serviciosGen;
    serviciosState = CatalogLoadState.loading;
    serviciosError = '';
    _loadedTipoId = null;
    _safeNotify();

    final result = await _service.getAllServiciosProveedor();

    if (thisGen != _serviciosGen || _disposed) return;
    if (result.success && result.data != null) {
      final idSet = ids.toSet();
      servicios = result.data!
          .where((s) => s.estado && idSet.contains(s.tipoServicioId))
          .toList();
      serviciosState = CatalogLoadState.success;
    } else {
      servicios = const [];
      serviciosError = result.message;
      serviciosState = CatalogLoadState.error;
    }
    _safeNotify();
  }

  Future<void> retryServiciosPorTipo(int tipoServicioId) async {
    _loadedTipoId = null;
    serviciosState = CatalogLoadState.idle;
    servicios = const [];
    serviciosError = '';
    _safeNotify();
    await loadServiciosPorTipo(tipoServicioId);
  }

  Future<void> buscarServicios(String busqueda) async {
    final int thisGen = ++_serviciosGen;
    serviciosState = CatalogLoadState.loading;
    serviciosError = '';
    _safeNotify();

    final result = await _service.buscarServiciosProveedor(busqueda);

    if (thisGen != _serviciosGen || _disposed) return;
    if (result.success && result.data != null) {
      servicios = result.data!.where((s) => s.estado).toList();
      serviciosState = CatalogLoadState.success;
    } else {
      servicios = const [];
      serviciosError = result.message;
      serviciosState = CatalogLoadState.error;
    }
    _safeNotify();
  }

  // ── Servicios del proveedor autenticado (panel proveedor) ─────────────

  Future<void> loadServiciosDelProveedor(int proveedorId) async {
    if (serviciosProveedorState == CatalogLoadState.success) return;
    serviciosProveedorState = CatalogLoadState.loading;
    serviciosProveedorError = '';
    _safeNotify();

    final result = await _service.getMisServicios();
    if (_disposed) return;
    if (result.success && result.data != null) {
      serviciosProveedor = result.data!;
      serviciosProveedorState = CatalogLoadState.success;
    } else {
      serviciosProveedor = const [];
      serviciosProveedorError = result.message;
      serviciosProveedorState = CatalogLoadState.error;
    }
    _safeNotify();
  }

  Future<void> retryServiciosDelProveedor(int proveedorId) async {
    serviciosProveedorState = CatalogLoadState.idle;
    serviciosProveedor = const [];
    serviciosProveedorError = '';
    _safeNotify();
    await loadServiciosDelProveedor(proveedorId);
  }

  // ════════════════════════════════════════════════════════════
  // CATEGORÍAS — CRUD
  // ════════════════════════════════════════════════════════════

  Future<ApiResult<Categoria>> createCategoria({
    required String nombre,
    String? descripcion,
  }) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.createCategoria(
        nombre: nombre, descripcion: descripcion);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success && result.data != null) {
        categorias = [...categorias, result.data!];
        categoriasState = CatalogLoadState.success;
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<Categoria>> updateCategoria(
    int id, {
    required String nombre,
    String? descripcion,
  }) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.updateCategoria(id,
        nombre: nombre, descripcion: descripcion);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success && result.data != null) {
        categorias = categorias.map((c) => c.id == id ? result.data! : c).toList();
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<void>> deleteCategoria(int id) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.deleteCategoria(id);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success) {
        categorias = categorias.where((c) => c.id != id).toList();
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  // ════════════════════════════════════════════════════════════
  // SUBCATEGORÍAS — CRUD
  // ════════════════════════════════════════════════════════════

  Future<ApiResult<Subcategoria>> createSubcategoria({
    required String nombre,
    String? descripcion,
    required int categoriaId,
  }) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.createSubcategoria(
        nombre: nombre, descripcion: descripcion, categoriaId: categoriaId);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success) {
        // Invalidar caché para que se recarguen al volver a la pantalla
        _loadedCategoriaId = null;
        allSubcategoriasState = CatalogLoadState.idle;
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<Subcategoria>> updateSubcategoria(
    int id, {
    required String nombre,
    String? descripcion,
    required int categoriaId,
  }) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.updateSubcategoria(id,
        nombre: nombre, descripcion: descripcion, categoriaId: categoriaId);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success) {
        _loadedCategoriaId = null;
        allSubcategoriasState = CatalogLoadState.idle;
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<void>> deleteSubcategoria(int id) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.deleteSubcategoria(id);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success) {
        _loadedCategoriaId = null;
        allSubcategoriasState = CatalogLoadState.idle;
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  // ════════════════════════════════════════════════════════════
  // TIPOS DE SERVICIO — CRUD
  // ════════════════════════════════════════════════════════════

  Future<ApiResult<TipoServicio>> createTipoServicio({
    required String nombre,
    String? descripcion,
    required int subcategoriaId,
  }) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.createTipoServicio(
        nombre: nombre,
        descripcion: descripcion,
        subcategoriaId: subcategoriaId);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success) {
        _loadedSubcategoriaId = null;
        allTiposState = CatalogLoadState.idle;
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<TipoServicio>> updateTipoServicio(
    int id, {
    required String nombre,
    String? descripcion,
    required int subcategoriaId,
  }) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.updateTipoServicio(id,
        nombre: nombre,
        descripcion: descripcion,
        subcategoriaId: subcategoriaId);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success) {
        _loadedSubcategoriaId = null;
        allTiposState = CatalogLoadState.idle;
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<void>> deleteTipoServicio(int id) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.deleteTipoServicio(id);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success) {
        _loadedSubcategoriaId = null;
        allTiposState = CatalogLoadState.idle;
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  // ════════════════════════════════════════════════════════════
  // SERVICIOS DE PROVEEDOR — CRUD
  // ════════════════════════════════════════════════════════════

  Future<ApiResult<ServicioProveedor>> createMisServicioProveedor({
    required int tipoServicioId,
    required double precioBase,
    bool estado = true,
    String? descripcion,
  }) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.createMisServicioProveedor(
      tipoServicioId: tipoServicioId,
      precioBase: precioBase,
      estado: estado,
      descripcion: descripcion,
    );

    isSubmitting = false;
    if (!_disposed) {
      if (result.success && result.data != null) {
        serviciosProveedor = [...serviciosProveedor, result.data!];
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<ServicioProveedor>> updateMisServicioProveedor(
    int id, {
    required int tipoServicioId,
    required double precioBase,
    required bool estado,
    String? descripcion,
  }) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.updateMisServicioProveedor(
      id,
      tipoServicioId: tipoServicioId,
      precioBase: precioBase,
      estado: estado,
      descripcion: descripcion,
    );

    isSubmitting = false;
    if (!_disposed) {
      if (result.success && result.data != null) {
        serviciosProveedor =
            serviciosProveedor.map((s) => s.id == id ? result.data! : s).toList();
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<void>> deleteMisServicioProveedor(int id) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.deleteMisServicioProveedor(id);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success) {
        serviciosProveedor = serviciosProveedor.where((s) => s.id != id).toList();
        allServicios = allServicios.where((s) => s.id != id).toList();
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<ServicioProveedor>> createServicioProveedor({
    required int tipoServicioId,
    required int proveedorId,
    required double precioBase,
    bool estado = true,
  }) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.createServicioProveedor(
      tipoServicioId: tipoServicioId,
      proveedorId: proveedorId,
      precioBase: precioBase,
      estado: estado,
    );

    isSubmitting = false;
    if (!_disposed) {
      if (result.success && result.data != null) {
        serviciosProveedor = [...serviciosProveedor, result.data!];
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<ServicioProveedor>> updateServicioProveedor(
    int id, {
    required int tipoServicioId,
    required int proveedorId,
    required double precioBase,
    required bool estado,
  }) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.updateServicioProveedor(
      id,
      tipoServicioId: tipoServicioId,
      proveedorId: proveedorId,
      precioBase: precioBase,
      estado: estado,
    );

    isSubmitting = false;
    if (!_disposed) {
      if (result.success && result.data != null) {
        serviciosProveedor = serviciosProveedor
            .map((s) => s.id == id ? result.data! : s)
            .toList();
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<void>> deleteServicioProveedor(int id, int proveedorId) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.deleteServicioProveedor(id);

    isSubmitting = false;
    if (!_disposed) {
      if (result.success) {
        serviciosProveedor =
            serviciosProveedor.where((s) => s.id != id).toList();
        // También actualizar la lista global de admin
        allServicios = allServicios.where((s) => s.id != id).toList();
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  Future<ApiResult<ServicioProveedor>> toggleServicioEstado(ServicioProveedor serv) async {
    isSubmitting = true;
    lastOperationError = '';
    _safeNotify();

    final result = await _service.updateMisServicioProveedor(
      serv.id,
      tipoServicioId: serv.tipoServicioId,
      precioBase: serv.precioBase,
      estado: !serv.estado,
      descripcion: serv.descripcion,
    );

    isSubmitting = false;
    if (!_disposed) {
      if (result.success && result.data != null) {
        // Actualizar en todas las listas donde pueda estar
        final updated = result.data!;
        allServicios = allServicios.map((s) => s.id == serv.id ? updated : s).toList();
        serviciosProveedor = serviciosProveedor.map((s) => s.id == serv.id ? updated : s).toList();
        servicios = servicios.map((s) => s.id == serv.id ? updated : s).toList();
      } else {
        lastOperationError = result.message;
      }
      _safeNotify();
    }
    return result;
  }

  // ════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
