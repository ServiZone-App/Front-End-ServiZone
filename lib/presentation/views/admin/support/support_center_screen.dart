import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/constants/app_constants.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int selectedCategory = 0;

  final List<Map<String, dynamic>> supportCategories = [
    {'title': 'Contacto Directo', 'icon': Icons.contact_support_rounded, 'color': const Color(0xFF2E7D32)},
    {'title': 'Documentación', 'icon': Icons.description_rounded, 'color': const Color(0xFF7B1FA2)},
    {'title': 'Herramientas', 'icon': Icons.build_rounded, 'color': const Color(0xFFE65100)},
    {'title': 'Estadísticas', 'icon': Icons.analytics_rounded, 'color': const Color(0xFFC2185B)},
  ];

  final List<Map<String, dynamic>> contactMethods = [
    {'title': 'Correo de Soporte', 'subtitle': 'soporte@servizone.com', 'icon': Icons.email_rounded, 'color': const Color(0xFF1976D2), 'action': 'email'},
    {'title': 'Teléfono Principal', 'subtitle': '+57 (4) 444-5555', 'icon': Icons.phone_rounded, 'color': const Color(0xFF388E3C), 'action': 'phone'},
    {'title': 'WhatsApp Soporte', 'subtitle': '+57 300 123 4567', 'icon': Icons.chat_rounded, 'color': const Color(0xFF25D366), 'action': 'whatsapp'},
    {'title': 'Chat en Vivo', 'subtitle': 'Disponible 24/7', 'icon': Icons.support_agent_rounded, 'color': const Color(0xFF6A1B9A), 'action': 'chat'},
  ];

  final List<Map<String, dynamic>> documentationItems = [
    {'title': 'Manual de Administrador', 'subtitle': 'Guía completa para administradores', 'icon': Icons.admin_panel_settings_rounded, 'color': const Color(0xFF1565C0)},
    {'title': 'API Documentation', 'subtitle': 'Documentación técnica de APIs', 'icon': Icons.code_rounded, 'color': const Color(0xFF7B1FA2)},
    {'title': 'Base de Conocimientos', 'subtitle': 'Artículos y tutoriales', 'icon': Icons.library_books_rounded, 'color': const Color(0xFF388E3C)},
    {'title': 'Políticas y Términos', 'subtitle': 'Documentos legales y políticas', 'icon': Icons.gavel_rounded, 'color': const Color(0xFFD84315)},
  ];

  final List<Map<String, dynamic>> toolsItems = [
    {'title': 'Monitor del Sistema', 'subtitle': 'Estado en tiempo real', 'icon': Icons.monitor_heart_rounded, 'color': const Color(0xFF00897B)},
    {'title': 'Generador de Reportes', 'subtitle': 'Crear reportes personalizados', 'icon': Icons.summarize_rounded, 'color': const Color(0xFF5E35B1)},
    {'title': 'Respaldo de Datos', 'subtitle': 'Gestión de copias de seguridad', 'icon': Icons.backup_rounded, 'color': const Color(0xFF1976D2)},
    {'title': 'Logs del Sistema', 'subtitle': 'Historial de eventos', 'icon': Icons.list_alt_rounded, 'color': const Color(0xFFE64A19)},
  ];

  final List<Map<String, dynamic>> statsItems = [
    {'title': 'Usuarios Activos', 'value': '2,847', 'change': '+12%', 'icon': Icons.group_rounded, 'color': const Color(0xFF4CAF50), 'trending': true},
    {'title': 'Tickets Abiertos', 'value': '23', 'change': '-8%', 'icon': Icons.support_rounded, 'color': const Color(0xFFFF9800), 'trending': false},
    {'title': 'Tiempo de Respuesta', 'value': '2.3h', 'change': '-15%', 'icon': Icons.timer_rounded, 'color': primaryBlue, 'trending': false},
    {'title': 'Satisfacción', 'value': '98.5%', 'change': '+2%', 'icon': Icons.sentiment_very_satisfied_rounded, 'color': const Color(0xFF4CAF50), 'trending': true},
  ];

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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copiado: $text'), backgroundColor: primaryBlue, behavior: SnackBarBehavior.floating),
    );
  }

  void _handleContactAction(String action, String value) {
    switch (action) {
      case 'email': _copyToClipboard(value); break;
      case 'phone': case 'whatsapp': _copyToClipboard(value); break;
      case 'chat': ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo chat en vivo...'), backgroundColor: primaryBlue, behavior: SnackBarBehavior.floating)); break;
    }
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: supportCategories.length,
        itemBuilder: (context, index) {
          final cat = supportCategories[index];
          final isSelected = selectedCategory == index;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => selectedCategory = index);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? cat['color'] : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: isSelected ? cat['color'].withValues(alpha: 0.3) : cardShadow, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Icon(cat['icon'], color: isSelected ? Colors.white : cat['color']),
                  const SizedBox(width: 8),
                  Text(cat['title'], style: TextStyle(color: isSelected ? Colors.white : darkGray, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10)]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleContactAction(contact['action'], contact['subtitle']),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: contact['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(contact['icon'], color: contact['color']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGray)),
                      const SizedBox(height: 4),
                      Text(contact['subtitle'], style: const TextStyle(fontSize: 14, color: textGray)),
                    ],
                  ),
                ),
                const Icon(Icons.content_copy_rounded, color: textGray),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentationCard(Map<String, dynamic> doc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10)]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Abriendo: ${doc['title']}'), backgroundColor: primaryBlue, behavior: SnackBarBehavior.floating));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: doc['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(doc['icon'], color: doc['color']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGray)),
                      const SizedBox(height: 4),
                      Text(doc['subtitle'], style: const TextStyle(fontSize: 14, color: textGray)),
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

  Widget _buildToolCard(Map<String, dynamic> tool) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10)]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Iniciando: ${tool['title']}'), backgroundColor: primaryBlue, behavior: SnackBarBehavior.floating));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: tool['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(tool['icon'], color: tool['color']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tool['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGray)),
                      const SizedBox(height: 4),
                      Text(tool['subtitle'], style: const TextStyle(fontSize: 14, color: textGray)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: tool['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('ABRIR', style: TextStyle(color: tool['color'], fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
        itemCount: statsItems.length,
        itemBuilder: (context, index) {
          final stat = statsItems[index];
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: stat['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(stat['icon'], color: stat['color']),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: stat['trending'] ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(stat['trending'] ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: stat['trending'] ? Colors.green : Colors.red),
                          const SizedBox(width: 4),
                          Text(stat['change'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stat['trending'] ? Colors.green : Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(stat['value'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkGray)),
                const SizedBox(height: 4),
                Text(stat['title'], style: const TextStyle(fontSize: 14, color: textGray)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedCategory) {
      case 0: return Column(children: contactMethods.map(_buildContactCard).toList());
      case 1: return Column(children: documentationItems.map(_buildDocumentationCard).toList());
      case 2: return Column(children: toolsItems.map(_buildToolCard).toList());
      case 3: return _buildStatsGrid();
      default: return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.support_agent_rounded, color: primaryBlue),
                  ),
                  const SizedBox(width: 16),
                  const Text('Centro de Soporte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGray)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: Colors.green),
                        SizedBox(width: 8),
                        Text('En Línea', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildCategoryTabs(),
            const SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: _buildContent())),
          ],
        ),
      ),
    );
  }
}


