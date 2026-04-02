import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/data/models/booking_model.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/presentation/widgets/shared/provider_bottom_nav.dart';
import 'package:servizone_app/presentation/widgets/shared/status_badge.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:servizone_app/domain/repositories/auth_repository.dart';
import 'package:servizone_app/presentation/viewmodels/booking_view_model.dart';

class ProviderRequestsView extends StatefulWidget {
  const ProviderRequestsView({super.key});

  @override
  State<ProviderRequestsView> createState() => _ProviderRequestsViewState();
}

class _ProviderRequestsViewState extends State<ProviderRequestsView> {
  late final BookingViewModel _vm;
  int? _proveedorId;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  DateTime? _selectedDate;
  String? _selectedService;
  
  // Pagination
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

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
      await _vm.loadProviderPending(
        res.data!,
        query: _searchQuery,
        date: _selectedDate,
        serviceName: _selectedService,
      );
    } else {
      setState(() => _proveedorId = null);
      _vm.setError(res.message.isNotEmpty ? res.message : 'No se pudo verificar tu ID de proveedor. Contacta a soporte.');
    }
  }

  void _shareToWhatsApp(BookingModel booking) async {
    final text = 'Hola ${booking.clientName}, te escribo de ServiZone por tu solicitud de ${booking.serviceName}. Me gustaría confirmar los detalles del servicio.';
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
      }
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (v) async {
          setState(() {
            _searchQuery = v;
            _currentPage = 1;
          });
          final id = _proveedorId;
          if (id != null) {
            await _vm.loadProviderPending(
              id,
              query: _searchQuery,
              date: _selectedDate,
              serviceName: _selectedService,
            );
          }
        },
        style: const TextStyle(color: textGray),
        decoration: InputDecoration(
          hintText: 'Buscar por cliente...',
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

  List<BookingModel> get _allFilteredRequests {
    return _vm.bookings;
  }

  List<BookingModel> get _paginatedRequests {
    final filtered = _allFilteredRequests;
    final endIndex = _currentPage * _itemsPerPage;
    if (endIndex >= filtered.length) {
      return filtered;
    }
    return filtered.sublist(0, endIndex);
  }

  bool get _hasMoreRequests => _paginatedRequests.length < _allFilteredRequests.length;

  void _loadMore() {
    setState(() {
      _currentPage++;
    });
  }

  void _handleRequest(BookingModel request, bool accept) {
    if (accept) {
      _showConfirmDialog(request);
    } else {
      _showRejectDialog(request);
    }
  }

  void _showConfirmDialog(BookingModel request) {
    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(request.date));
    final timeController = TextEditingController(text: DateFormat('HH:mm').format(request.date));
    final addressController = TextEditingController(text: request.address);
    bool isValid = addressController.text.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirmar Reserva', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          content: Form(
            key: formKey,
            onChanged: () => setModalState(() => isValid = formKey.currentState?.validate() ?? false),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cliente', style: TextStyle(color: textGray, fontSize: 12)),
                  Text(request.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Servicio', style: TextStyle(color: textGray, fontSize: 12)),
                  Text(request.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Fecha del servicio', prefixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: request.date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        dateController.text = DateFormat('yyyy-MM-dd').format(date);
                        setModalState(() => isValid = formKey.currentState?.validate() ?? false);
                      }
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: timeController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Hora del servicio', prefixIcon: Icon(Icons.access_time)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(request.date),
                      );
                      if (time != null) {
                        timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        setModalState(() => isValid = formKey.currentState?.validate() ?? false);
                      }
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Dirección del servicio', prefixIcon: Icon(Icons.location_on)),
                    onChanged: (v) => setModalState(() => isValid = formKey.currentState?.validate() ?? false),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _shareToWhatsApp(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValid ? () {
                  try {
                    final proveedorId = _proveedorId;
                    if (proveedorId == null) {
                      throw Exception('No se pudo obtener el ID del proveedor.');
                    }
                    // Combinar fecha y hora
                    final dateParts = dateController.text.split('-');
                    final timeParts = timeController.text.split(':');
                    final combinedDate = DateTime(
                      int.parse(dateParts[0]),
                      int.parse(dateParts[1]),
                      int.parse(dateParts[2]),
                      int.parse(timeParts[0]),
                      int.parse(timeParts[1]),
                    );

                    _vm.confirm(
                      request.id,
                      proveedorId,
                      combinedDate,
                      addressController.text,
                    );
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reserva confirmada correctamente'), backgroundColor: successGreen),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: errorRed),
                    );
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  disabledBackgroundColor: textGray.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirmar Reserva', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BookingModel request) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Motivo del rechazo'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                try {
                  final proveedorId = _proveedorId;
                  if (proveedorId == null) {
                    throw Exception('No se pudo obtener el ID del proveedor.');
                  }
                  _vm.reject(request.id, proveedorId, reasonController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Solicitud rechazada correctamente'), backgroundColor: errorRed),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: errorRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: const Text('Solicitudes Pendientes'),
        backgroundColor: Colors.white,
        foregroundColor: textGray,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16), // Espacio entre buscador y lista
          if (_selectedDate != null || _selectedService != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               child: Wrap(
                 spacing: 8.0,
                 children: [
                   if (_selectedDate != null)
                     Chip(
                       label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                       onDeleted: () => setState(() { _selectedDate = null; _currentPage = 1; }),
                     ),
                   if (_selectedService != null)
                     Chip(
                       label: Text(_selectedService!),
                       onDeleted: () => setState(() { _selectedService = null; _currentPage = 1; }),
                     ),
                 ],
               ),
             ),
          Expanded(
            child: _paginatedRequests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _paginatedRequests.length + (_hasMoreRequests ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _paginatedRequests.length) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _loadMore,
                              child: const Text('Cargar más'),
                            ),
                          ),
                        );
                      }
                      return _buildRequestCard(_paginatedRequests[index]);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const ProviderBottomNav(currentIndex: 2),
    );
  }

  Widget _buildRequestCard(BookingModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: warningOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_rounded, color: warningOrange),
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
                              request.serviceName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkGray),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const StatusBadge(status: BookingStatus.pendiente),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente: ${request.clientName}',
                        style: const TextStyle(color: textGray, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: textGray),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy - hh:mm a').format(request.date),
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
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _handleRequest(request, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: errorRed,
                    side: const BorderSide(color: errorRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Rechazar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _handleRequest(request, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_vm.isBusy) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }
    final err = _vm.error;
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind_rounded, size: 80, color: primaryBlue.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('No hay solicitudes pendientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGray)),
          const Text('Las nuevas solicitudes aparecerán aquí', style: TextStyle(color: textGray)),
        ],
      ),
    );
  }



  void _showFilters() {
    final services = _vm.bookings.map((b) => b.serviceName).toSet().toList()..sort();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Filtros', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_selectedDate == null ? 'Filtrar por fecha' : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setModalState(() => _selectedDate = date);
                    setState(() { 
                      _selectedDate = date; 
                      _currentPage = 1;
                    });
                    final id = _proveedorId;
                    if (id != null) {
                      _vm.loadProviderPending(
                        id,
                        query: _searchQuery,
                        date: _selectedDate,
                        serviceName: _selectedService,
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.build),
                title: Text(_selectedService == null ? 'Filtrar por servicio' : _selectedService!),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Seleccionar Servicio'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: services.map((s) => ListTile(
                            title: Text(s),
                            onTap: () {
                              setModalState(() => _selectedService = s);
                              setState(() {
                                _selectedService = s;
                                _currentPage = 1;
                              });
                              final id = _proveedorId;
                              if (id != null) {
                                _vm.loadProviderPending(
                                  id,
                                  query: _searchQuery,
                                  date: _selectedDate,
                                  serviceName: _selectedService,
                                );
                              }
                              Navigator.pop(context);
                            },
                          )).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_selectedDate != null || _selectedService != null)
                TextButton(
                  onPressed: () {
                    setModalState(() {
                      _selectedDate = null;
                      _selectedService = null;
                    });
                    setState(() {
                      _selectedDate = null;
                      _selectedService = null;
                      _currentPage = 1;
                    });
                    final id = _proveedorId;
                    if (id != null) {
                      _vm.loadProviderPending(
                        id,
                        query: _searchQuery,
                        date: _selectedDate,
                        serviceName: _selectedService,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar Filtros'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  
}
