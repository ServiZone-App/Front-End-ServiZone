import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/routes/app_routes.dart';
import 'users/users_management_screen.dart';
import 'providers/providers_management_screen.dart';
import 'providers/provider_requests_screen.dart';

import 'reports/reports_dashboard_screen.dart';
import 'support/support_center_screen.dart';
import 'settings/admin_settings_screen.dart';
import 'category_management_screen.dart';
import 'reports/audit_logs_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? userName;
  const AdminDashboardScreen({super.key, this.userName});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _displayName = 'Usuario';
  int _selected = 0;

  final List<_MenuItem> _items = const [
    _MenuItem('Gestión Usuarios', Icons.group_rounded, Color(0xFF2E7D32)),
    _MenuItem('Solicitudes Proveedores', Icons.person_add_rounded, purple),
    _MenuItem('Gestión Proveedores', Icons.business_rounded, Color(0xFFE65100)),
    _MenuItem('Catálogo y Servicios', Icons.category_rounded, primaryBlue),
    _MenuItem('Reportes', Icons.analytics_rounded, Color(0xFFC2185B)),
    _MenuItem('Logs de Auditoría', Icons.security_rounded, Colors.blueGrey),
    _MenuItem('Soporte', Icons.support_agent_rounded, Color(0xFFD32F2F)),
    _MenuItem('Configuración', Icons.settings_rounded, Color(0xFF455A64)),
  ];

  late final List<Widget> _screens = [
    const UsersManagementScreen(),
    const ProviderRequestsScreen(),
    const ProvidersManagementScreen(),
    const CategoryManagementScreen(),
    const ReportsDashboardScreen(),
    const AuditLogsScreen(),
    const SupportCenterScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _displayName = widget.userName ?? prefs.getString('user_name') ?? 'Usuario';
      });
    } catch (e) {
      setState(() => _displayName = 'Usuario');
    }
  }

  void _cerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cerrar sesión?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Se cerrará tu sesión de administrador'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 768;
        bool isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: isDark ? const Color(0xFF121212) : lightGray,
          drawer: isMobile ? _buildDrawer() : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!isMobile) _buildSidebar(isTablet),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeader(isMobile),
                      Container(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
                      Expanded(
                        child: Container(
                          color: isDark ? const Color(0xFF121212) : lightGray,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: _screens[_selected],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(bool isCollapsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double width = isCollapsed ? 80 : 280;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: isDark ? null : [const BoxShadow(color: cardShadow, blurRadius: 20, offset: Offset(4, 0))],
        border: isDark ? Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))) : null,
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          if (!isCollapsed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: purple,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, size: 40, color: purple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_displayName,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : darkGray),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Administrador', style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 24), color: isDark ? Colors.white10 : Colors.grey.shade200),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                final selected = i == _selected;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selected = i);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: selected ? item.color : item.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item.icon, size: 20, color: selected ? Colors.white : item.color),
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                    color: selected ? (isDark ? Colors.white : primaryBlue) : (isDark ? Colors.white70 : darkGray),
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (selected)
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(isCollapsed ? 8 : 24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _cerrarSesion(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: errorRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: errorRed, size: 20),
                      if (!isCollapsed) ...[
                        const SizedBox(width: 12),
                        const Text('Cerrar Sesión', style: TextStyle(color: errorRed, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: _buildSidebar(false),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 80,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.menu_rounded, color: primaryBlue),
              ),
            ),
          const SizedBox(width: 20),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                _items[_selected].label,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : darkGray,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Row(
            children: [
              _buildHeaderIndicator(icon: Icons.notifications_rounded, count: 3, color: Colors.orange),
              if (!isMobile) const SizedBox(width: 16),
              if (!isMobile) _buildHeaderIndicator(icon: Icons.message_rounded, count: 7, color: primaryBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIndicator({required IconData icon, required int count, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Stack(
        children: [
          Icon(icon, color: color, size: 24),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  const _MenuItem(this.label, this.icon, this.color);
}

