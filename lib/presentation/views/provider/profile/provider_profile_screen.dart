import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/core/routes/app_routes.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/presentation/views/provider/profile/provider_edit_profile_screen.dart';

import 'package:servizone_app/presentation/views/common/booking_history_screen.dart';
import 'package:servizone_app/presentation/widgets/shared/provider_bottom_nav.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  String _userName = 'Usuario';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() {
    final data = locator<AuthService>().currentUserProfile;
    if (data != null && mounted) {
      setState(() {
        _userName = "${data['nombre'] ?? data['Nombre'] ?? ''} ${data['apellido'] ?? data['Apellido'] ?? ''}".trim();
        if (_userName.isEmpty) {
          _userName = 'Usuario Proveedor';
        }
      });
    }
  }

  String _getInitials(String name) {
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _performLogout() async {
    locator<CatalogNotifier>().clearProviderSession();
    await locator<AuthService>().logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  void _showChangeRoleConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cambiar a cliente'),
        content: const Text(
          '¿Estás seguro de que deseas cambiar a cliente? Perderás los privilegios de proveedor y serás redirigido a la interfaz de cliente.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // cerrar diálogo
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: primaryBlue)),
              );

              final result = await locator<AuthService>().switchRole('cliente');
              
              if (!mounted) return;
              Navigator.pop(context); // cerrar loading

              if (result['success'] == true) {
                // Limpiar pila y navegar a cliente
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.clientHome,
                  (route) => false,
                );
              } else {
                if (result['statusCode'] == 401) {
                  await _performLogout();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Error al cambiar de rol'), 
                      backgroundColor: errorRed,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textGray,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: cardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: successGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: successGreen.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_userName),
                            style: const TextStyle(
                              color: successGreen,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textGray,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Información personal
            _buildSectionTitle('Información personal'),
            _buildOptionTile(
              icon: Icons.person_rounded,
              title: 'Información personal',
              color: primaryBlue,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderEditProfileScreen(),
                  ),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.history_rounded,
              title: 'Historial de reservas',
              color: primaryBlue,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingHistoryScreen(isProvider: true),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Soporte y ayuda
            _buildSectionTitle('Soporte y ayuda', icon: Icons.support_agent_rounded),
            _buildOptionTile(
              icon: Icons.email_rounded,
              title: 'Correo de Soporte',
              subtitle: 'soporte@servizone.com',
              color: Colors.green,
              onTap: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(const ClipboardData(text: 'soporte@servizone.com'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Correo copiado al portapapeles'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.phone_rounded,
              title: 'Teléfono principal',
              subtitle: '+57 (4) 444-5555',
              color: primaryBlue,
              onTap: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(const ClipboardData(text: '+57 (4) 444-5555'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teléfono copiado al portapapeles'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.chat_rounded,
              title: 'WhatsApp',
              subtitle: '+57 300 123 4567',
              color: Colors.green,
              onTap: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(const ClipboardData(text: '+57 300 123 4567'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Número copiado al portapapeles'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            _buildActionButton(
              title: 'Cambiar a cliente',
              color: primaryBlue,
              onTap: _showChangeRoleConfirmation,
            ),

            const SizedBox(height: 16),

            _buildActionButton(
              title: 'Cerrar sesión',
              color: errorRed,
              onTap: () {
                HapticFeedback.heavyImpact();
                _showLogoutDialog();
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: const ProviderBottomNav(currentIndex: 4),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: primaryBlue),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: textGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: textGray, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Deleted extra private widgets

}


