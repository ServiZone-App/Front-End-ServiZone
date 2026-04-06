import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/models/booking/reserva_dto.dart';
import 'package:servizone_app/data/models/booking_model.dart';
import 'package:servizone_app/presentation/viewmodels/solicitudes_reservas_view_model.dart';
import 'package:servizone_app/data/models/booking/resena_dto.dart';
import 'package:servizone_app/data/providers/booking_api_service.dart';
import 'package:servizone_app/presentation/widgets/shared/booking_detail_sheet.dart';
import 'package:servizone_app/presentation/widgets/shared/status_badge.dart';

class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen> {
  String _priceSort = 'none';
  String _dateSort = 'desc';
  final List<String> _selectedServiceTypes = [];
  final Set<String> _ratedIds = {};
  late final SolicitudesReservasViewModel _vm;

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
      servicioProveedorId: dto.servicioProveedorId,
      clientId: dto.clienteId.toString(),
      providerId: dto.proveedorId.toString(),
      clientName: dto.clienteNombre,
      providerName: dto.proveedorNombre,
      serviceType: dto.nombreServicio ?? 'Servicio',
      serviceName: dto.nombreServicio ?? 'Servicio ${dto.servicioProveedorId}',
      date: dto.fechaHoraReserva ?? dto.fechaCreacion,
      address: dto.direccionCliente ?? '',
      price: dto.precioAcordado ?? 0.0,
      status: _mapEstado(dto.estado),
    );
  }

  List<String> get _availableServiceTypes =>
      _vm.misBookings.map((dto) => dto.nombreServicio ?? 'Servicio').toSet().toList();

  @override
  void initState() {
    super.initState();
    _vm = locator<SolicitudesReservasViewModel>();
    _vm.addListener(_onChanged);
    _load();
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await _vm.cargarMisBookings();
    await _checkExistingRatings();
  }

  Future<void> _checkExistingRatings() async {
    final completadas = _vm.misBookings.where((dto) => dto.estado == 'completado');
    final apiService = locator<BookingApiService>();
    final checkedServiceIds = <int>{};
    for (final dto in completadas) {
      final svcId = dto.servicioProveedorId;
      if (svcId <= 0 || checkedServiceIds.contains(svcId)) continue;
      checkedServiceIds.add(svcId);
      final res = await apiService.getResenasServicio(svcId);
      if (res.success && res.data != null) {
        for (final r in res.data!) {
          if (mounted) setState(() => _ratedIds.add(r.solicitudId.toString()));
        }
      }
    }
  }

  List<BookingModel> get _bookingsNoPendientes =>
      _vm.misBookings
          .map(_toBookingModel)
          .where((b) => b.status == BookingStatus.enProceso || b.status == BookingStatus.completada)
          .toList();

  List<BookingModel> get _filteredBookings {
    var list = _bookingsNoPendientes.where((booking) {
      return _selectedServiceTypes.isEmpty ||
          _selectedServiceTypes.contains(booking.serviceType);
    }).toList();

    if (_priceSort == 'asc') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_priceSort == 'desc') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_dateSort == 'asc') {
      list.sort((a, b) => a.date.compareTo(b.date));
    } else {
      list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  void _showNotification(String message, {bool isError = false}) {
    if (isError) {
      HapticFeedback.vibrate();
    } else {
      HapticFeedback.lightImpact();
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? errorRed : successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showRatingDialog(BookingModel booking) {
    double selectedRating = 5;
    final reviewController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Calificar Servicio',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () =>
                        setDialogState(() => selectedRating = index + 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Comparte tu experiencia...',
                  hintStyle: const TextStyle(fontSize: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: lightGray,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      setDialogState(() => isSubmitting = true);
                      final solicitudId = int.tryParse(booking.id) ?? 0;
                      final comentario = reviewController.text.trim();
                      final res = await _vm.dejarResena(
                        solicitudId: solicitudId,
                        calificacion: selectedRating.toInt(),
                        comentario: comentario.isEmpty ? null : comentario,
                      );
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      _showNotification(
                        res.success ? '¡Gracias por tu calificación!' : res.message,
                        isError: !res.success,
                      );
                      if (res.success) {
                        setState(() => _ratedIds.add(booking.id));
                        await _load();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Enviar', style: TextStyle(color: Colors.white)),
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
        title: const Text('Mis Reservas',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: textGray,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              setState(() {
                if (value == 'price_asc') {
                  _priceSort = 'asc';
                  _dateSort = 'none';
                } else if (value == 'price_desc') {
                  _priceSort = 'desc';
                  _dateSort = 'none';
                } else if (value == 'date_asc') {
                  _dateSort = 'asc';
                  _priceSort = 'none';
                } else if (value == 'date_desc') {
                  _dateSort = 'desc';
                  _priceSort = 'none';
                } else if (value.startsWith('type_')) {
                  final type = value.substring(5);
                  if (_selectedServiceTypes.contains(type)) {
                    _selectedServiceTypes.remove(type);
                  } else {
                    _selectedServiceTypes.add(type);
                  }
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('Filtrar por tipo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              ..._availableServiceTypes.map((type) => PopupMenuItem(
                    value: 'type_$type',
                    child: Row(
                      children: [
                        Icon(
                          _selectedServiceTypes.contains(type)
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(type),
                      ],
                    ),
                  )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Ordenar por',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              PopupMenuItem(
                value: 'date_desc',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: _dateSort == 'desc' ? primaryBlue : textGray,
                        size: 20),
                    const SizedBox(width: 12),
                    const Text('Fecha: más reciente'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date_asc',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: _dateSort == 'asc' ? primaryBlue : textGray,
                        size: 20),
                    const SizedBox(width: 12),
                    const Text('Fecha: más antigua'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price_asc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        color: _priceSort == 'asc' ? primaryBlue : textGray,
                        size: 20),
                    const SizedBox(width: 12),
                    const Text('Precio: menor a mayor'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded,
                        color: _priceSort == 'desc' ? primaryBlue : textGray,
                        size: 20),
                    const SizedBox(width: 12),
                    const Text('Precio: mayor a menor'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _filteredBookings.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _filteredBookings.length,
              itemBuilder: (context, index) =>
                  _buildBookingCard(_filteredBookings[index]),
            ),
    );
  }

  Future<void> _showBookingDetails(BookingModel booking) async {
    ResenaDto? resena;
    if (booking.status == BookingStatus.completada && booking.servicioProveedorId > 0) {
      final apiService = locator<BookingApiService>();
      final res = await apiService.getResenasServicio(booking.servicioProveedorId);
      if (res.success && res.data != null) {
        final solicitudId = int.tryParse(booking.id) ?? 0;
        resena = res.data!.where((r) => r.solicitudId == solicitudId).firstOrNull;
      }
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingDetailSheet(booking: booking, resena: resena),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final Color statusColor = switch (booking.status) {
      BookingStatus.pendiente   => warningOrange,
      BookingStatus.enRevision  => const Color(0xFF0288D1),
      BookingStatus.enProceso   => const Color(0xFF00796B),
      BookingStatus.confirmada  => successGreen,
      BookingStatus.completada  => successGreen,
      BookingStatus.cancelada   => errorRed,
      BookingStatus.rechazada   => errorRed,
    };

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showBookingDetails(booking);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      switch (booking.status) {
                        BookingStatus.completada => Icons.check_circle_rounded,
                        BookingStatus.cancelada  => Icons.cancel_rounded,
                        BookingStatus.rechazada  => Icons.cancel_rounded,
                        _                        => Icons.calendar_today_rounded,
                      },
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: darkGray),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(status: booking.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Proveedor: ${booking.providerName ?? 'No asignado'}',
                          style: const TextStyle(color: textGray, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: textGray),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy - hh:mm a')
                                  .format(booking.date),
                              style: const TextStyle(
                                  color: textGray, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.price > 0
                        ? 'Total: \$${NumberFormat('#,###').format(booking.price)}'
                        : 'Precio a confirmar',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: booking.price > 0 ? primaryBlue : textGray,
                      fontSize: booking.price > 0 ? 16 : 13,
                    ),
                  ),
                  Row(
                    children: [
                      if (booking.status == BookingStatus.completada &&
                          !_ratedIds.contains(booking.id))
                        ElevatedButton(
                          onPressed: () => _showRatingDialog(booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            minimumSize: const Size(80, 32),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Calificar',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600)),
                        ),
                      TextButton(
                        onPressed: () => _showBookingDetails(booking),
                        child: const Text('Detalles',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
              size: 80, color: primaryBlue.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('No hay reservas registradas',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGray)),
          const Text('Tus próximas reservas aparecerán aquí',
              style: TextStyle(color: textGray)),
        ],
      ),
    );
  }
}
