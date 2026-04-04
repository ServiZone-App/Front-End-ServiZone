import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/models/catalog/categoria_model.dart';
import 'package:servizone_app/data/models/catalog/subcategoria_model.dart';
import 'package:servizone_app/data/models/catalog/tipo_servicio_model.dart';
import 'package:servizone_app/data/models/catalog/servicio_proveedor_model.dart';
import 'package:servizone_app/data/providers/catalog_service.dart';
import 'package:servizone_app/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogService _service;

  CatalogRepositoryImpl(this._service);

  @override
  Future<ApiResult<List<Categoria>>> getCategorias() => _service.getCategorias();

  @override
  Future<ApiResult<Categoria>> createCategoria({required String nombre, String? descripcion}) =>
      _service.createCategoria(nombre: nombre, descripcion: descripcion);

  @override
  Future<ApiResult<Categoria>> updateCategoria(int id, {required String nombre, String? descripcion}) =>
      _service.updateCategoria(id, nombre: nombre, descripcion: descripcion);

  @override
  Future<ApiResult<void>> deleteCategoria(int id) => _service.deleteCategoria(id);

  @override
  Future<ApiResult<List<Subcategoria>>> getSubcategorias() => _service.getSubcategorias();

  @override
  Future<ApiResult<List<Subcategoria>>> getSubcategoriasPorCategoria(int categoriaId) =>
      _service.getSubcategoriasPorCategoria(categoriaId);

  @override
  Future<ApiResult<Subcategoria>> createSubcategoria({required String nombre, String? descripcion, required int categoriaId}) =>
      _service.createSubcategoria(nombre: nombre, descripcion: descripcion, categoriaId: categoriaId);

  @override
  Future<ApiResult<Subcategoria>> updateSubcategoria(int id, {required String nombre, String? descripcion, required int categoriaId}) =>
      _service.updateSubcategoria(id, nombre: nombre, descripcion: descripcion, categoriaId: categoriaId);

  @override
  Future<ApiResult<void>> deleteSubcategoria(int id) => _service.deleteSubcategoria(id);

  @override
  Future<ApiResult<List<TipoServicio>>> getTiposServicio() => _service.getTiposServicio();

  @override
  Future<ApiResult<List<TipoServicio>>> getTiposServicioPorSubcategoria(int subcategoriaId) =>
      _service.getTiposServicioPorSubcategoria(subcategoriaId);

  @override
  Future<ApiResult<TipoServicio>> createTipoServicio({required String nombre, String? descripcion, required int subcategoriaId}) =>
      _service.createTipoServicio(nombre: nombre, descripcion: descripcion, subcategoriaId: subcategoriaId);

  @override
  Future<ApiResult<TipoServicio>> updateTipoServicio(int id, {required String nombre, String? descripcion, required int subcategoriaId}) =>
      _service.updateTipoServicio(id, nombre: nombre, descripcion: descripcion, subcategoriaId: subcategoriaId);

  @override
  Future<ApiResult<void>> deleteTipoServicio(int id) => _service.deleteTipoServicio(id);

  @override
  Future<ApiResult<List<ServicioProveedor>>> getAllServiciosProveedor() => _service.getAllServiciosProveedor();

  @override
  Future<ApiResult<List<ServicioProveedor>>> buscarServiciosProveedor(String busqueda) =>
      _service.buscarServiciosProveedor(busqueda);

  @override
  Future<ApiResult<List<ServicioProveedor>>> getMisServicios() => _service.getMisServicios();

  @override
  Future<ApiResult<ServicioProveedor>> createMisServicioProveedor({required int tipoServicioId, required double precioBase, required bool estado, String? descripcion}) =>
      _service.createMisServicioProveedor(tipoServicioId: tipoServicioId, precioBase: precioBase, estado: estado, descripcion: descripcion);

  @override
  Future<ApiResult<ServicioProveedor>> updateMisServicioProveedor(int id, {required int tipoServicioId, required double precioBase, required bool estado, String? descripcion}) =>
      _service.updateMisServicioProveedor(id, tipoServicioId: tipoServicioId, precioBase: precioBase, estado: estado, descripcion: descripcion);

  @override
  Future<ApiResult<void>> deleteMisServicioProveedor(int id) => _service.deleteMisServicioProveedor(id);
}
