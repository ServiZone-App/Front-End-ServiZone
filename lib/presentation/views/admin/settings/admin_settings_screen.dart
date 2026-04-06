import 'package:flutter/material.dart';
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
              _buildSectionHeader('Preferencias', Icons.palette_rounded),
              _buildActionCard(title: 'Idioma', subtitle: 'Cambia el idioma', icon: Icons.language_rounded, iconColor: const Color(0xFF00BCD4), onTap: _showLanguageSelector, actionText: selectedLanguage),
              _buildSectionHeader('Acciones', Icons.build_rounded),
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


