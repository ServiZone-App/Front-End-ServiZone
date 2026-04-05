import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/data/models/booking/reserva_dto.dart';
import 'package:servizone_app/presentation/viewmodels/solicitudes_reservas_view_model.dart';
import 'package:servizone_app/presentation/views/provider/services/provider_services_screen.dart';
import 'package:servizone_app/presentation/views/provider/provider_bookings_screen.dart';
import 'package:servizone_app/presentation/widgets/shared/provider_bottom_nav.dart';
import 'package:servizone_app/presentation/widgets/provider/create_service_bottom_sheet.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/data/models/catalog/servicio_proveedor_model.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  late final CatalogNotifier _notifier;
  late final SolicitudesReservasViewModel _reservasVm;
  String _userName = 'Usuario';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _notifier = locator<CatalogNotifier>();
    _notifier.addListener(_onChanged);
    _reservasVm = locator<SolicitudesReservasViewModel>();
    _reservasVm.addListener(_onChanged);
    _loadProviderData();
  }

  @override
  void dispose() {
    _notifier.removeListener(_onChanged);
    _reservasVm.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProviderData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = locator<AuthService>();
    final data = auth.currentUserProfile;
    if (data == null) {
      setState(() {
        _errorMessage = 'No se pudo cargar el perfil del proveedor. Intenta reiniciar sesión.';
        _isLoading = false;
      });
      return;
    }

    final name = "${data['nombre'] ?? data['Nombre'] ?? ''} ${data['apellido'] ?? data['Apellido'] ?? ''}".trim();
    setState(() {
      _userName = name.isNotEmpty ? name : 'Usuario Proveedor';
      _isLoading = false;
    });

    _notifier.loadServiciosDelProveedor(0);
    _reservasVm.cargarReservasProveedor();
  }

  void _showCreateServiceDialog() {
    CreateServiceBottomSheet.show(
      context,
      onServiceCreated: () {
        if (mounted) {
          _notifier.retryServiciosDelProveedor(0);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: const ProviderBottomNav(currentIndex: 0),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: errorRed, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: textGray),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              onPressed: _loadProviderData,
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            ),
          ],
        ),
      ),
    );
  }

  // ── Computed booking stats ───────────────────────────────────────────────

  List<ReservaDto> get _reservasEnProceso =>
      _reservasVm.reservasProveedor.where((r) => r.estado == 'en_proceso').toList();

  int get _totalReservas => _reservasVm.reservasProveedor.length;

  double get _totalIngresos => _reservasVm.reservasProveedor
      .where((r) => r.estado == 'completado')
      .fold(0.0, (sum, r) => sum + (r.precioAcordado ?? 0.0));

  String _formatCompact(double value) {
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}k';
    return '\$${NumberFormat('#,###').format(value)}';
  }

  Widget _buildContent() {
    final services = _notifier.serviciosProveedor;
    final ratingsConValor = services
        .map((s) => s.ratingPromedio)
        .where((r) => r != null && r > 0)
        .cast<double>()
        .toList();
    final double? avgRating = ratingsConValor.isEmpty
        ? null
        : ratingsConValor.fold(0.0, (a, b) => a + b) / ratingsConValor.length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Contenedor de bienvenida: fondo blanco, ocupa todo el ancho
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Text(
              'Bienvenido, $_userName!',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Divider(color: lightGray, thickness: 1),
                const SizedBox(height: 20),

                // Tarjeta de métricas
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetric(
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber,
                        value: avgRating == null ? 'Sin calificaciones' : avgRating.toStringAsFixed(1),
                        label: 'Calificación promedio',
                        small: avgRating == null,
                      ),
                      _buildVerticalDivider(),
                      _buildMetric(
                        icon: Icons.calendar_today_rounded,
                        iconColor: const Color(0xFF1976D2),
                        value: '$_totalReservas',
                        label: 'Total reservas',
                      ),
                      _buildVerticalDivider(),
                      _buildMetric(
                        icon: Icons.attach_money_rounded,
                        iconColor: const Color(0xFF2E7D32),
                        value: _formatCompact(_totalIngresos),
                        label: 'Ingresos',
                      ),
                      _buildVerticalDivider(),
                       _buildMetric(
                        icon: Icons.build_rounded,
                        iconColor: const Color(0xFF1976D2),
                        value: '${services.where((s) => s.estado).length}',
                        label: 'Servicios activos',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Botón Crear nuevo servicio
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _showCreateServiceDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Crear Nuevo Servicio',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                 _buildSectionTitle('Tus servicios'),
                const SizedBox(height: 12),

                _buildServicesSection(),

                const SizedBox(height: 8),
                Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProviderServicesScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Ver todos mis servicios >',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: textGray,
                    ),
                  ),
                ),
              ),
                const SizedBox(height: 32),

                _buildSectionTitle('Proximas reservas'),
                const SizedBox(height: 12),
                _buildUpcomingBookings(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool small = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: small ? 9 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 9, // Reducir un poco
              color: textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: lightGray,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    final upcoming = _reservasEnProceso;
    if (upcoming.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event_busy_rounded, color: primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sin reservas próximas',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando confirmes solicitudes, aquí verás tus próximas reservas.',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 13, color: textGray, height: 1.4),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProviderBookingsScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: const BorderSide(color: primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Ver reservas', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...upcoming.map((r) => _buildUpcomingCard(r)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProviderBookingsScreen()),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Ver todas las reservas', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingCard(ReservaDto r) {
    final date = r.fechaHoraReserva ?? r.fechaCreacion;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00796B).withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00796B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_rounded, color: Color(0xFF00796B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.nombreServicio ?? 'Servicio ${r.servicioProveedorId}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: textGray),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Cliente: ${r.clienteNombre.isNotEmpty ? r.clienteNombre : 'Desconocido'}',
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: textGray),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: textGray),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy - hh:mm a').format(date),
                      style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: textGray),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (r.precioAcordado != null) ...[
            const SizedBox(width: 8),
            Text(
              '\$${NumberFormat('#,###').format(r.precioAcordado)}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final state = _notifier.serviciosProveedorState;
    final services = _notifier.serviciosProveedor;

    if (state == CatalogLoadState.loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(color: primaryBlue),
      ));
    }

    if (services.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.build_circle_outlined, size: 48, color: mediumGray),
            SizedBox(height: 12),
            Text('No tienes servicios registrados', style: TextStyle(color: textGray)),
          ],
        ),
      );
    }

    // Mostrar solo los primeros 3
    final recent = services.take(3).toList();
    return Column(
      children: recent.map((s) => _buildServiceCard(s)).toList(),
    );
  }

  Widget _buildServiceCard(ServicioProveedor s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.build_rounded, color: primaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.nombreMostrado,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textGray),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${NumberFormat('#,###').format(s.precioBase)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: s.estado ? successGreen : errorRed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              s.estado ? 'Activo' : 'Inactivo',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

}
