import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/core/routes/app_routes.dart';
import 'package:servizone_app/core/utils/catalog_visuals.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/presentation/views/client/home_client_screen.dart';
import 'package:servizone_app/presentation/views/client/services/service_list_screen.dart';

class SubcategoryScreen extends StatefulWidget {
  final String categoryName;
  final int categoriaId; // id real del backend — necesario para la API
  final bool isGuest;

  const SubcategoryScreen({
    super.key,
    required this.categoryName,
    required this.categoriaId,
    this.isGuest = false,
  });

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final CatalogNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = locator<CatalogNotifier>();
    _notifier.addListener(_onCatalogChanged);
    // El notifier tiene cache por id — llama a API solo si cambió la categoría
    _notifier.loadSubcategorias(widget.categoriaId);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onCatalogChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onCatalogChanged() {
    if (mounted) setState(() {});
  }

  void _navigateToHomeWithIndex(int index) {
    if (widget.isGuest) {
      if (index == 2) {
        Navigator.pop(context);
      } else {
        _showLoginRequiredDialog();
      }
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeClientScreen(initialIndex: index)),
      (route) => false,
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Acceso restringido'),
        content:
            const Text('Para acceder a esta sección debes iniciar sesión o registrarte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.login);
            },
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _notifier.subcategoriasState;
    final allSubs = _notifier.subcategorias;
    final filtered = _searchQuery.isEmpty
        ? allSubs
        : allSubs
            .where((s) =>
                s.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 8)],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Buscar subcategoría...',
                  hintStyle: const TextStyle(color: textGray),
                  prefixIcon: const Icon(Icons.search_rounded, color: textGray),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: textGray),
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

          // Contenido con estados
          Expanded(child: _buildContent(state, filtered)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildContent(CatalogLoadState state, List subcategorias) {
    if (state == CatalogLoadState.loading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (state == CatalogLoadState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 60, color: textGray.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                _notifier.subcategoriasError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textGray, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                onPressed: () =>
                    _notifier.retrySubcategorias(widget.categoriaId),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (subcategorias.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: textGray),
            SizedBox(height: 16),
            Text('No se encontraron subcategorías',
                style: TextStyle(color: textGray, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: subcategorias.length,
      itemBuilder: (context, index) {
        final sub = subcategorias[index];
        final icon = CatalogVisuals.subcategoryIcon(sub.nombre);
        final color = CatalogVisuals.subcategoryColor(sub.nombre);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 8)],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceListScreen(
                      categoryName: widget.categoryName,
                      subcategoryName: sub.nombre,
                      subcategoriaId: sub.id, // id real del backend
                      isGuest: widget.isGuest,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        sub.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: textGray, size: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: cardShadow, blurRadius: 20, offset: Offset(0, -4))
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          HapticFeedback.lightImpact();
          if (index == 2) return;
          _navigateToHomeWithIndex(index);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textGray,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded), label: "Reservas"),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded), label: "Solicitudes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: "Servicios"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: "Perfil"),
        ],
      ),
    );
  }
}
