import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/core/routes/app_routes.dart';
import 'package:servizone_app/core/utils/catalog_visuals.dart';
import 'package:servizone_app/data/models/catalog/categoria_model.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/presentation/views/client/services/subcategory_screen.dart';
import 'package:servizone_app/presentation/views/client/profile/client_profile_screen.dart';
import 'package:servizone_app/presentation/views/client/client_requests_screen.dart';
import 'package:servizone_app/presentation/views/client/client_bookings_screen.dart';

class HomeClientScreen extends StatefulWidget {
  final int initialIndex;
  const HomeClientScreen({super.key, this.initialIndex = 2});

  @override
  State<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends State<HomeClientScreen>
    with TickerProviderStateMixin {
  late int _currentIndex;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late final CatalogNotifier _catalogNotifier;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _fadeController =
        AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _slideController =
        AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();

    // Obtener singleton y registrar listener
    _catalogNotifier = locator<CatalogNotifier>();
    _catalogNotifier.addListener(_onCatalogChanged);

    // Cargar categorías (el notifier evita llamadas duplicadas)
    _catalogNotifier.loadCategorias();
  }

  @override
  void dispose() {
    _catalogNotifier.removeListener(_onCatalogChanged);
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onCatalogChanged() {
    if (mounted) setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildReservasScreen(),
      _buildSolicitudesTab(),
      _buildServiciosScreen(),
      _buildAccountScreen(),
    ];

    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: (_currentIndex == 3)
          ? AppBar(
              title: const Text("Perfil",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: textGray,
              elevation: 0,
            )
          : null,
      body: screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: cardShadow, blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
          _fadeController.reset();
          _slideController.reset();
          _fadeController.forward();
          _slideController.forward();
        },
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textGray,
        selectedLabelStyle:
            const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: "Reservas"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: "Solicitudes"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Servicios"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Perfil"),
        ],
      ),
    );
  }

  Widget _buildSolicitudesTab() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: const ClientRequestsScreen()),
    );
  }

  // ── Pantalla Servicios ──────────────────────────────────────────

  Widget _buildServiciosScreen() {
    final state = _catalogNotifier.categoriasState;
    final categorias = _catalogNotifier.categorias;

    // Filtrar por búsqueda
    final filtered = categorias.where((cat) {
      final q = searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return cat.nombre.toLowerCase().contains(q) ||
          (cat.descripcion?.toLowerCase().contains(q) ?? false);
    }).toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.displayLarge,
                          children: const [
                            TextSpan(text: "Servi", style: TextStyle(color: primaryBlue)),
                            TextSpan(text: "Zone", style: TextStyle(color: darkGray)),
                          ],
                        ),
                      ),
                      Text('Tu plataforma de servicios',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontFamily: 'Roboto')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSearchBar(),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Categorías de Servicios',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Text('${filtered.length} categorías',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontFamily: 'Roboto')),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // — Grid con estados —
            Expanded(
              child: _buildCategoriaGrid(state, filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaGrid(CatalogLoadState state, List<Categoria> filtered) {
    if (state == CatalogLoadState.loading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (state == CatalogLoadState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: textGray.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(_catalogNotifier.categoriasError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textGray, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              onPressed: _catalogNotifier.retryCategorias,
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty && state == CatalogLoadState.success) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: textGray.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No se encontraron resultados',
                style: TextStyle(fontWeight: FontWeight.bold, color: darkGray)),
            const Text('Intenta con otra palabra clave',
                style: TextStyle(color: textGray)),
          ],
        ),
      );
    }

    // Idle o success con datos
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildCategoryCard(filtered[index]),
    );
  }

  Widget _buildCategoryCard(Categoria categoria) {
    final gradient = CatalogVisuals.categoryGradient(categoria.nombre);
    final icon = CatalogVisuals.categoryIcon(categoria.nombre);
    final color = CatalogVisuals.categoryColor(categoria.nombre);
    final subtitle = CatalogVisuals.categorySubtitle(
      categoria.nombre,
      fallback: categoria.descripcion ?? '',
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubcategoryScreen(
              categoryName: categoria.nombre,
              categoriaId: categoria.id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const Spacer(),
              Text(
                categoria.nombre,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontFamily: 'Roboto',
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: Center(
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => searchQuery = value),
          style: const TextStyle(fontSize: 16, color: darkGray, fontFamily: 'Roboto'),
          decoration: InputDecoration(
            hintText: 'Buscar categoría...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: textGray.withValues(alpha: 0.8), fontSize: 16, fontFamily: 'Roboto'),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.search_rounded, color: primaryBlue, size: 28),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 22, color: textGray),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => searchQuery = "");
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildReservasScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: const ClientBookingsScreen()),
    );
  }

  Widget _buildAccountScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ClientProfileScreen(onLogout: () async {
          await locator<AuthService>().logout();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
          }
        }),
      ),
    );
  }
}
