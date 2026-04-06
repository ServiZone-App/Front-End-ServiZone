import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/models/booking/resena_dto.dart';
import 'package:servizone_app/data/models/booking/reserva_dto.dart';
import 'package:servizone_app/data/models/booking_model.dart';
import 'package:servizone_app/data/providers/booking_api_service.dart';
import 'package:servizone_app/presentation/viewmodels/solicitudes_reservas_view_model.dart';
import 'package:servizone_app/presentation/widgets/shared/booking_detail_sheet.dart';
import 'package:servizone_app/presentation/widgets/shared/status_badge.dart';

class BookingHistoryScreen extends StatefulWidget {
  final bool isProvider;

  const BookingHistoryScreen({super.key, this.isProvider = false});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  BookingStatus? _statusFilter;
  String _priceSort = 'none'; // 'asc', 'desc', 'none'
  String _dateSort = 'desc'; // 'asc', 'desc'
  final List<String> _selectedServiceTypes = [];

  late final SolicitudesReservasViewModel _solicitudesVm;

  // ── Helpers ───────────────────────────────────────────────────────────────

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
      serviceType: dto.categoria ?? dto.nombreServicio ?? 'Servicio',
      serviceName: dto.nombreServicio ?? 'Servicio ${dto.servicioProveedorId}',
      date: dto.fechaHoraReserva ?? dto.fechaCreacion,
      address: dto.direccionCliente ?? '',
      price: dto.precioAcordado ?? 0.0,
      status: _mapEstado(dto.estado),
    );
  }

  List<String> get _availableServiceTypes {
    return _allBookings.map((e) => e.serviceType).toSet().toList();
  }

  List<BookingModel> get _allBookings {
    final raw = widget.isProvider
        ? _solicitudesVm.reservasProveedor.map(_toBookingModel).toList()
        : _solicitudesVm.misBookings.map(_toBookingModel).toList();
    // Historial nunca muestra reservas activas (en_proceso)
    return raw.where((b) => b.status != BookingStatus.enProceso).toList();
  }

  // Estados válidos para el filtro en la vista de proveedor (solo finales)
  static const _providerFilterableStatuses = [
    BookingStatus.completada,
    BookingStatus.cancelada,
    BookingStatus.rechazada,
  ];

  // Estados válidos para el filtro en la vista de cliente (solo finales)
  static const _clientFilterableStatuses = [
    BookingStatus.completada,
    BookingStatus.cancelada,
    BookingStatus.rechazada,
  ];

  bool get _isBusy => _solicitudesVm.isBusy;

  String? get _error => _solicitudesVm.error;

  @override
  void initState() {
    super.initState();
    _solicitudesVm = locator<SolicitudesReservasViewModel>();
    _solicitudesVm.addListener(_onChanged);
    _load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (widget.isProvider) {
      await _solicitudesVm.cargarReservasProveedor();
    } else {
      await _solicitudesVm.cargarMisBookings();
    }
  }

  List<BookingModel> get _filteredBookings {
    var filtered = _allBookings.where((booking) {
      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch = booking.serviceName.toLowerCase().contains(searchLower) ||
          booking.clientName.toLowerCase().contains(searchLower) ||
          (booking.providerName?.toLowerCase().contains(searchLower) ?? false);

      final matchesStatus = _statusFilter == null || booking.status == _statusFilter;

      final matchesService = _selectedServiceTypes.isEmpty ||
                             _selectedServiceTypes.contains(booking.serviceType);

      return matchesSearch && matchesStatus && matchesService;
    }).toList();

    if (_priceSort == 'asc') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_priceSort == 'desc') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    } else if (_dateSort == 'asc') {
      filtered.sort((a, b) => a.date.compareTo(b.date));
    } else {
      filtered.sort((a, b) => b.date.compareTo(a.date));
    }

    return filtered;
  }

  @override
  void dispose() {
    _solicitudesVm.removeListener(_onChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: Text(
          widget.isProvider ? 'Servicios Realizados' : 'Historial de Reservas',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: textGray,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'price_desc') {
                setState(() { _priceSort = 'desc'; _dateSort = 'none'; });
              } else if (value == 'price_asc') {
                setState(() { _priceSort = 'asc'; _dateSort = 'none'; });
              } else if (value == 'date_desc') {
                setState(() { _dateSort = 'desc'; _priceSort = 'none'; });
              } else if (value == 'date_asc') {
                setState(() { _dateSort = 'asc'; _priceSort = 'none'; });
              } else if (value.startsWith('type_')) {
                final type = value.substring(5);
                setState(() {
                  if (_selectedServiceTypes.contains(type)) {
                    _selectedServiceTypes.remove(type);
                  } else {
                    _selectedServiceTypes.add(type);
                  }
                });
              } else if (value.startsWith('status_')) {
                final st = value.substring(7);
                if (st == 'all') {
                  setState(() => _statusFilter = null);
                } else {
                  final status = BookingStatus.values.firstWhere((e) => e.name == st);
                  setState(() => _statusFilter = status);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('Filtrar por tipo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              ..._availableServiceTypes.map((type) => PopupMenuItem(
                value: 'type_$type',
                child: Row(
                  children: [
                    Icon(
                      _selectedServiceTypes.contains(type) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
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
                child: Text('Filtrar por estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              PopupMenuItem(
                value: 'status_all',
                child: Row(
                  children: [
                    Icon(
                      _statusFilter == null ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Todos'),
                  ],
                ),
              ),
              ...(widget.isProvider
                  ? _providerFilterableStatuses
                  : _clientFilterableStatuses
              ).map((status) => PopupMenuItem(
                value: 'status_${status.name}',
                child: Row(
                  children: [
                    Icon(
                      _statusFilter == status ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(status.name.toUpperCase()),
                  ],
                ),
              )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Ordenar por', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              PopupMenuItem(
                value: 'date_desc',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: _dateSort == 'desc' ? primaryBlue : textGray, size: 20),
                    const SizedBox(width: 12),
                    const Text('Fecha: más reciente'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date_asc',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: _dateSort == 'asc' ? primaryBlue : textGray, size: 20),
                    const SizedBox(width: 12),
                    const Text('Fecha: más antigua'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price_asc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: _priceSort == 'asc' ? primaryBlue : textGray, size: 20),
                    const SizedBox(width: 12),
                    const Text('Precio: menor a mayor'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded, color: _priceSort == 'desc' ? primaryBlue : textGray, size: 20),
                    const SizedBox(width: 12),
                    const Text('Precio: mayor a menor'),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isBusy
                ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                : _filteredBookings.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredBookings.length,
                        itemBuilder: (context, index) => _buildBookingCard(_filteredBookings[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    Color statusColor = switch (booking.status) {
      BookingStatus.pendiente => warningOrange,
      BookingStatus.enRevision => const Color(0xFF0288D1),
      BookingStatus.enProceso => const Color(0xFF00796B),
      BookingStatus.confirmada => successGreen,
      BookingStatus.completada => successGreen,
      BookingStatus.cancelada => errorRed,
      BookingStatus.rechazada => errorRed,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)
            )
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
                    child: Icon(Icons.build_rounded, color: statusColor),
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
                                  color: textGray,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(status: booking.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isProvider
                            ? 'Cliente: ${booking.clientName.isNotEmpty ? booking.clientName : 'Desconocido'}'
                            : 'Proveedor: ${booking.providerName != null && booking.providerName!.isNotEmpty ? booking.providerName : 'No asignado'}',
                          style: const TextStyle(color: textGray, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: textGray),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy - hh:mm a').format(booking.date),
                              style: const TextStyle(color: textGray, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      builder: (context) => BookingDetailSheet(
        booking: booking,
        isProvider: widget.isProvider,
        resena: resena,
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
          hintText: 'Buscar por servicio, ${widget.isProvider ? 'cliente' : 'proveedor'}...',
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
    final err = _error;
    if (err != null && err.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 80, color: errorRed),
              const SizedBox(height: 16),
              Text(err, textAlign: TextAlign.center, style: const TextStyle(color: textGray)),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                  child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80, color: primaryBlue.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text('No se encontraron reservas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGray)),
            const Text('Ajusta los filtros para ver más resultados', style: TextStyle(color: textGray)),
          ],
        ),
      ),
    );
  }
}
