import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/core/utils/catalog_visuals.dart';
import 'package:servizone_app/data/models/catalog/servicio_proveedor_model.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/presentation/views/client/services/service_detail_screen.dart';

class ServiceListScreen extends StatefulWidget {
  final String categoryName;
  final String subcategoryName;
  final int subcategoriaId; // id real del backend
  final bool isGuest;

  const ServiceListScreen({
    super.key,
    required this.categoryName,
    required this.subcategoryName,
    required this.subcategoriaId,
    this.isGuest = false,
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'price_asc'; // Sin rating — usar precio por defecto
  bool _requestedServicios = false;

  late final CatalogNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = locator<CatalogNotifier>();
    _notifier.addListener(_onCatalogChanged);
    // Paso 1: cargar tipos de servicio para esta subcategoría
    _notifier.loadTiposServicio(widget.subcategoriaId, forceRefresh: true);
    _onCatalogChanged();
  }

  @override
  void dispose() {
    _notifier.removeListener(_onCatalogChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onCatalogChanged() {
    if (!mounted) return;
    // Paso 2: cuando tipos carguen exitosamente, cargar servicios de TODOS los tipos.
    if (!_requestedServicios &&
        _notifier.tiposState == CatalogLoadState.success &&
        _notifier.tipos.isNotEmpty) {
      _requestedServicios = true;
      _notifier.loadServiciosPorTipos(_notifier.tipos.map((t) => t.id).toList());
    }
    setState(() {});
  }

  List<ServicioProveedor> get _filteredServices {
    var list = List<ServicioProveedor>.from(_notifier.servicios);

    // Búsqueda por nombre del servicio
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((s) =>
              s.nombreMostrado.toLowerCase().contains(q) ||
              (s.tipoServicioNombre?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // Ordenar por precio
    if (_selectedSort == 'price_asc') {
      list.sort((a, b) => a.precioBase.compareTo(b.precioBase));
    } else if (_selectedSort == 'price_desc') {
      list.sort((a, b) => b.precioBase.compareTo(a.precioBase));
    }

    return list;
  }

  void _retryServicios() {
    if (_notifier.tipos.isNotEmpty) {
      _notifier.loadServiciosPorTipos(_notifier.tipos.map((t) => t.id).toList());
    }
  }

  void _showGuestLoginModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: primaryBlue, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Inicia sesión para reservar!',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: const Text(
          'Para poder agendar este servicio y gestionar tus reservas, necesitas tener una cuenta en ServiZone.',
          style: TextStyle(fontFamily: 'Roboto', fontSize: 15, color: darkGray),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/auth/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Iniciar Sesión',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryBlue),
                    foregroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continuar explorando',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(ServicioProveedor service) {
    if (widget.isGuest) {
      _showGuestLoginModal();
      return;
    }
    // Convertir a Map para ServiceDetailScreen (sin modificar esa pantalla)
    final displayMap = <String, dynamic>{
      'id': service.id,
      'name': service.nombreMostrado,
      'professional': service.proveedorNombre ?? 'Proveedor #${service.proveedorId}',
      'description': service.tipoServicioDescripcion ?? service.descripcion,
      'price': service.precioBase,
      'rating': service.ratingMedia,
      'reviewCount': 0,
      'type': service.tipoServicioNombre ?? 'Servicio',
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(service: displayMap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiposState = _notifier.tiposState;
    final serviciosState = _notifier.serviciosState;

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.subcategoryName,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: primaryBlue,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Menú de orden — solo visible cuando tipos ya cargaron
          if (tiposState == CatalogLoadState.success && _notifier.tipos.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: darkGray),
              onSelected: (value) {
                if (value == 'sort_price_desc') {
                  setState(() => _selectedSort = 'price_desc');
                } else if (value == 'sort_price_asc') {
                  setState(() => _selectedSort = 'price_asc');
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];

                items.add(const PopupMenuItem(
                  enabled: false,
                  child: Text('Ordenar por precio:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textGray,
                          fontSize: 12)),
                ));
                items.add(PopupMenuItem<String>(
                  value: 'sort_price_asc',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded,
                          color: _selectedSort == 'price_asc'
                              ? primaryBlue
                              : textGray,
                          size: 20),
                      const SizedBox(width: 12),
                      const Text('Precio: menor a mayor'),
                    ],
                  ),
                ));
                items.add(PopupMenuItem<String>(
                  value: 'sort_price_desc',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded,
                          color: _selectedSort == 'price_desc'
                              ? primaryBlue
                              : textGray,
                          size: 20),
                      const SizedBox(width: 12),
                      const Text('Precio: mayor a menor'),
                    ],
                  ),
                ));
                return items;
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(color: cardShadow, blurRadius: 8)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar el servicio que necesitas',
                    hintStyle:
                        const TextStyle(fontFamily: 'Roboto', color: textGray),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: textGray),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon:
                                const Icon(Icons.clear_rounded, color: textGray),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // Lista de servicios
          Expanded(child: _buildBody(tiposState, serviciosState)),
        ],
      ),
    );
  }

  Widget _buildBody(CatalogLoadState tiposState, CatalogLoadState serviciosState) {
    // Estado de carga de tipos
    if (tiposState == CatalogLoadState.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryBlue),
            SizedBox(height: 16),
            Text('Cargando tipos de servicio...',
                style: TextStyle(color: textGray)),
          ],
        ),
      );
    }

    if (tiposState == CatalogLoadState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 60, color: textGray.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(_notifier.tiposError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textGray)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                onPressed: () =>
                    _notifier.retryTiposServicio(widget.subcategoriaId),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (tiposState == CatalogLoadState.success && _notifier.tipos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 60, color: textGray),
            SizedBox(height: 16),
            Text('No hay servicios en esta subcategoría',
                style: TextStyle(color: textGray, fontSize: 16)),
          ],
        ),
      );
    }

    // Estado de carga de servicios
    if (serviciosState == CatalogLoadState.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryBlue),
            SizedBox(height: 16),
            Text('Cargando servicios...', style: TextStyle(color: textGray)),
          ],
        ),
      );
    }

    if (serviciosState == CatalogLoadState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 60, color: errorRed.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              Text(_notifier.serviciosError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textGray)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                onPressed: _retryServicios,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredServices;

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: textGray),
            SizedBox(height: 16),
            Text('No se encontraron servicios',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: textGray)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildServiceCard(filtered[index]),
    );
  }

  Widget _buildServiceCard(ServicioProveedor service) {
    final iconColor = CatalogVisuals.servicioColor(service.tipoServicioNombre);
    final icon = CatalogVisuals.servicioIcon(service.tipoServicioNombre);
    final precioStr = service.precioBase
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono izquierdo
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(width: 16),
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.nombreMostrado, // getter null-safe
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (service.proveedorNombre ?? 'Proveedor #${service.proveedorId}')
                        .trim(),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if ((service.descripcion ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      service.descripcion!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        color: textGray,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$$precioStr',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showBookingDialog(service);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 36),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Reservar'),
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
}
