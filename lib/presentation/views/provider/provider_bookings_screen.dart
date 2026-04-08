import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/models/booking/resena_dto.dart';
import 'package:servizone_app/data/models/booking/reserva_dto.dart';
import 'package:servizone_app/data/models/booking_model.dart';
import 'package:servizone_app/presentation/viewmodels/solicitudes_reservas_view_model.dart';
import 'package:servizone_app/presentation/widgets/shared/booking_detail_sheet.dart';
import 'package:servizone_app/presentation/widgets/shared/provider_bottom_nav.dart';
import 'package:servizone_app/presentation/widgets/shared/status_badge.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  late final SolicitudesReservasViewModel _vm;
  final TextEditingController _searchController = TextEditingController();

  final int _monthsFilter = 1;
  String _searchQuery = '';

  // ── Helpers ──────────────────────────────────────────────────────────────

  BookingStatus _mapEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':   return BookingStatus.pendiente;
      case 'en_revision': return BookingStatus.enRevision;
      case 'en_proceso':  return BookingStatus.enProceso;
      case 'completado':  return BookingStatus.completada;
      case 'cancelado':   return BookingStatus.cancelada;
      case 'rechazada':   return BookingStatus.rechazada;
      default:            return BookingStatus.pendiente;
    }
  }

  BookingModel _toBookingModel(ReservaDto dto) {
    return BookingModel(
      id: dto.solicitudId.toString(),
      clientId: dto.clienteId.toString(),
      providerId: dto.proveedorId.toString(),
      clientName: dto.clienteNombre,
      providerName: dto.proveedorNombre,
      serviceType: dto.categoria ?? dto.nombreServicio ?? 'Servicio',
      serviceName: dto.nombreServicio ?? 'Servicio ${dto.servicioProveedorId}',
      date: dto.fechaHoraReserva ?? dto.fechaCreacion,
      address: dto.direccionCliente ?? '',
      price: dto.precioAcordado ?? 0.0,
      status: _mapEstado(dto.estado),
    );
  }

  @override
  void initState() {
    super.initState();
    _vm = locator<SolicitudesReservasViewModel>();
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
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await Future.wait([
      _vm.cargarReservasProveedor(),
      _vm.cargarMisResenasProveedor(),
    ]);
  }

  ResenaDto? _resenaParaSolicitud(int solicitudId) {
    final matching = _vm.misResenasProveedor
        .where((r) => r.solicitudId == solicitudId);
    return matching.isEmpty ? null : matching.first;
  }

  void _shareToWhatsApp(BookingModel booking) async {
    final text =
        'Hola ${booking.clientName}, te escribo de ServiZone por tu reserva de ${booking.serviceName}'
        '${booking.date.year > 2000 ? ' para el ${DateFormat('dd/MM/yyyy').format(booking.date)} a las ${DateFormat('hh:mm a').format(booking.date)}' : ''}'
        '${booking.address.isNotEmpty ? ' en la dirección: ${booking.address}' : ''}.';
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  List<BookingModel> get _allFilteredBookings {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: 30 * _monthsFilter));
    final mapped = _vm.reservasProveedor.map(_toBookingModel).toList();
    return mapped.where((b) {
      if (b.status != BookingStatus.enProceso) return false;
      if (!b.date.isAfter(cutoff)) return false;
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

    if (booking.status == BookingStatus.enRevision) {
      // Proveedor debe completar los datos de la reserva
      actionButtons = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
              label: const Text('Completar Datos',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context);
                _showCompletarDatosDialog(booking);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _shareToWhatsApp(booking),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('WhatsApp',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    } else if (booking.status == BookingStatus.enProceso) {
      // Proveedor puede completar o cancelar
      actionButtons = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _shareToWhatsApp(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('WhatsApp',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final solicitudId = int.parse(booking.id);
                      final res = await _vm.cancelarReserva(solicitudId);
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              res.success ? 'Reserva cancelada' : res.message),
                          backgroundColor:
                              res.success ? errorRed : Colors.grey,
                        ),
                      );
                      if (res.success) _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final solicitudId = int.parse(booking.id);
                      final res = await _vm.completarReserva(solicitudId);
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.success
                              ? 'Servicio completado correctamente'
                              : res.message),
                          backgroundColor:
                              res.success ? successGreen : errorRed,
                        ),
                      );
                      if (res.success) _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Completar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (booking.status != BookingStatus.rechazada &&
        booking.status != BookingStatus.cancelada) {
      actionButtons = SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _shareToWhatsApp(booking),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('WhatsApp',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final solicitudId = int.tryParse(booking.id) ?? 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingDetailSheet(
        booking: booking,
        isProvider: true,
        actionButtons: actionButtons,
        resena: _resenaParaSolicitud(solicitudId),
      ),
    );
  }

  void _showCompletarDatosDialog(BookingModel booking) {
    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final timeController = TextEditingController(
        text: DateFormat('HH:mm').format(DateTime.now()));
    final addressController = TextEditingController(text: booking.address);
    final priceController = TextEditingController(
        text: booking.price > 0 ? booking.price.toString() : '');
    bool isValid = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Completar Datos de Reserva',
              style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          content: Form(
            key: formKey,
            onChanged: () => setModalState(
                () => isValid = formKey.currentState?.validate() ?? false),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'Fecha del servicio',
                        prefixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        dateController.text =
                            DateFormat('yyyy-MM-dd').format(date);
                        setModalState(() =>
                            isValid =
                                formKey.currentState?.validate() ?? false);
                      }
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: timeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'Hora del servicio',
                        prefixIcon: Icon(Icons.access_time)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        timeController.text =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        setModalState(() =>
                            isValid =
                                formKey.currentState?.validate() ?? false);
                      }
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                        labelText: 'Dirección del servicio',
                        prefixIcon: Icon(Icons.location_on)),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Precio acordado',
                        prefixIcon: Icon(Icons.attach_money)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final p = double.tryParse(v);
                      if (p == null || p <= 0) return 'Precio inválido';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: errorRed),
                      foregroundColor: errorRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isValid && !isLoading
                        ? () async {
                            setModalState(() => isLoading = true);
                            final solicitudId = int.parse(booking.id);
                            final dateParts =
                                dateController.text.split('-');
                            final timeParts =
                                timeController.text.split(':');
                            final combinedDate = DateTime(
                              int.parse(dateParts[0]),
                              int.parse(dateParts[1]),
                              int.parse(dateParts[2]),
                              int.parse(timeParts[0]),
                              int.parse(timeParts[1]),
                            );
                            final res = await _vm.completarDatosReserva(
                              solicitudId: solicitudId,
                              precioAcordado:
                                  double.parse(priceController.text),
                              direccionCliente:
                                  addressController.text.trim(),
                              fechaHoraReserva: combinedDate,
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.success
                                    ? 'Datos completados correctamente'
                                    : res.message),
                                backgroundColor:
                                    res.success ? successGreen : errorRed,
                              ),
                            );
                            if (res.success) _load();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor:
                          textGray.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Confirmar',
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                    itemBuilder: (context, index) =>
                        _buildBookingCard(_allFilteredBookings[index]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const ProviderBottomNav(currentIndex: 3),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: cardShadow, blurRadius: 10)
        ],
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
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(status: booking.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 16, color: textGray),
                    const SizedBox(width: 8),
                    Text(booking.clientName,
                        style: const TextStyle(color: textGray)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 16, color: textGray),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(booking.date),
                      style: const TextStyle(color: textGray),
                    ),
                  ],
                ),
                const Divider(height: 24),
                booking.price > 0
                    ? Text(
                        '\$${NumberFormat('#,###').format(booking.price)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue),
                      )
                    : const Text(
                        'Precio a definir',
                        style: TextStyle(
                            fontSize: 14,
                            color: textGray,
                            fontStyle: FontStyle.italic),
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
    if (_vm.isBusy) {
      return const Center(
          child: CircularProgressIndicator(color: primaryBlue));
    }
    final err = _vm.error;
    if (err != null && err.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 80, color: errorRed),
              const SizedBox(height: 16),
              Text(err,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textGray)),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _load,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                  child: const Text('Reintentar',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_rounded,
              size: 80, color: primaryBlue.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No hay reservas registradas',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGray)),
        ],
      ),
    );
  }
}
