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

  Future<void> _toggleProviderStatus(ProviderModel provider) async {
    final bool newStatus = !provider.isActive;
    final String statusString = newStatus ? 'activo' : 'inactivo';

    setState(() => _isProcessing = true);

    try {
      // Intento de actualización real basado en el método añadido a AuthService
      final result = await _authService.actualizarEstadoProveedor(
          int.tryParse(provider.id) ?? 0, statusString);

      if (result['success']) {
        await _auditService.logAction(
          newStatus ? 'ACTIVACIÓN PROVEEDOR' : 'SUSPENSIÓN PROVEEDOR',
          'El proveedor ${provider.name} (#${provider.id}) ha sido marcado como $statusString.'
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Proveedor ${provider.name} ahora está $statusString'),
              backgroundColor: newStatus ? successGreen : Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadProviders();
      } else {
        // Si el endpoint no existe o falla, seguimos la instrucción del usuario
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionalidad en desarrollo: Pendiente de integración con API de estados completa'),
              backgroundColor: primaryBlue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
          );
        }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
                AdminDataBadge.status(provider.isActive ? 'ACTIVO' : 'INACTIVO'),
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
                  child: AdminActionCard(
                    label: provider.isActive ? 'Desactivar Cuenta' : 'Activar Cuenta',
                    onTap: () => _toggleProviderStatus(provider),
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
