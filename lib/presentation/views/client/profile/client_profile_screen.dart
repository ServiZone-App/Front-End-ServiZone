import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/routes/app_routes.dart';
import 'package:servizone_app/presentation/views/client/profile/edit_profile_screen.dart';
import 'package:servizone_app/presentation/views/common/booking_history_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ClientProfileScreen({super.key, required this.onLogout});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  String _userName = 'Usuario';
  bool _isSwitchingRole = false;

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
          _userName = 'Usuario Cliente';
        }
      });
    }
  }

  String _getInitials(String name) {
    String trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    List<String> parts = trimmed.split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + (parts[1].isNotEmpty ? parts[1].substring(0, 1) : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
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
                      color: primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.3),
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
                              color: primaryBlue,
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

            // Opción Información personal (sin título duplicado)
            _buildOptionTile(
              icon: Icons.edit_rounded,
              title: 'Información personal',
              color: primaryBlue,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            _buildSectionTitle('Preferencias'),
            _buildOptionTile(
              icon: Icons.history_rounded,
              title: 'Historial de reservas',
              color: primaryBlue,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingHistoryScreen(isProvider: false),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            _buildSectionTitle('Soporte y ayuda', icon: Icons.support_agent_rounded),
            _buildOptionTile(
              icon: Icons.email_rounded,
              title: 'Correo de Soporte',
              subtitle: 'soporte@servizone.com',
              color: successGreen,
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
              color: successGreen,
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
              title: _isSwitchingRole ? 'Cambiando...' : 'Cambiar a proveedor',
              color: primaryBlue,
              isLoading: _isSwitchingRole,
              onTap: _isSwitchingRole
                  ? null
                  : () async {
                      HapticFeedback.lightImpact();
                      setState(() => _isSwitchingRole = true);

                      final authService = locator<AuthService>();
                      final result = await authService.switchRole('proveedor');

                      if (!context.mounted) return;
                      setState(() => _isSwitchingRole = false);

                      if (result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sesión cambiada a Proveedor'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pushReplacementNamed(context, AppRoutes.providerHome);
                      } else if (result['requiresProviderApplication'] == true) {
                        // No tiene el rol Proveedor → ir al formulario de solicitud
                        Navigator.pushNamed(context, AppRoutes.providerRequest);
                      } else {
                        // Error del backend con mensaje (tiene el rol pero falla otra cosa)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'No se pudo cambiar el rol'),
                            backgroundColor: errorRed,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
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
              widget.onLogout();
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
    required VoidCallback? onTap,
    bool isLoading = false,
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
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
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
              color: textGray,
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
                          color: textGray,
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
}
