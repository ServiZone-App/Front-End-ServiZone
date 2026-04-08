import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/core/routes/app_routes.dart';
import 'package:servizone_app/core/utils/catalog_visuals.dart';
import 'package:servizone_app/data/models/catalog/categoria_model.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/presentation/views/client/services/subcategory_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 1;
  String searchQuery = "";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late final CatalogNotifier _catalogNotifier;

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
    // Compartir singleton con HomeClientScreen — sin segunda llamada HTTP
    _catalogNotifier = locator<CatalogNotifier>();
    _catalogNotifier.addListener(_onCatalogChanged);
    _catalogNotifier.loadCategorias(forceRefresh: true);
  }

  @override
  void dispose() {
    _catalogNotifier.removeListener(_onCatalogChanged);
    _fadeController.dispose();
    super.dispose();
  }

  void _onCatalogChanged() {
    if (mounted) setState(() {});
  }

  // Muestra un diálogo para iniciar sesión (usado en acciones que no son botones directos)
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Acceso restringido'),
        content: const Text('Para realizar esta acción debes iniciar sesión o registrarte.'),
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
            style: ElevatedButton.styleFrom(
            minimumSize: const Size(150, 48),
                ),
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mismas pantallas que el cliente, pero con acciones bloqueadas
    final List<Widget> screens = [
      _buildActivityScreen(),
      _buildSolicitudScreen(),
      _buildReservasScreen(),
      _buildAccountScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          // Permitir cambiar de pestaña sin restricción
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textGray,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: "Actividad",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Servicios",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: "Reservas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Cuenta",
          ),
        ],
      ),
    );
  }

  // Pantalla Actividad (solo visual)
  Widget _buildActivityScreen() {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: const Text(
          "Historial de Solicitudes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_rounded, size: 40, color: primaryBlue),
              ),
              const SizedBox(height: 24),
              const Text(
                'No hay actividad reciente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Inicia sesión para ver tu historial',
                style: TextStyle(color: textGray),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.login); // Navegación directa
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 48),
                ),
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitudScreen() {
    final state = _catalogNotifier.categoriasState;
    final categorias = _catalogNotifier.categorias;

    final filtered = categorias.where((cat) {
      final q = searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return cat.nombre.toLowerCase().contains(q) ||
          (cat.descripcion?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: lightGray,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                          children: [
                            TextSpan(text: "Servi", style: TextStyle(color: primaryBlue)),
                            TextSpan(text: "Zone", style: TextStyle(color: darkGray)),
                          ],
                        ),
                      ),
                      const Text('Explora como invitado', style: TextStyle(color: textGray)),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: const Stack(
                    children: [
                      Icon(Icons.notifications_none_rounded, color: darkGray),
                      Positioned(
                        right: 0, top: 0,
                        child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
                      ),
                    ],
                  ),
                  onPressed: _showLoginRequiredDialog,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: _showLoginRequiredDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "¿Qué servicio necesitas?",
                      prefixIcon: const Icon(Icons.search_rounded, color: textGray),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryBlue, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text('Categorías de Servicios',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGray)),
                      const Spacer(),
                      Text('${filtered.length} categorías',
                          style: const TextStyle(color: textGray)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // — Estados: loading / error / grid —
          if (state == CatalogLoadState.loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: primaryBlue)),
            )
          else if (state == CatalogLoadState.error)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 64, color: textGray),
                    const SizedBox(height: 12),
                    Text(_catalogNotifier.categoriasError,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textGray)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                      onPressed: _catalogNotifier.retryCategorias,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCategoryCard(filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
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
              isGuest: true,
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
            ),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pantalla Reservas (solo visual)
  Widget _buildReservasScreen() {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: const Text(
  "Mis Reservas",
  style: TextStyle(color: Colors.white), // el color que quieras
),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded, size: 80, color: primaryBlue.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            const Text(
              "No tienes reservas activas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkGray),
            ),
            const SizedBox(height: 10),
            const Text(
              "Inicia sesión para gestionar tus reservas",
              style: TextStyle(color: textGray),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.login); // Navegación directa
              },
                              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 48),
                ),
              child: const Text("Iniciar Sesión"),
            ),
          ],
        ),
      ),
    );
  }

  // Pantalla Cuenta (solo visual)
  Widget _buildAccountScreen() {
    return Scaffold(
      backgroundColor: lightGray,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: primaryBlue),
            const SizedBox(height: 20),
            const Text('Perfil de Usuario', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Inicia sesión para ver tu perfil', style: TextStyle(color: textGray)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.login); // Navegación directa
              },
                              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 48),
                ),
              child: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}


