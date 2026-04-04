import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/models/catalog/categoria_model.dart';
import 'package:servizone_app/data/models/catalog/subcategoria_model.dart';
import 'package:servizone_app/data/models/catalog/tipo_servicio_model.dart';
import 'package:servizone_app/data/models/catalog/servicio_proveedor_model.dart';

abstract class CatalogRepository {
  Future<ApiResult<List<Categoria>>> getCategorias();
  Future<ApiResult<Categoria>> createCategoria({required String nombre, String? descripcion});
  Future<ApiResult<Categoria>> updateCategoria(int id, {required String nombre, String? descripcion});
  Future<ApiResult<void>> deleteCategoria(int id);

  Future<ApiResult<List<Subcategoria>>> getSubcategorias();
  Future<ApiResult<List<Subcategoria>>> getSubcategoriasPorCategoria(int categoriaId);
  Future<ApiResult<Subcategoria>> createSubcategoria({required String nombre, String? descripcion, required int categoriaId});
  Future<ApiResult<Subcategoria>> updateSubcategoria(int id, {required String nombre, String? descripcion, required int categoriaId});
  Future<ApiResult<void>> deleteSubcategoria(int id);

  Future<ApiResult<List<TipoServicio>>> getTiposServicio();
  Future<ApiResult<List<TipoServicio>>> getTiposServicioPorSubcategoria(int subcategoriaId);
  Future<ApiResult<TipoServicio>> createTipoServicio({required String nombre, String? descripcion, required int subcategoriaId});
  Future<ApiResult<TipoServicio>> updateTipoServicio(int id, {required String nombre, String? descripcion, required int subcategoriaId});
  Future<ApiResult<void>> deleteTipoServicio(int id);

  Future<ApiResult<List<ServicioProveedor>>> getAllServiciosProveedor();
  Future<ApiResult<List<ServicioProveedor>>> buscarServiciosProveedor(String busqueda);
  Future<ApiResult<List<ServicioProveedor>>> getMisServicios();
  Future<ApiResult<ServicioProveedor>> createMisServicioProveedor({required int tipoServicioId, required double precioBase, required bool estado, String? descripcion});
  Future<ApiResult<ServicioProveedor>> updateMisServicioProveedor(int id, {required int tipoServicioId, required double precioBase, required bool estado, String? descripcion});
  Future<ApiResult<void>> deleteMisServicioProveedor(int id);
}
