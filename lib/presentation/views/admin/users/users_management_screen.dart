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
  String? _errorMessage;
  String _searchQuery = '';

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
      final result = await _authService.getAllUsuarios();
      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        if (mounted) {
          setState(() {
            _users.clear();
            _users.addAll(data.map((e) => User.fromJson(e)).toList());
            _applyFilter(_searchQuery);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
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
            style: TextStyle(color: isDark ? Colors.white70 : textGray)
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
                          color: isDark ? Colors.white : darkGray
                        ),
                      ),
                      Text(
                        user.email, 
                        style: TextStyle(
                          fontSize: 13, 
                          color: isDark ? Colors.white70 : textGray
                        )
                      ),
                    ],
                  ),
                ),
                AdminDataBadge.status(user.isActive ? 'ACTIVO' : 'INACTIVO'),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                _buildInfoItem(Icons.phone_rounded, user.phone),
                const SizedBox(width: 24),
                _buildInfoItem(Icons.cake_rounded, '${user.age} años'),
                const Spacer(),
                if (user.isPremium) 
                  const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: AdminActionCard(
                    label: 'Suspender Usuario',
                    isDisabled: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminActionCard(
                    label: 'Detalles Cuenta',
                    onTap: () {
                      _showUserDetails(user);
                    },
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
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
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
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white54 : textGray),
        const SizedBox(width: 8),
        Text(
          text, 
          style: TextStyle(
            fontSize: 13, 
            color: isDark ? Colors.white54 : textGray
          )
        ),
      ],
    );
  }

  void _showUserDetails(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(user.name),
                const SizedBox(width: 16),
                Text(
                  user.name, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : darkGray
                  )
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailField('Dirección', user.address),
            _buildDetailField('Miembro desde', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
            const SizedBox(height: 24),
            Row(
              children: [
                AdminDataBadge.status(user.isActive ? 'ACTIVO' : 'INACTIVO'),
                const SizedBox(width: 8),
                AdminDataBadge.status(user.isVerified ? 'VERIFICADO' : 'NO VERIFICADO'),
                const SizedBox(width: 8),
                if (user.isPremium) AdminDataBadge.status('PREMIUM'),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('CERRAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
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
              fontWeight: FontWeight.bold
            )
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: TextStyle(
              fontSize: 14, 
              color: isDark ? Colors.white : darkGray
            )
          ),
        ],
      ),
    );
  }
}
