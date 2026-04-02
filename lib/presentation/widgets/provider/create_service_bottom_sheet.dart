import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/models/catalog/categoria_model.dart';
import 'package:servizone_app/data/models/catalog/subcategoria_model.dart';
import 'package:servizone_app/data/models/catalog/tipo_servicio_model.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/data/providers/catalog_service.dart';

class CreateServiceBottomSheet extends StatefulWidget {
  final VoidCallback onServiceCreated;

  const CreateServiceBottomSheet({
    super.key,
    required this.onServiceCreated,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onServiceCreated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CreateServiceBottomSheet(
        onServiceCreated: onServiceCreated,
      ),
    );
  }

  @override
  State<CreateServiceBottomSheet> createState() =>
      _CreateServiceBottomSheetState();
}

class _CreateServiceBottomSheetState extends State<CreateServiceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();

  late final CatalogNotifier _notifier;
  late final CatalogService _service;

  // Selecciones en cascada
  Categoria? _selectedCategoria;
  Subcategoria? _selectedSubcategoria;
  TipoServicio? _selectedTipo;
  bool _estado = true;

  // Listas locales según selección
  List<Subcategoria> _subcategorias = [];
  List<TipoServicio> _tipos = [];

  // Estados de carga
  bool _loadingCategorias = false;
  bool _loadingSubcategorias = false;
  bool _loadingTipos = false;
  bool _isSubmitting = false;

  List<Categoria> _categorias = [];

  @override
  void initState() {
    super.initState();
    _notifier = locator<CatalogNotifier>();
    _service = locator<CatalogService>();
    _loadCategorias();
  }

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  // ── Carga en cascada ─────────────────────────────────────────────────

  Future<void> _loadCategorias() async {
    setState(() => _loadingCategorias = true);
    // Usar caché del notifier si ya existe
    if (_notifier.categoriasState == CatalogLoadState.success &&
        _notifier.categorias.isNotEmpty) {
      setState(() {
        _categorias = _notifier.categorias;
        _loadingCategorias = false;
      });
      return;
    }
    // Si no, cargarlas directamente
    final result = await _service.getCategorias();
    if (mounted) {
      setState(() {
        _categorias = result.data ?? [];
        _loadingCategorias = false;
      });
    }
  }

  Future<void> _onCategoriaChanged(Categoria? cat) async {
    setState(() {
      _selectedCategoria = cat;
      _selectedSubcategoria = null;
      _selectedTipo = null;
      _subcategorias = [];
      _tipos = [];
    });
    if (cat == null) return;

    setState(() => _loadingSubcategorias = true);
    final result = await _service.getSubcategoriasPorCategoria(cat.id);
    if (mounted) {
      setState(() {
        _subcategorias = result.data ?? [];
        _loadingSubcategorias = false;
      });
    }
  }

  Future<void> _onSubcategoriaChanged(Subcategoria? sub) async {
    setState(() {
      _selectedSubcategoria = sub;
      _selectedTipo = null;
      _tipos = [];
    });
    if (sub == null) return;

    setState(() => _loadingTipos = true);
    final result = await _service.getTiposServicioPorSubcategoria(sub.id);
    if (mounted) {
      setState(() {
        _tipos = result.data ?? [];
        _loadingTipos = false;
      });
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona el tipo de servicio'),
        backgroundColor: errorRed,
      ));
      return;
    }

    final precio = double.tryParse(
        _precioController.text.trim().replaceAll(',', '.'));
    if (precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingresa un precio válido mayor a cero'),
        backgroundColor: errorRed,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final result = await _notifier.createMisServicioProveedor(
      tipoServicioId: _selectedTipo!.id,
      precioBase: precio,
      estado: _estado,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.pop(context);
      widget.onServiceCreated();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Servicio creado correctamente'),
        backgroundColor: successGreen,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Crear Nuevo Servicio',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkGray),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: textGray),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Categoría
              const _SectionLabel('Categoría *'),
              const SizedBox(height: 6),
              _loadingCategorias
                  ? const _LoadingIndicator()
                  : DropdownButtonFormField<Categoria>(
                      isExpanded: true,
                      initialValue: _selectedCategoria,
                      decoration: _inputDeco('Seleccionar...', Icons.category_rounded),
                      items: _categorias
                          .map((c) => DropdownMenuItem<Categoria>(
                              value: c, child: Text(c.nombre)))
                          .toList(),
                      onChanged: _onCategoriaChanged,
                      validator: (_) => _selectedCategoria == null
                          ? 'Selecciona una categoría'
                          : null,
                    ),

              const SizedBox(height: 16),

              // 2. Subcategoría
              const _SectionLabel('Subcategoría *'),
              const SizedBox(height: 6),
              _loadingSubcategorias
                  ? const _LoadingIndicator()
                  : DropdownButtonFormField<Subcategoria>(
                      isExpanded: true,
                      initialValue: _selectedSubcategoria,
                      decoration: _inputDeco(
                          _selectedCategoria == null
                              ? 'Primero selecciona categoría'
                              : 'Seleccionar...',
                          Icons.list_rounded),
                      items: _subcategorias
                          .map((s) => DropdownMenuItem<Subcategoria>(
                              value: s, child: Text(s.nombre)))
                          .toList(),
                      onChanged: _selectedCategoria == null
                          ? null
                          : _onSubcategoriaChanged,
                      validator: (_) => _selectedSubcategoria == null
                          ? 'Selecciona una subcategoría'
                          : null,
                    ),

              const SizedBox(height: 16),

              // 3. Tipo de servicio
              const _SectionLabel('Tipo de Servicio *'),
              const SizedBox(height: 6),
              _loadingTipos
                  ? const _LoadingIndicator()
                  : DropdownButtonFormField<TipoServicio>(
                      isExpanded: true,
                      initialValue: _selectedTipo,
                      decoration: _inputDeco(
                          _selectedSubcategoria == null
                              ? 'Primero selecciona subcategoría'
                              : 'Seleccionar...',
                          Icons.build_rounded),
                      items: _tipos
                          .map((t) => DropdownMenuItem<TipoServicio>(
                              value: t, child: Text(t.nombre)))
                          .toList(),
                      onChanged: _selectedSubcategoria == null
                          ? null
                          : (v) => setState(() => _selectedTipo = v),
                      validator: (_) => _selectedTipo == null
                          ? 'Selecciona un tipo de servicio'
                          : null,
                    ),

              const SizedBox(height: 16),

              // 4. Precio base
              const _SectionLabel('Precio Base *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _precioController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDeco('Ej: 50000', Icons.attach_money_rounded),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el precio';
                  final d = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (d == null || d <= 0) return 'Precio inválido';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 5. Estado
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _estado ? 'Activo' : 'Inactivo',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: textGray),
                ),
                subtitle: const Text('El servicio será visible para los clientes',
                    style: TextStyle(fontSize: 12, color: textGray)),
                value: _estado,
                onChanged: (v) => setState(() => _estado = v),
                activeThumbColor: primaryBlue,
              ),

              const SizedBox(height: 24),

              // Botón crear
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Crear Servicio',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: darkGray),
      );
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
            ),
            SizedBox(width: 12),
            Text('Cargando...', style: TextStyle(color: textGray)),
          ],
        ),
      );
}
