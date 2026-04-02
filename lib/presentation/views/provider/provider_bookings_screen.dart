import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/data/models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/presentation/widgets/shared/provider_bottom_nav.dart';
import 'package:servizone_app/presentation/widgets/shared/status_badge.dart';
import 'package:servizone_app/presentation/widgets/shared/booking_detail_sheet.dart';
import 'package:servizone_app/domain/repositories/auth_repository.dart';
import 'package:servizone_app/presentation/viewmodels/booking_view_model.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  late final BookingViewModel _vm;
  int? _proveedorId;
  final TextEditingController _searchController = TextEditingController();

  final int _monthsFilter = 1;
  BookingStatus? _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _vm = locator<BookingViewModel>();
    _vm.addListener(_onServiceUpdate);
    _load();
  }

  @override
  void dispose() {
    _vm.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    setState(() {});
  }

  Future<void> _load() async {
    final authRepo = locator<AuthRepository>();
    final res = await authRepo.getCurrentProveedorId();
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() => _proveedorId = res.data);
      await _vm.loadProviderBookings(res.data!);
    } else {
      setState(() => _proveedorId = null);
      _vm.setError(res.message.isNotEmpty ? res.message : 'No se pudo verificar tu ID de proveedor. Contacta a soporte.');
    }
  }

  void _shareToWhatsApp(BookingModel booking) async {
    final text = 'Hola ${booking.clientName}, te escribo de ServiZone por tu reserva de ${booking.serviceName} para el ${DateFormat('dd/MM/yyyy').format(booking.date)} a las ${DateFormat('hh:mm a').format(booking.date)} en la dirección: ${booking.address}.';
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
      }
    }
  }

  List<BookingModel> get _allFilteredBookings {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: 30 * _monthsFilter));
    return _vm.bookings.where((b) {
      final within = b.date.isAfter(cutoff);
      if (!within) return false;
      if (_statusFilter != null && b.status != _statusFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final hay = '${b.clientName} ${b.serviceName} ${b.address}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  void _showBookingDetails(BookingModel booking) {
    Widget? actionButtons;
    if (booking.status != BookingStatus.rechazada) {
      actionButtons = Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _shareToWhatsApp(booking),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              child: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
            ),
          ),
          if (booking.status == BookingStatus.confirmada) ...[
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  try {
                    final proveedorId = _proveedorId;
                    if (proveedorId == null) {
                      throw Exception('No se pudo obtener el ID del proveedor.');
                    }
                    _vm.complete(booking.id, proveedorId);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Servicio marcado como completado'), backgroundColor: successGreen));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: errorRed));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: successGreen),
                child: const Text('Completar', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ],
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingDetailSheet(
        booking: booking,
        isProvider: true,
        actionButtons: actionButtons,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        backgroundColor: Colors.white,
        foregroundColor: textGray,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _allFilteredBookings.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _allFilteredBookings.length,
                    itemBuilder: (context, index) => _buildBookingCard(_allFilteredBookings[index]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const ProviderBottomNav(currentIndex: 3),
    );
  }



  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtros de Reservas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textGray)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  _buildStatusFilterChip('Todas', _statusFilter == null, () => setModalState(() => _statusFilter = null)),
                  _buildStatusFilterChip('Confirmadas', _statusFilter == BookingStatus.confirmada, () => setModalState(() => _statusFilter = BookingStatus.confirmada)),
                  _buildStatusFilterChip('Completadas', _statusFilter == BookingStatus.completada, () => setModalState(() => _statusFilter = BookingStatus.completada)),
                  _buildStatusFilterChip('Rechazadas', _statusFilter == BookingStatus.rechazada, () => setModalState(() => _statusFilter = BookingStatus.rechazada)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: primaryBlue.withValues(alpha: 0.1),
      checkmarkColor: primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? primaryBlue : textGray,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: isSelected ? primaryBlue : Colors.transparent),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBookingDetails(booking),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.serviceName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(status: booking.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: textGray),
                    const SizedBox(width: 8),
                    Text(booking.clientName, style: const TextStyle(color: textGray)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: textGray),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd MMM yyyy, hh:mm a').format(booking.date), style: const TextStyle(color: textGray)),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  '\$${NumberFormat('#,###').format(booking.price)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: textGray),
        decoration: InputDecoration(
          hintText: 'Buscar por servicio o cliente...',
          hintStyle: const TextStyle(color: textGray, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: textGray),
          filled: true,
          fillColor: backgroundGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_rounded, size: 80, color: primaryBlue.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No hay reservas registradas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGray)),
        ],
      ),
    );
  }
}
