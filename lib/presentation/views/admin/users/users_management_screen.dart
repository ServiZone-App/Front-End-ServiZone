import 'package:flutter/material.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/models/user_model.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/presentation/views/admin/shared/admin_shared_widgets.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final List<User> _users = [];
  final List<User> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = locator<AuthService>();

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String _searchQuery = '';
  // usuarioId → estado real del proveedor (desde Lista-de-Proveedores)
  Map<int, String> _proveedorEstados = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _authService.getAllUsuarios(),
        _authService.getProveedoresVerificados(),
      ]);

      final usersResult = results[0];
      final proveedoresResult = results[1];

      // Construir mapa usuarioId → estado desde el endpoint de proveedores
      final Map<int, String> provEstados = {};
      if (proveedoresResult['success'] == true) {
        final List<dynamic> provData = proveedoresResult['data'] ?? [];
        for (final item in provData) {
          if (item is Map<String, dynamic>) {
            final rawId = item['usuarioId'] ?? item['UsuarioId'];
            final rawEstado = item['estado'] ?? item['Estado'];
            if (rawId != null && rawEstado != null) {
              final id = rawId is int ? rawId : int.tryParse(rawId.toString());
              if (id != null) provEstados[id] = rawEstado.toString();
            }
          }
        }
      }

      if (usersResult['success']) {
        final List<dynamic> data = usersResult['data'] ?? [];
        if (mounted) {
          setState(() {
            _proveedorEstados = provEstados;
            _users.clear();
            _users.addAll(data.map((e) => User.fromJson(e)).toList());
            _applyFilter(_searchQuery);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = usersResult['message'];
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

  bool _isProveedor(User user) =>
      user.roles.any((r) => r.toLowerCase() == 'proveedor' || r.toLowerCase() == 'provider');

  /// Devuelve el estado efectivo del usuario.
  /// Para proveedores usa el valor cruzado con Lista-de-Proveedores; para el resto, user.estado.
  String _effectiveEstado(User user) {
    if (_isProveedor(user)) {
      final id = int.tryParse(user.id);
      if (id != null && _proveedorEstados.containsKey(id)) {
        return _proveedorEstados[id]!;
      }
    }
    return user.estado;
  }

  void _applyFilter(String query) {
    _searchQuery = query;
    _filteredUsers.clear();
    if (query.isEmpty) {
      _filteredUsers.addAll(_users);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredUsers.addAll(_users.where((u) =>
        u.name.toLowerCase().contains(lowerQuery) ||
        u.email.toLowerCase().contains(lowerQuery) ||
        u.phone.contains(query)
      ));
    }
  }

  Future<void> _handleToggleBlock(User user, bool block, StateSetter setModalState) async {
    setState(() => _isProcessing = true);
    try {
      final result = await _authService.actualizarEstadoUsuario(
        int.parse(user.id),
        block ? 2 : 0,
      );
      if (result['success']) {
        user.isActive = !block;
        user.estado = block ? 'bloqueado' : 'activo';
        if (_isProveedor(user)) {
          final id = int.tryParse(user.id);
          if (id != null) _proveedorEstados[id] = user.estado;
        }
        setState(() {});
        if (mounted) {
          Navigator.pop(context); // cierra el modal de detalle
          _showBlockActionResult(blocked: block, userName: user.name);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error crítico: $e'), backgroundColor: errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showBlockActionResult({required bool blocked, required String userName}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (blocked ? errorRed : successGreen).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                blocked ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                color: blocked ? errorRed : successGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              blocked ? 'Cuenta Bloqueada' : 'Cuenta Activada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : darkGray,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              blocked
                  ? 'La cuenta de $userName fue bloqueada. El usuario no podrá iniciar sesión.'
                  : 'La cuenta de $userName fue activada. El usuario puede iniciar sesión nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : textGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blocked ? errorRed : successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
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
              title: 'Gestión Usuarios',
              subtitle: 'Administración de la base de clientes activos',
              action: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: primaryBlue),
                onPressed: _loadUsers,
                tooltip: 'Refrescar lista',
              ),
            ),
          ),
          body: Column(
            children: [
              AdminSearchBar(
                controller: _searchController,
                hintText: 'Buscar por nombre, correo o teléfono...',
                onChanged: (val) => setState(() => _applyFilter(val)),
              ),
              Expanded(
                child: _isLoading
                    ? const AdminLoadingOverlay()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _filteredUsers.isEmpty
                            ? const AdminEmptyState(
                                icon: Icons.people_outline_rounded,
                                title: 'Sin usuarios',
                                subtitle: 'No se encontraron clientes que coincidan con los criterios de búsqueda.',
                              )
                            : _buildUserList(),
              ),
            ],
          ),
        ),
        if (_isProcessing) const AdminLoadingOverlay(),
      ],
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: errorRed),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: isDark ? Colors.white70 : textGray),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadUsers, child: const Text('REINTENTAR')),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
    );
  }

  Widget _buildUserCard(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserDetails(user),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildAvatar(user.name),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : darkGray,
                            ),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : textGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AdminDataBadge.status(_effectiveEstado(user)),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    _buildInfoItem(Icons.phone_rounded, user.phone.isNotEmpty ? user.phone : '—'),
                    const SizedBox(width: 16),
                    if (user.documento.isNotEmpty)
                      Flexible(child: _buildInfoItem(Icons.badge_rounded, user.documento)),
                    const Spacer(),
                    if (user.roles.isNotEmpty)
                      AdminDataBadge.status(_primaryRole(user.roles)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textGray),
                  ],
                ),
              ],
            ),
          ),
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
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
          style: TextStyle(
            color: isDark ? Colors.white : darkGray,
            fontWeight: FontWeight.bold,
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
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : textGray),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showUserDetails(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildAvatar(user.name),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : darkGray,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${user.id}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AdminDataBadge.status(_effectiveEstado(user)),
                            if (user.roles.isNotEmpty)
                              AdminDataBadge.status(_primaryRole(user.roles)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildDetailField('Correo electrónico', user.email.isNotEmpty ? user.email : '—'),
                        _buildDetailField('Teléfono', user.phone.isNotEmpty ? user.phone : '—'),
                        _buildDetailField('Documento', user.documento.isNotEmpty ? user.documento : '—'),
                        const SizedBox(height: 16),
                        // Botones de bloqueo / activación
                        if (_effectiveEstado(user) == 'activo')
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _handleToggleBlock(user, true, setModalState),
                              icon: const Icon(Icons.block_rounded, size: 18),
                              label: const Text('BLOQUEAR CUENTA', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: errorRed,
                                side: const BorderSide(color: errorRed),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _handleToggleBlock(user, false, setModalState),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text('ACTIVAR CUENTA', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: successGreen,
                                side: const BorderSide(color: successGreen),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('CERRAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Devuelve el rol más relevante para mostrar en el badge.
  /// Prioridad: Admin > Proveedor > el primero de la lista.
  String _primaryRole(List<String> roles) {
    if (roles.isEmpty) return '';
    const priority = ['admin', 'administrador', 'proveedor', 'provider'];
    for (final p in priority) {
      final match = roles.firstWhere(
        (r) => r.toLowerCase() == p,
        orElse: () => '',
      );
      if (match.isNotEmpty) return match;
    }
    return roles.first;
  }

  Widget _buildDetailField(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : textGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : darkGray),
          ),
        ],
      ),
    );
  }
}
