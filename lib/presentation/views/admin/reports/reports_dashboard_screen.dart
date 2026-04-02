import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/presentation/views/admin/shared/admin_shared_widgets.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String selectedPeriod = 'Último mes';
  bool isLoading = false;

  final List<Map<String, dynamic>> reportCategories = [
    {'title': 'Reportes de Ventas', 'subtitle': 'Ingresos y transacciones', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF4CAF50), 'count': '0', 'change': '0%', 'trending': true},
    {'title': 'Reportes de Usuarios', 'subtitle': 'Análisis de usuarios activos', 'icon': Icons.group_rounded, 'color': primaryBlue, 'count': '0', 'change': '0%', 'trending': true},
    {'title': 'Reportes de Proveedores', 'subtitle': 'Servicios y proveedores', 'icon': Icons.business_rounded, 'color': const Color(0xFFFF9800), 'count': '0', 'change': '0%', 'trending': false},
    {'title': 'Reportes de Publicaciones', 'subtitle': 'Contenido y engagement', 'icon': Icons.article_rounded, 'color': const Color(0xFF9C27B0), 'count': '0', 'change': '0%', 'trending': true},
    {'title': 'Reportes Financieros', 'subtitle': 'Estados financieros', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFF00BCD4), 'count': '0', 'change': '0%', 'trending': true},
    {'title': 'Reportes de Soporte', 'subtitle': 'Tickets y resoluciones', 'icon': Icons.support_agent_rounded, 'color': const Color(0xFFE91E63), 'count': '0', 'change': '0%', 'trending': false},
  ];

  final List<Map<String, dynamic>> quickStats = [
    {'title': 'Ingresos Totales', 'value': '\$0', 'icon': Icons.attach_money_rounded, 'color': const Color(0xFF4CAF50), 'percentage': '0%', 'trending': true},
    {'title': 'Servicios Activos', 'value': '0', 'icon': Icons.work_rounded, 'color': primaryBlue, 'percentage': '0%', 'trending': true},
    {'title': 'Tiempo Promedio', 'value': '0h', 'icon': Icons.timer_rounded, 'color': const Color(0xFFFF9800), 'percentage': '0%', 'trending': false},
    {'title': 'Satisfacción', 'value': '0/5', 'icon': Icons.star_rounded, 'color': const Color(0xFFE91E63), 'percentage': '0%', 'trending': true},
  ];

  final List<String> periods = ['Última semana', 'Último mes', 'Últimos 3 meses', 'Último año', 'Personalizado'];

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
    _loadRealStats();
  }

  Future<void> _loadRealStats() async {
    setState(() => isLoading = true);
    try {
      final authService = locator<AuthService>();
      final catalogNotifier = locator<CatalogNotifier>();

      // Cargar datos en paralelo
      final results = await Future.wait([
        authService.getAllUsuarios(),
        authService.getProveedoresVerificados(),
        authService.getSolicitudesProveedor(),
        catalogNotifier.loadAllServicios().then((_) => true),
      ]);

      if (mounted) {
        setState(() {
          // Usuarios
          final usersData = results[0] as Map<String, dynamic>;
          final usersCount = (usersData['data'] as List?)?.length ?? 0;
          reportCategories[1]['count'] = usersCount.toString();

          // Proveedores
          final providersData = results[1] as Map<String, dynamic>;
          final providersCount = (providersData['data'] as List?)?.length ?? 0;
          reportCategories[2]['count'] = providersCount.toString();

          // Solicitudes (Soporte fallback)
          final requestsData = results[2] as Map<String, dynamic>;
          final requestsCount = (requestsData['data'] as List?)?.length ?? 0;
          reportCategories[5]['count'] = requestsCount.toString();

          // Servicios Activos
          final servicesCount = catalogNotifier.allServicios.where((s) => s.estaActivo).length;
          quickStats[1]['value'] = servicesCount.toString();
          
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showPeriodSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Seleccionar Período', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGray)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: periods.map((p) => RadioListTile<String>(
            title: Text(p),
            value: p,
            groupValue: selectedPeriod,
            activeColor: primaryBlue,
            onChanged: (v) {
              if (v != null) {
                setState(() => selectedPeriod = v);
                Navigator.pop(context);
                _refreshData();
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _refreshData() {
    _loadRealStats();
  }

  void _generateReport(String reportType) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.summarize_rounded, color: primaryBlue),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Generar Reporte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGray))),
          ],
        ),
        content: Text('¿Deseas generar el reporte de $reportType para el período: $selectedPeriod?', style: const TextStyle(color: textGray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Generando reporte de $reportType...'), backgroundColor: primaryBlue, behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text('Generar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: quickStats.length,
        itemBuilder: (context, index) {
          final stat = quickStats[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, animation, child) => Transform.scale(
              scale: animation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? null : const [BoxShadow(color: cardShadow, blurRadius: 10)],
                  border: isDark ? Border.all(color: Colors.white10) : null,
                ),
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
                              Icon(stat['trending'] ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 12, color: stat['trending'] ? Colors.green : Colors.red),
                              const SizedBox(width: 4),
                              Text(stat['percentage'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stat['trending'] ? Colors.green : Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      stat['value'], 
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : darkGray
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['title'], 
                      style: TextStyle(
                        fontSize: 12, 
                        color: isDark ? Colors.white54 : textGray
                      )
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation)),
          child: Opacity(
            opacity: animation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? null : const [BoxShadow(color: cardShadow, blurRadius: 10)],
                border: isDark ? Border.all(color: Colors.white10) : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _generateReport(report['title']),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [report['color'], report['color'].withValues(alpha: 0.7)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: report['color'].withValues(alpha: 0.3), blurRadius: 10)],
                          ),
                          child: Icon(report['icon'], color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report['title'], 
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold, 
                                  color: isDark ? Colors.white : darkGray
                                )
                              ),
                              const SizedBox(height: 4),
                              Text(
                                report['subtitle'], 
                                style: TextStyle(
                                  fontSize: 14, 
                                  color: isDark ? Colors.white70 : textGray
                                )
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(report['count'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: report['color'])),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: report['trending'] ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      children: [
                                        Icon(report['trending'] ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: report['trending'] ? Colors.green : Colors.red),
                                        const SizedBox(width: 4),
                                        Text(report['change'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: report['trending'] ? Colors.green : Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white54 : textGray, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : lightGray,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primaryBlue.withValues(alpha: 0.1), 
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: const Icon(Icons.analytics_rounded, color: primaryBlue),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Dashboard de Reportes', 
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? Colors.white : darkGray
                            )
                          ),
                          const Spacer(),
                          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh_rounded, color: primaryBlue)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _showPeriodSelector,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C2C2C) : lightGray, 
                                  borderRadius: BorderRadius.circular(12), 
                                  border: Border.all(color: primaryBlue.withValues(alpha: 0.3))
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: primaryBlue),
                                    const SizedBox(width: 12),
                                    Text(
                                      selectedPeriod, 
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.w600, 
                                        color: isDark ? Colors.white : darkGray
                                      )
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_drop_down_rounded, color: primaryBlue),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Estadísticas Rápidas', 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? Colors.white : darkGray
                            )
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickStatsGrid(),
                        const SizedBox(height: 32),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Reportes Detallados', 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? Colors.white : darkGray
                            )
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...reportCategories.asMap().entries.map((e) => _buildReportCard(e.value, e.key)),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const AdminLoadingOverlay(),
        ],
      ),
    );
  }
}


