import 'package:flutter/material.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/models/provider_model.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/data/providers/admin_audit_service.dart';
import 'package:servizone_app/presentation/views/admin/shared/admin_shared_widgets.dart';

class ProvidersManagementScreen extends StatefulWidget {
  const ProvidersManagementScreen({super.key});

  @override
  State<ProvidersManagementScreen> createState() => _ProvidersManagementScreenState();
}

class _ProvidersManagementScreenState extends State<ProvidersManagementScreen> {
  final List<ProviderModel> _providers = [];
  final List<ProviderModel> _filteredProviders = [];
  final TextEditingController _searchController = TextEditingController();
  final AdminAuditService _auditService = locator<AdminAuditService>();
  final AuthService _authService = locator<AuthService>();

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  final String _selectedStatus = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.getProveedoresVerificados();
      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        if (mounted) {
          setState(() {
            _providers.clear();
            _providers.addAll(data.map((e) => ProviderModel.fromJson(e)).toList());
            _applyFilters();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error inesperado: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _filteredProviders.clear();
    final query = _searchQuery.toLowerCase();

    _filteredProviders.addAll(_providers.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.email.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      
      final matchesCategory = _selectedCategory == 'Todos' || p.category == _selectedCategory;
      
      final matchesStatus = _selectedStatus == 'Todos' ||
          (_selectedStatus == 'Activos' && p.isActive) ||
          (_selectedStatus == 'Inactivos' && !p.isActive);

      return matchesSearch && matchesCategory && matchesStatus;
    }));
  }

  Future<void> _handleBlock(ProviderModel provider) async {
    setState(() => _isProcessing = true);
    try {
      final id = int.tryParse(provider.id) ?? 0;
      final result = await _authService.actualizarEstadoProveedor(id, 'bloqueado');
      if (!mounted) return;
      if (result['success'] == true) {
        final index = _providers.indexWhere((p) => p.id == provider.id);
        if (index != -1) {
          _providers[index].estado = 'bloqueado';
          _providers[index].isActive = false;
        }
        setState(() => _applyFilters());
        await _auditService.logAction(
          'BLOQUEO PROVEEDOR',
          'El proveedor ${provider.name} (#${provider.id}) ha sido bloqueado.',
        );
        _showResultModal(
          title: 'Cuenta Bloqueada',
          message: 'La cuenta de ${provider.name} ha sido bloqueada correctamente.',
          isSuccess: true,
          icon: Icons.block_rounded,
          color: errorRed,
        );
      } else {
        _showResultModal(
          title: 'Error al Bloquear',
          message: result['message'] ?? 'No se pudo bloquear la cuenta.',
          isSuccess: false,
          icon: Icons.error_outline_rounded,
          color: errorRed,
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultModal(
          title: 'Error',
          message: 'Ocurrió un error inesperado: $e',
          isSuccess: false,
          icon: Icons.error_outline_rounded,
          color: errorRed,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleUnblock(ProviderModel provider) async {
    setState(() => _isProcessing = true);
    try {
      final id = int.tryParse(provider.id) ?? 0;
      final result = await _authService.actualizarEstadoProveedor(id, 'activo');
      if (!mounted) return;
      if (result['success'] == true) {
        final index = _providers.indexWhere((p) => p.id == provider.id);
        if (index != -1) {
          _providers[index].estado = 'activo';
          _providers[index].isActive = true;
        }
        setState(() => _applyFilters());
        await _auditService.logAction(
          'DESBLOQUEO PROVEEDOR',
          'El proveedor ${provider.name} (#${provider.id}) ha sido desbloqueado.',
        );
        _showResultModal(
          title: 'Cuenta Activada',
          message: 'La cuenta de ${provider.name} ha sido activada correctamente.',
          isSuccess: true,
          icon: Icons.check_circle_outline_rounded,
          color: successGreen,
        );
      } else {
        _showResultModal(
          title: 'Error al Desbloquear',
          message: result['message'] ?? 'No se pudo activar la cuenta.',
          isSuccess: false,
          icon: Icons.error_outline_rounded,
          color: errorRed,
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultModal(
          title: 'Error',
          message: 'Ocurrió un error inesperado: $e',
          isSuccess: false,
          icon: Icons.error_outline_rounded,
          color: errorRed,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResultModal({
    required String title,
    required String message,
    required bool isSuccess,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: textGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ACEPTAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(130),
            child: AdminHeader(
              title: 'Gestión Proveedores',
              subtitle: 'Control operativo de la red de servicios',
              action: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: primaryBlue),
                onPressed: _loadProviders,
                tooltip: 'Refrescar datos',
              ),
            ),
          ),
          body: Column(
            children: [
              AdminSearchBar(
                controller: _searchController,
                hintText: 'Buscar por nombre, correo o especialidad...',
                onChanged: (val) {
                  _searchQuery = val;
                  setState(() => _applyFilters());
                },
                onFilterPressed: () => _showFiltersModal(),
                hasActiveFilters: _selectedCategory != 'Todos' || _selectedStatus != 'Todos',
              ),
              Expanded(
                child: _isLoading
                    ? const AdminLoadingOverlay()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _filteredProviders.isEmpty
                            ? const AdminEmptyState(
                                icon: Icons.business_rounded,
                                title: 'Sin coincidencias',
                                subtitle: 'No encontramos proveedores con esos criterios de búsqueda.',
                              )
                            : _buildProviderList(),
              ),
            ],
          ),
        ),
        if (_isProcessing)
          const AdminLoadingOverlay(),
      ],
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            _errorMessage!, 
            style: TextStyle(color: isDark ? Colors.white70 : textGray)
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadProviders, child: const Text('REINTENTAR')),
        ],
      ),
    );
  }

  Widget _buildProviderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredProviders.length,
      itemBuilder: (context, index) => _buildProviderCard(_filteredProviders[index]),
    );
  }

  Widget _buildProviderCard(ProviderModel provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildAvatar(provider.name),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16, 
                          color: isDark ? Colors.white : darkGray
                        ),
                      ),
                      Text(
                        provider.category, 
                        style: const TextStyle(
                          fontSize: 13, 
                          color: primaryBlue, 
                          fontWeight: FontWeight.w600
                        )
                      ),
                    ],
                  ),
                ),
                AdminDataBadge.status(provider.estado),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: _buildInfoItem(Icons.email_outlined, provider.email)),
                const SizedBox(width: 12),
                _buildRating(provider.rating),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: provider.estado == 'activo'
                      ? AdminActionCard(
                          label: 'Bloquear Cuenta',
                          onTap: () => _handleBlock(provider),
                        )
                      : AdminActionCard(
                          label: 'Desbloquear Cuenta',
                          onTap: () => _handleUnblock(provider),
                        ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: AdminActionCard(
                    label: 'Ver Perfil',
                    isDisabled: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : backgroundGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
          style: TextStyle(
            color: isDark ? Colors.white : darkGray, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white54 : textGray),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : textGray
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRating(double rating) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : darkGray
          ),
        ),
      ],
    );
  }

  void _showFiltersModal() {
    final categories = ['Todos', ..._providers.map((p) => p.category).toSet()];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtrar Proveedores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Categoría', style: TextStyle(fontSize: 14, color: textGray)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _selectedCategory == c,
                      onSelected: (val) {
                        setModalState(() => _selectedCategory = c);
                        setState(() {
                          _selectedCategory = c;
                          _applyFilters();
                        });
                      },
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('APLICAR FILTROS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
