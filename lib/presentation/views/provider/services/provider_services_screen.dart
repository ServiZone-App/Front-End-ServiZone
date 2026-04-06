import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/models/catalog/servicio_proveedor_model.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/presentation/widgets/shared/provider_bottom_nav.dart';
import 'package:servizone_app/presentation/widgets/provider/create_service_bottom_sheet.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  late final CatalogNotifier _notifier;
  String _userName = 'Usuario Proveedor';
  bool? _statusFilter; // null = todos, true = activos, false = inactivos

  @override
  void initState() {
    super.initState();
    _notifier = locator<CatalogNotifier>();
    _notifier.addListener(_onChanged);
    _loadProviderData();
  }

  @override
  void dispose() {
    _notifier.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProviderData() async {
    final profile = locator<AuthService>().currentUserProfile;
    if (profile == null) return;

    final nombre =
        "${profile['Nombre'] ?? profile['nombre'] ?? ''} ${profile['Apellido'] ?? profile['apellido'] ?? ''}"
            .trim();

    if (mounted) {
      setState(() {
        _userName = nombre.isNotEmpty ? nombre : 'Usuario Proveedor';
      });
    }

    _notifier.loadServiciosDelProveedor(0);
  }

  List<ServicioProveedor> get _filteredServices {
    final all = _notifier.serviciosProveedor;
    if (_statusFilter == null) return all;
    return all.where((s) => s.estado == _statusFilter).toList();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ── Filtros ────────────────────────────────────────────────────────────

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar Servicios',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textGray)),
            const SizedBox(height: 20),
            _buildFilterOption(
                'Todos', _statusFilter == null, () => setState(() => _statusFilter = null)),
            _buildFilterOption(
                'Activos', _statusFilter == true, () => setState(() => _statusFilter = true)),
            _buildFilterOption(
                'Inactivos', _statusFilter == false, () => setState(() => _statusFilter = false)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Aplicar',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap) {
    return ListTile(
      title: Text(label,
          style: TextStyle(
              color: isSelected ? primaryBlue : textGray,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing:
          isSelected ? const Icon(Icons.check_rounded, color: primaryBlue) : null,
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
    );
  }

  // ── Modal de actualización ────────────────────────────────────────────

  static const double _precioMin = 10000;
  static const double _precioMax = 20000000;

  String? _validatePrecio(String raw) {
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) return 'Ingresa un precio';
    final value = double.tryParse(text);
    if (value == null) return 'Ingresa un número válido';
    if (value < _precioMin) return 'El precio mínimo es \$${_precioMin.toStringAsFixed(0)}';
    if (value > _precioMax) return 'El precio máximo es \$${_precioMax.toStringAsFixed(0)}';
    return null;
  }

  void _showUpdateModal(ServicioProveedor s) {
    final priceCtrl = TextEditingController(text: s.precioBase.toStringAsFixed(0));

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false;
        String? errorMsg = _validatePrecio(priceCtrl.text);

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final bool canConfirm = !isLoading && errorMsg == null;

            Future<void> confirm() async {
              final validationError = _validatePrecio(priceCtrl.text);
              if (validationError != null) {
                setDialogState(() => errorMsg = validationError);
                return;
              }
              final newPrice = double.parse(
                priceCtrl.text.trim().replaceAll(',', '.'),
              );
              setDialogState(() { isLoading = true; errorMsg = null; });
              final result = await _notifier.updateMisServicioProveedor(
                s.id,
                tipoServicioId: s.tipoServicioId,
                precioBase: newPrice,
                estado: s.estado,
                descripcion: s.descripcion,
              );
              if (!ctx.mounted) return;
              if (result.success) {
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Precio actualizado correctamente'),
                    backgroundColor: successGreen,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } else {
                setDialogState(() { isLoading = false; errorMsg = result.message; });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Actualizar servicio',
                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('Nombre', s.nombreMostrado),
                    if (s.descripcion != null && s.descripcion!.isNotEmpty)
                      _buildInfoItem('Descripción', s.descripcion!),
                    _buildInfoItem('Estado', s.estado ? 'Activo' : 'Inactivo'),
                    _buildInfoItem('Duración estimada', '${s.duracionEstimadaMin} min'),
                    if (s.ratingMedia > 0)
                      _buildInfoItem('Rating', '${s.ratingMedia.toStringAsFixed(1)} / 5'),
                    const Divider(height: 28),
                    const Text(
                      'Precio base',
                      style: TextStyle(fontWeight: FontWeight.w600, color: textGray, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (v) => setDialogState(() => errorMsg = _validatePrecio(v)),
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        hintText: '0',
                        filled: true,
                        fillColor: backgroundGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorText: errorMsg,
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator(color: primaryBlue)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: canConfirm ? confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => priceCtrl.dispose());
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: textGray, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textGray),
            ),
          ),
        ],
      ),
    );
  }

  // ── Acciones ──────────────────────────────────────────────────────────

  Future<void> _toggleEstado(ServicioProveedor s) async {
    HapticFeedback.lightImpact();
    final result = await _notifier.toggleServicioEstado(s);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success
            ? 'Servicio ${!s.estado ? 'activado' : 'desactivado'}'
            : result.message),
        backgroundColor: result.success ? successGreen : errorRed,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteServicio(ServicioProveedor s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar servicio',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            '¿Eliminar "${s.nombreMostrado}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: errorRed, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await _notifier.deleteMisServicioProveedor(s.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success ? 'Servicio eliminado' : result.message),
        backgroundColor: result.success ? successGreen : errorRed,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showCreateServiceModal() {
    CreateServiceBottomSheet.show(
      context,
      onServiceCreated: () {
        // Recargar lista desde API
        _notifier.retryServiciosDelProveedor(0);
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
                color: successGreen, shape: BoxShape.circle),
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    _getInitials(_userName),
                    style: const TextStyle(
                      color: successGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          _userName,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textGray,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: textGray),
            onPressed: _showFilterMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Text('Tus servicios',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textGray)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateServiceModal,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 36),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: const ProviderBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    final state = _notifier.serviciosProveedorState;

    if (state == CatalogLoadState.loading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryBlue));
    }

    if (state == CatalogLoadState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 60, color: textGray.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(_notifier.serviciosProveedorError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textGray)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                onPressed: () => _notifier.retryServiciosDelProveedor(0),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredServices;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_circle_outlined, size: 60, color: textGray),
            const SizedBox(height: 16),
            Text(
              _notifier.serviciosProveedor.isEmpty
                  ? 'Aún no tienes servicios registrados'
                  : 'No hay servicios con ese filtro',
              style: const TextStyle(color: textGray, fontSize: 16),
            ),
            if (_notifier.serviciosProveedor.isEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar primer servicio'),
                onPressed: _showCreateServiceModal,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _buildServiceCard(filtered[i]),
    );
  }

  Widget _buildServiceCard(ServicioProveedor s) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showUpdateModal(s);
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.estado ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.build_rounded, color: primaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nombreMostrado,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textGray)),
                const SizedBox(height: 4),
                Text(
                  '\$${s.precioBase.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue),
                ),
              ],
            ),
          ),
          // Toggle estado
          GestureDetector(
            onTap: () => _toggleEstado(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: s.estado ? successGreen : errorRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                s.estado ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: errorRed, size: 20),
            onPressed: () => _deleteServicio(s),
            tooltip: 'Eliminar servicio',
          ),
        ],
      ),
    ),
    );
  }
}
