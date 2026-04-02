import 'package:servizone_app/core/network/api_result.dart';
import 'package:servizone_app/data/models/catalog/categoria_model.dart';
import 'package:servizone_app/data/models/catalog/subcategoria_model.dart';
import 'package:servizone_app/data/models/catalog/tipo_servicio_model.dart';
import 'package:servizone_app/data/models/catalog/servicio_proveedor_model.dart';
import 'package:servizone_app/domain/repositories/catalog_repository.dart';
import 'package:servizone_app/presentation/viewmodels/base_view_model.dart';

class CatalogViewModel extends BaseViewModel {
  final CatalogRepository _repo;

  CatalogViewModel(this._repo);

  List<Categoria> categorias = const [];
  List<Subcategoria> subcategorias = const [];
  List<TipoServicio> tipos = const [];
  List<ServicioProveedor> servicios = const [];

  Future<ApiResult<List<Categoria>>> loadCategorias() async {
    setBusy(true);
    clearError();
    final res = await _repo.getCategorias();
    if (res.success && res.data != null) {
      categorias = res.data!;
    } else {
      setError(res.message);
    }
    setBusy(false);
    return res;
  }

  Future<ApiResult<List<Subcategoria>>> loadSubcategorias(int categoriaId) async {
    setBusy(true);
    clearError();
    final res = await _repo.getSubcategoriasPorCategoria(categoriaId);
    if (res.success && res.data != null) {
      subcategorias = res.data!;
    } else {
      setError(res.message);
    }
    setBusy(false);
    return res;
  }

  Future<ApiResult<List<TipoServicio>>> loadTipos(int subcategoriaId) async {
    setBusy(true);
    clearError();
    final res = await _repo.getTiposServicioPorSubcategoria(subcategoriaId);
    if (res.success && res.data != null) {
      tipos = res.data!;
    } else {
      setError(res.message);
    }
    setBusy(false);
    return res;
  }

  Future<ApiResult<List<ServicioProveedor>>> loadServiciosPorTipo(int tipoServicioId) async {
    setBusy(true);
    clearError();
    final res = await _repo.buscarServiciosProveedor('');
    if (res.success && res.data != null) {
      servicios = res.data!.where((s) => s.tipoServicioId == tipoServicioId).toList();
    } else {
      setError(res.message);
    }
    setBusy(false);
    return res;
  }
}
