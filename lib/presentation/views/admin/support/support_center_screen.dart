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
  ];

  final List<Map<String, dynamic>> contactMethods = [
    {'title': 'Correo de Soporte', 'subtitle': 'soporte@servizone.com', 'icon': Icons.email_rounded, 'color': const Color(0xFF1976D2), 'action': 'email'},
    {'title': 'Teléfono Principal', 'subtitle': '+57 (4) 444-5555', 'icon': Icons.phone_rounded, 'color': const Color(0xFF388E3C), 'action': 'phone'},
    {'title': 'WhatsApp Soporte', 'subtitle': '+57 300 123 4567', 'icon': Icons.chat_rounded, 'color': const Color(0xFF25D366), 'action': 'whatsapp'},
    {'title': 'Chat en Vivo', 'subtitle': 'Disponible 24/7', 'icon': Icons.support_agent_rounded, 'color': const Color(0xFF6A1B9A), 'action': 'chat'},
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

  Widget _buildContent() {
    return Column(children: contactMethods.map(_buildContactCard).toList());
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


