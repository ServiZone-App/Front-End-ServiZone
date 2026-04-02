import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/constants/app_constants.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool notificationsEnabled = true;
  bool emailNotifications = true;
  bool pushNotifications = false;
  bool soundEnabled = true;
  bool autoBackup = true;
  bool twoFactorEnabled = false;
  String selectedLanguage = 'Español';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true, obscureNew = true, obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.lock_reset_rounded, color: primaryBlue),
              ),
              const SizedBox(width: 12),
              const Text('Cambiar Contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGray)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Contraseña actual',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryBlue),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                      ),
                      filled: true,
                      fillColor: lightGray,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_rounded, color: primaryBlue),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                      filled: true,
                      fillColor: lightGray,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
                    ),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Requerido';
                      if (v!.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: const Icon(Icons.lock_rounded, color: primaryBlue),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                      filled: true,
                      fillColor: lightGray,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
                    ),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Requerido';
                      if (v != newController.text) return 'No coinciden';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada'), backgroundColor: Colors.green));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final languages = ['Español', 'English', 'Português', 'Français'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Seleccionar Idioma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGray)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) => RadioListTile<String>(
            title: Text(lang),
            value: lang,
            groupValue: selectedLanguage,
            activeColor: primaryBlue,
            onChanged: (v) {
              setState(() => selectedLanguage = v!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Idioma cambiado a $v'), backgroundColor: primaryBlue));
            },
          )).toList(),
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(8)
            ),
            child: Icon(icon, color: primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title, 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : darkGray
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        boxShadow: isDark ? null : const [BoxShadow(color: cardShadow, blurRadius: 8)],
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600, 
                          color: isDark ? Colors.white : darkGray
                        )
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4), 
                        Text(
                          subtitle, 
                          style: TextStyle(
                            fontSize: 14, 
                            color: isDark ? Colors.white54 : textGray
                          )
                        )
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      trailing: Switch(value: value, onChanged: (v) { HapticFeedback.lightImpact(); onChanged(v); }, activeThumbColor: primaryBlue),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    String? actionText,
  }) {
    return _buildSettingCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (actionText != null) ...[Text(actionText, style: const TextStyle(fontSize: 14, color: textGray)), const SizedBox(width: 8)],
          const Icon(Icons.arrow_forward_ios_rounded, color: textGray, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : lightGray,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1), 
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: const Icon(Icons.settings_rounded, color: primaryBlue),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Configuración', 
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : darkGray
                      )
                    ),
                  ],
                ),
              ),
              _buildSectionHeader('Notificaciones', Icons.notifications_rounded),
              _buildSwitchCard(title: 'Notificaciones Generales', subtitle: 'Recibir todas las notificaciones', icon: Icons.notifications_active_rounded, iconColor: const Color(0xFF4CAF50), value: notificationsEnabled, onChanged: (v) => setState(() => notificationsEnabled = v)),
              _buildSwitchCard(title: 'Notificaciones por Email', subtitle: 'Recibir notificaciones en tu correo', icon: Icons.email_rounded, iconColor: primaryBlue, value: emailNotifications, onChanged: (v) => setState(() => emailNotifications = v)),
              _buildSwitchCard(title: 'Notificaciones Push', subtitle: 'Notificaciones instantáneas', icon: Icons.push_pin_rounded, iconColor: const Color(0xFFFF9800), value: pushNotifications, onChanged: (v) => setState(() => pushNotifications = v)),
              _buildSectionHeader('Seguridad', Icons.security_rounded),
              _buildActionCard(title: 'Cambiar Contraseña', subtitle: 'Actualiza tu contraseña', icon: Icons.lock_reset_rounded, iconColor: const Color(0xFFE91E63), onTap: _showChangePasswordDialog),
              _buildSwitchCard(title: 'Autenticación de Dos Factores', subtitle: 'Seguridad adicional', icon: Icons.security_rounded, iconColor: const Color(0xFF673AB7), value: twoFactorEnabled, onChanged: (v) => setState(() => twoFactorEnabled = v)),
              _buildSectionHeader('Preferencias', Icons.palette_rounded),
              _buildActionCard(title: 'Idioma', subtitle: 'Cambia el idioma', icon: Icons.language_rounded, iconColor: const Color(0xFF00BCD4), onTap: _showLanguageSelector, actionText: selectedLanguage),
              _buildSectionHeader('Sistema', Icons.storage_rounded),
              _buildSwitchCard(title: 'Respaldo Automático', subtitle: 'Copia de seguridad automática', icon: Icons.backup_rounded, iconColor: const Color(0xFF4CAF50), value: autoBackup, onChanged: (v) => setState(() => autoBackup = v)),
              _buildSwitchCard(title: 'Sonidos del Sistema', subtitle: 'Reproducir sonidos', icon: Icons.volume_up_rounded, iconColor: const Color(0xFFFF5722), value: soundEnabled, onChanged: (v) => setState(() => soundEnabled = v)),
              _buildSectionHeader('Acciones', Icons.build_rounded),
              _buildActionCard(title: 'Limpiar Caché', subtitle: 'Libera espacio', icon: Icons.cleaning_services_rounded, iconColor: const Color(0xFFFF9800), onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caché limpiado'), backgroundColor: Colors.green)); }),
              _buildActionCard(title: 'Exportar Datos', subtitle: 'Descargar copia', icon: Icons.download_rounded, iconColor: const Color(0xFF607D8B), onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iniciando exportación...'), backgroundColor: primaryBlue)); }),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
                  borderRadius: BorderRadius.circular(12), 
                  boxShadow: isDark ? null : const [BoxShadow(color: cardShadow, blurRadius: 8)],
                  border: isDark ? Border.all(color: Colors.white10) : null,
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: primaryBlue),
                        SizedBox(width: 12),
                        Text('Información de la Aplicación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkGray)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Versión:', style: TextStyle(color: isDark ? Colors.white54 : textGray)), 
                        Text('1.2.3', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : darkGray))
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Última actualización:', style: TextStyle(color: isDark ? Colors.white54 : textGray)), 
                        Text('15 Ene 2025', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : darkGray))
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}


