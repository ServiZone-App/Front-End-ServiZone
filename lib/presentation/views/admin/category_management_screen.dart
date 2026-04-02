import 'package:flutter/material.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/models/catalog/categoria_model.dart';
import 'package:servizone_app/data/models/catalog/subcategoria_model.dart';
import 'package:servizone_app/data/models/catalog/tipo_servicio_model.dart';
import 'package:servizone_app/data/models/catalog/servicio_proveedor_model.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/presentation/views/admin/shared/admin_shared_widgets.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late final CatalogNotifier _notifier;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _notifier = locator<CatalogNotifier>();
    _notifier.addListener(_onChanged);
    // Cargar datos para las cuatro pestañas
    _notifier.loadCategorias();
    _notifier.loadAllSubcategorias();
    _notifier.loadAllTiposServicio();
    _notifier.loadAllServicios();
  }

  @override
  void dispose() {
    _notifier.removeListener(_onChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? errorRed : successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // DIÁLOGOS CATEGORÍA
  // ════════════════════════════════════════════════════════════

  void _showCreateCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _buildCrudDialog(
        title: 'Crear Categoría',
        children: [
          _buildField(nameCtrl, 'Nombre *', Icons.category_rounded),
          const SizedBox(height: 12),
          _buildField(descCtrl, 'Descripción', Icons.description_rounded,
              maxLines: 3),
        ],
        onConfirm: () async {
          if (nameCtrl.text.trim().isEmpty) {
            _showNotification('El nombre es obligatorio', isError: true);
            return;
          }
          Navigator.pop(ctx);
          final result = await _notifier.createCategoria(
            nombre: nameCtrl.text.trim(),
            descripcion: descCtrl.text.trim().isEmpty
                ? null
                : descCtrl.text.trim(),
          );
          _showNotification(
            result.success
                ? 'Categoría creada correctamente'
                : result.message,
            isError: !result.success,
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(Categoria cat) {
    final nameCtrl = TextEditingController(text: cat.nombre);
    final descCtrl = TextEditingController(text: cat.descripcion ?? '');
    showDialog(
      context: context,
      builder: (ctx) => _buildCrudDialog(
        title: 'Editar Categoría',
        children: [
          _buildField(nameCtrl, 'Nombre *', Icons.category_rounded),
          const SizedBox(height: 12),
          _buildField(descCtrl, 'Descripción', Icons.description_rounded,
              maxLines: 3),
        ],
        onConfirm: () async {
          if (nameCtrl.text.trim().isEmpty) {
            _showNotification('El nombre es obligatorio', isError: true);
            return;
          }
          Navigator.pop(ctx);
          final result = await _notifier.updateCategoria(
            cat.id,
            nombre: nameCtrl.text.trim(),
            descripcion: descCtrl.text.trim().isEmpty
                ? null
                : descCtrl.text.trim(),
          );
          _showNotification(
            result.success
                ? 'Categoría actualizada correctamente'
                : result.message,
            isError: !result.success,
          );
        },
      ),
    );
  }

  void _showDeleteCategoryDialog(Categoria cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Categoría',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            '¿Estás seguro de que deseas eliminar "${cat.nombre}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _notifier.deleteCategoria(cat.id);
              _showNotification(
                result.success
                    ? 'Categoría eliminada correctamente'
                    : result.message,
                isError: !result.success,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: errorRed, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // DIÁLOGOS SUBCATEGORÍA
  // ════════════════════════════════════════════════════════════

  void _showCreateSubcategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Categoria? selectedCat;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _buildCrudDialog(
          title: 'Crear Subcategoría',
          children: [
            _buildField(nameCtrl, 'Nombre *', Icons.list_rounded),
            const SizedBox(height: 12),
            _buildField(descCtrl, 'Descripción', Icons.description_rounded,
                maxLines: 3),
            const SizedBox(height: 12),
            const Text('Categoría padre *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            _buildCategoriasDropdown(
              selected: selectedCat,
              onChanged: (v) => setS(() => selectedCat = v),
            ),
          ],
          onConfirm: () async {
            if (nameCtrl.text.trim().isEmpty || selectedCat == null) {
              _showNotification('Nombre y categoría son obligatorios',
                  isError: true);
              return;
            }
            Navigator.pop(ctx);
            final result = await _notifier.createSubcategoria(
              nombre: nameCtrl.text.trim(),
              descripcion: descCtrl.text.trim().isEmpty
                  ? null
                  : descCtrl.text.trim(),
              categoriaId: selectedCat!.id,
            );
            if (result.success) _notifier.loadAllSubcategorias();
            _showNotification(
              result.success
                  ? 'Subcategoría creada correctamente'
                  : result.message,
              isError: !result.success,
            );
          },
        ),
      ),
    );
  }

  void _showEditSubcategoryDialog(Subcategoria sub) {
    final nameCtrl = TextEditingController(text: sub.nombre);
    final descCtrl = TextEditingController(text: sub.descripcion ?? '');
    Categoria? selectedCat = _notifier.categorias
        .where((c) => c.id == sub.categoriaId)
        .firstOrNull;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _buildCrudDialog(
          title: 'Editar Subcategoría',
          children: [
            _buildField(nameCtrl, 'Nombre *', Icons.list_rounded),
            const SizedBox(height: 12),
            _buildField(descCtrl, 'Descripción', Icons.description_rounded,
                maxLines: 3),
            const SizedBox(height: 12),
            const Text('Categoría padre *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            _buildCategoriasDropdown(
              selected: selectedCat,
              onChanged: (v) => setS(() => selectedCat = v),
            ),
          ],
          onConfirm: () async {
            if (nameCtrl.text.trim().isEmpty || selectedCat == null) {
              _showNotification('Nombre y categoría son obligatorios',
                  isError: true);
              return;
            }
            Navigator.pop(ctx);
            final result = await _notifier.updateSubcategoria(
              sub.id,
              nombre: nameCtrl.text.trim(),
              descripcion: descCtrl.text.trim().isEmpty
                  ? null
                  : descCtrl.text.trim(),
              categoriaId: selectedCat!.id,
            );
            if (result.success) _notifier.loadAllSubcategorias();
            _showNotification(
              result.success
                  ? 'Subcategoría actualizada correctamente'
                  : result.message,
              isError: !result.success,
            );
          },
        ),
      ),
    );
  }

  void _showDeleteSubcategoryDialog(Subcategoria sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Subcategoría',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            '¿Eliminar "${sub.nombre}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _notifier.deleteSubcategoria(sub.id);
              if (result.success) _notifier.loadAllSubcategorias();
              _showNotification(
                result.success
                    ? 'Subcategoría eliminada'
                    : result.message,
                isError: !result.success,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: errorRed, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // DIÁLOGOS TIPO DE SERVICIO
  // ════════════════════════════════════════════════════════════

  void _showCreateServiceTypeDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Subcategoria? selectedSub;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _buildCrudDialog(
          title: 'Crear Tipo de Servicio',
          children: [
            _buildField(nameCtrl, 'Nombre *', Icons.build_rounded),
            const SizedBox(height: 12),
            _buildField(descCtrl, 'Descripción', Icons.description_rounded,
                maxLines: 3),
            const SizedBox(height: 12),
            const Text('Subcategoría *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            _buildSubcategoriasDropdown(
              selected: selectedSub,
              onChanged: (v) => setS(() => selectedSub = v),
            ),
          ],
          onConfirm: () async {
            if (nameCtrl.text.trim().isEmpty || selectedSub == null) {
              _showNotification('Nombre y subcategoría son obligatorios',
                  isError: true);
              return;
            }
            Navigator.pop(ctx);
            final result = await _notifier.createTipoServicio(
              nombre: nameCtrl.text.trim(),
              descripcion: descCtrl.text.trim().isEmpty
                  ? null
                  : descCtrl.text.trim(),
              subcategoriaId: selectedSub!.id,
            );
            if (result.success) _notifier.loadAllTiposServicio();
            _showNotification(
              result.success
                  ? 'Tipo de servicio creado correctamente'
                  : result.message,
              isError: !result.success,
            );
          },
        ),
      ),
    );
  }

  void _showEditServiceTypeDialog(TipoServicio tipo) {
    final nameCtrl = TextEditingController(text: tipo.nombre);
    final descCtrl = TextEditingController(text: tipo.descripcion ?? '');
    Subcategoria? selectedSub = _notifier.allSubcategorias
        .where((s) => s.id == tipo.subcategoriaId)
        .firstOrNull;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _buildCrudDialog(
          title: 'Editar Tipo de Servicio',
          children: [
            _buildField(nameCtrl, 'Nombre *', Icons.build_rounded),
            const SizedBox(height: 12),
            _buildField(descCtrl, 'Descripción', Icons.description_rounded,
                maxLines: 3),
            const SizedBox(height: 12),
            const Text('Subcategoría *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            _buildSubcategoriasDropdown(
              selected: selectedSub,
              onChanged: (v) => setS(() => selectedSub = v),
            ),
          ],
          onConfirm: () async {
            if (nameCtrl.text.trim().isEmpty || selectedSub == null) {
              _showNotification('Nombre y subcategoría son obligatorios',
                  isError: true);
              return;
            }
            Navigator.pop(ctx);
            final result = await _notifier.updateTipoServicio(
              tipo.id,
              nombre: nameCtrl.text.trim(),
              descripcion: descCtrl.text.trim().isEmpty
                  ? null
                  : descCtrl.text.trim(),
              subcategoriaId: selectedSub!.id,
            );
            if (result.success) _notifier.loadAllTiposServicio();
            _showNotification(
              result.success
                  ? 'Tipo de servicio actualizado'
                  : result.message,
              isError: !result.success,
            );
          },
        ),
      ),
    );
  }

  void _showDeleteServiceTypeDialog(TipoServicio tipo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Tipo de Servicio',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            '¿Eliminar "${tipo.nombre}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _notifier.deleteTipoServicio(tipo.id);
              if (result.success) _notifier.loadAllTiposServicio();
              _showNotification(
                result.success ? 'Tipo de servicio eliminado' : result.message,
                isError: !result.success,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: errorRed, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // WIDGETS AUXILIARES
  // ════════════════════════════════════════════════════════════

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildCategoriasDropdown({
    required Categoria? selected,
    required ValueChanged<Categoria?> onChanged,
  }) {
    final cats = _notifier.categorias;
    if (cats.isEmpty) {
      return const Text('No hay categorías disponibles',
          style: TextStyle(color: textGray));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Categoria>(
          value: selected,
          isExpanded: true,
          hint: const Text('Seleccionar categoría...'),
          items: cats
              .map((c) => DropdownMenuItem<Categoria>(
                    value: c,
                    child: Text(c.nombre),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSubcategoriasDropdown({
    required Subcategoria? selected,
    required ValueChanged<Subcategoria?> onChanged,
  }) {
    final subs = _notifier.allSubcategorias;
    if (subs.isEmpty) {
      return const Text('No hay subcategorías disponibles',
          style: TextStyle(color: textGray));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Subcategoria>(
          value: selected,
          isExpanded: true,
          hint: const Text('Seleccionar subcategoría...'),
          items: subs
              .map((s) => DropdownMenuItem<Subcategoria>(
                    value: s,
                    child: Text(s.nombre),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCrudDialog({
    required String title,
    required List<Widget> children,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textGray,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _notifier.isSubmitting ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _notifier.isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : backgroundGray,
      body: Column(
        children: [
          _buildHeader(),
          // Tabs
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryBlue,
              unselectedLabelColor: isDark ? Colors.white54 : textGray,
              indicatorColor: primaryBlue,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Categorías'),
                Tab(text: 'Subcategorías'),
                Tab(text: 'Tipos'),
                Tab(text: 'Servicios'),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriasTab(),
                _buildSubcategoriasTab(),
                _buildTiposTab(),
                _buildServiciosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: isDark ? null : const [BoxShadow(color: cardShadow, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión del Catálogo', 
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : darkGray
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Administra categorías y servicios del sistema', 
                      style: TextStyle(
                        fontSize: 14, 
                        color: isDark ? Colors.white70 : textGray
                      )
                    ),
                  ],
                ),
              ),
              _buildCreateMenu(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AdminSearchBar(
                  controller: _searchController,
                  hintText: 'Buscar en el catálogo...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : backgroundGray, 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: IconButton(
                  icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : darkGray),
                  onPressed: () {
                    _notifier.loadCategorias();
                    _notifier.loadAllSubcategorias();
                    _notifier.loadAllTiposServicio();
                    _notifier.loadAllServicios();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateMenu() {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'cat') _showCreateCategoryDialog();
        if (val == 'sub') _showCreateSubcategoryDialog();
        if (val == 'tipo') _showCreateServiceTypeDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'cat', child: Row(children: [Icon(Icons.category_rounded, size: 20), SizedBox(width: 12), Text('Nueva Categoría')])),
        const PopupMenuItem(value: 'sub', child: Row(children: [Icon(Icons.list_rounded, size: 20), SizedBox(width: 12), Text('Nueva Subcategoría')])),
        const PopupMenuItem(value: 'tipo', child: Row(children: [Icon(Icons.build_rounded, size: 20), SizedBox(width: 12), Text('Nuevo Tipo de Servicio')])),
      ],
    );
  }

  // ── Tab Categorías ────────────────────────────────────────────────────

  Widget _buildCategoriasTab() {
    final state = _notifier.categoriasState;
    if (state == CatalogLoadState.loading) return const AdminLoadingOverlay();
    
    if (state == CatalogLoadState.error) {
      return _buildErrorState(_notifier.categoriasError, _notifier.retryCategorias);
    }

    final filtered = _notifier.categorias.where((c) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || c.nombre.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) return const AdminEmptyState(icon: Icons.category_rounded, title: 'No hay categorías', subtitle: 'Empieza creando una categoría raíz.');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildCatalogTable(
            items: filtered,
            columns: const ['Nombre', 'Descripción', 'Acciones'],
            cellsBuilder: (c) => [
              DataCell(Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(c.descripcion ?? 'Sin descripción')),
              DataCell(_buildTableActions(
                onEdit: () => _showEditCategoryDialog(c),
                onDelete: () => _showDeleteCategoryDialog(c),
              )),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _buildCatalogCard(
            title: filtered[i].nombre,
            subtitle: filtered[i].descripcion ?? 'Sin descripción',
            icon: Icons.folder_rounded,
            onEdit: () => _showEditCategoryDialog(filtered[i]),
            onDelete: () => _showDeleteCategoryDialog(filtered[i]),
          ),
        );
      },
    );
  }

  Widget _buildSubcategoriasTab() {
    final state = _notifier.allSubcategoriasState;
    if (state == CatalogLoadState.loading) return const AdminLoadingOverlay();
    
    if (state == CatalogLoadState.error) {
      return _buildErrorState(_notifier.allSubcategoriasError, _notifier.retryAllSubcategorias);
    }

    final filtered = _notifier.allSubcategorias.where((s) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || s.nombre.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) return const AdminEmptyState(icon: Icons.list_rounded, title: 'No hay subcategorías', subtitle: 'Asocia una subcategoría a una categoría existente.');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildCatalogTable(
            items: filtered,
            columns: const ['Nombre', 'Categoría Padre', 'Descripción', 'Acciones'],
            cellsBuilder: (s) {
              final catNombre = _notifier.categorias
                  .where((c) => c.id == s.categoriaId)
                  .map((c) => c.nombre)
                  .firstOrNull;
              return [
                DataCell(Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(AdminDataBadge(label: catNombre ?? 'ID: ${s.categoriaId}', color: primaryBlue)),
                DataCell(Text(s.descripcion ?? 'Sin descripción')),
                DataCell(_buildTableActions(
                  onEdit: () => _showEditSubcategoryDialog(s),
                  onDelete: () => _showDeleteSubcategoryDialog(s),
                )),
              ];
            },
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final catNombre = _notifier.categorias
                .where((c) => c.id == filtered[i].categoriaId)
                .map((c) => c.nombre)
                .firstOrNull;
            return _buildCatalogCard(
              title: filtered[i].nombre,
              subtitle: filtered[i].descripcion ?? 'Sin descripción',
              extra: catNombre != null ? 'Categoría: $catNombre' : 'ID cat: ${filtered[i].categoriaId}',
              icon: Icons.list_rounded,
              onEdit: () => _showEditSubcategoryDialog(filtered[i]),
              onDelete: () => _showDeleteSubcategoryDialog(filtered[i]),
            );
          },
        );
      },
    );
  }

  Widget _buildTiposTab() {
    final state = _notifier.allTiposState;
    if (state == CatalogLoadState.loading) return const AdminLoadingOverlay();
    
    if (state == CatalogLoadState.error) {
      return _buildErrorState(_notifier.allTiposError, _notifier.retryAllTiposServicio);
    }

    final filtered = _notifier.allTipos.where((t) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || t.nombre.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) return const AdminEmptyState(icon: Icons.build_rounded, title: 'No hay tipos de servicio', subtitle: 'Define los tipos de servicio para las subcategorías.');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildCatalogTable(
            items: filtered,
            columns: const ['Nombre', 'Subcategoría', 'Descripción', 'Acciones'],
            cellsBuilder: (t) {
              final subNombre = _notifier.allSubcategorias
                  .where((s) => s.id == t.subcategoriaId)
                  .map((s) => s.nombre)
                  .firstOrNull;
              return [
                DataCell(Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(AdminDataBadge(label: subNombre ?? 'ID: ${t.subcategoriaId}', color: purple)),
                DataCell(Text(t.descripcion ?? 'Sin descripción')),
                DataCell(_buildTableActions(
                  onEdit: () => _showEditServiceTypeDialog(t),
                  onDelete: () => _showDeleteServiceTypeDialog(t),
                )),
              ];
            },
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final subNombre = _notifier.allSubcategorias
                .where((s) => s.id == filtered[i].subcategoriaId)
                .map((s) => s.nombre)
                .firstOrNull;
            return _buildCatalogCard(
              title: filtered[i].nombre,
              subtitle: filtered[i].descripcion ?? 'Sin descripción',
              extra: subNombre != null ? 'Subcategoría: $subNombre' : 'ID sub: ${filtered[i].subcategoriaId}',
              icon: Icons.build_rounded,
              onEdit: () => _showEditServiceTypeDialog(filtered[i]),
              onDelete: () => _showDeleteServiceTypeDialog(filtered[i]),
            );
          },
        );
      },
    );
  }

  Widget _buildCatalogTable<T>({
    required List<T> items,
    required List<String> columns,
    required List<DataCell> Function(T item) cellsBuilder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.05) : backgroundGray.withValues(alpha: 0.5)),
          columns: columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          rows: items.map((item) => DataRow(cells: cellsBuilder(item))).toList(),
        ),
      ),
    );
  }

  Widget _buildTableActions({required VoidCallback onEdit, required VoidCallback onDelete}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(Icons.edit_outlined, size: 20, color: isDark ? Colors.white70 : textGray), onPressed: onEdit),
        IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: errorRed), onPressed: onDelete),
      ],
    );
  }

  Widget _buildCatalogCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    String? extra,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryBlue, size: 24),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : darkGray
          )
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle, 
              style: TextStyle(
                fontSize: 12, 
                color: isDark ? Colors.white54 : textGray
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (extra != null) ...[
              const SizedBox(height: 4),
              Text(
                extra, 
                style: const TextStyle(
                  fontSize: 11, 
                  color: primaryBlue, 
                  fontWeight: FontWeight.w600
                )
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.edit_outlined, size: 20, color: isDark ? Colors.white70 : textGray), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: errorRed), onPressed: onDelete),
          ],
        ),
      ),
    );
  }

  // ── Tab Servicios (ServicioProveedor) ────────────────────────────────

  Widget _buildServiciosTab() {
    final state = _notifier.allServiciosState;
    if (state == CatalogLoadState.loading) return const AdminLoadingOverlay();
    
    if (state == CatalogLoadState.error) {
      return _buildErrorState(
        _notifier.allServiciosError.isEmpty ? 'Error al cargar servicios' : _notifier.allServiciosError, 
        _notifier.retryAllServicios
      );
    }

    final filtered = _notifier.allServicios.where((s) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || 
             s.nombreMostrado.toLowerCase().contains(q) ||
             (s.proveedorNombre?.toLowerCase().contains(q) ?? false);
    }).toList();

    if (filtered.isEmpty) return const AdminEmptyState(icon: Icons.handyman_rounded, title: 'No hay servicios', subtitle: 'No se encontraron servicios activos en la red.');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildCatalogTable(
            items: filtered,
            columns: const ['Servicio', 'Proveedor', 'Precio', 'Duración', 'Estado'],
            cellsBuilder: (s) => [
              DataCell(Text(s.nombreMostrado, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(s.proveedorNombre ?? 'ID: ${s.proveedorId}', style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w600))),
              DataCell(Text('\$${s.precioBase.toStringAsFixed(0)}', style: const TextStyle(color: successGreen, fontWeight: FontWeight.bold))),
              DataCell(Text('${s.duracionEstimadaMin} min')),
              DataCell(AdminDataBadge.status(s.estaActivo ? 'ACTIVO' : 'INACTIVO')),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _buildServicioCard(filtered[i]),
        );
      },
    );
  }

  Widget _buildServicioCard(ServicioProveedor serv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.handyman_rounded, color: primaryBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serv.nombreMostrado,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16, 
                          color: isDark ? Colors.white : darkGray
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        serv.proveedorNombre ?? 'Proveedor ID: ${serv.proveedorId}',
                        style: const TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${serv.precioBase.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: successGreen, fontSize: 16),
                ),
              ],
            ),
            if (serv.descripcion != null && serv.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                serv.descripcion!,
                style: TextStyle(color: isDark ? Colors.white70 : textGray, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem(Icons.timer_outlined, '${serv.duracionEstimadaMin} min'),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.star_rounded, '${serv.ratingMedia}'),
                const Spacer(),
                AdminDataBadge.status(serv.estaActivo ? 'ACTIVO' : 'INACTIVO'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white54 : textGray),
        const SizedBox(width: 4),
        Text(
          text, 
          style: TextStyle(
            fontSize: 12, 
            color: isDark ? Colors.white54 : textGray
          )
        ),
      ],
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: errorRed),
          const SizedBox(height: 16),
          Text(
            error, 
            style: TextStyle(color: isDark ? Colors.white70 : textGray)
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRetry, child: const Text('REINTENTAR')),
        ],
      ),
    );
  }
}
