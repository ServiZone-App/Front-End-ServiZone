import 'package:flutter/material.dart';

/// Helper visual para el catálogo.
/// Mapea nombres de categoría/subcategoría (en minúsculas) a íconos y colores.
/// Permite mantener la UI intacta aunque los nombres del backend difieran.
abstract class CatalogVisuals {
  // ── Categorías ──────────────────────────────────────────────────

  static const _categoriaMap = <String, _VisualData>{
    'hogar': _VisualData(
      icon: Icons.home_rounded,
      color: Color(0xFF2E7D32),
      gradient: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
      subtitle: 'Limpieza y mantenimiento',
    ),
    'servi favor': _VisualData(
      icon: Icons.handshake_rounded,
      color: Color(0xFF1A237E),
      gradient: [Color(0xFF1A237E), Color(0xFF3F51B5)],
      subtitle: 'Favores personales',
    ),
    'servifavor': _VisualData(
      icon: Icons.handshake_rounded,
      color: Color(0xFF1A237E),
      gradient: [Color(0xFF1A237E), Color(0xFF3F51B5)],
      subtitle: 'Favores personales',
    ),
    'ciclismo': _VisualData(
      icon: Icons.directions_bike_rounded,
      color: Color(0xFFE65100),
      gradient: [Color(0xFFE65100), Color(0xFFFF9800)],
      subtitle: 'Reparación y servicios',
    ),
    'cuidado personal': _VisualData(
      icon: Icons.spa_rounded,
      color: Color(0xFF7B1FA2),
      gradient: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
      subtitle: 'Belleza y bienestar',
    ),
    'cuidadopersonal': _VisualData(
      icon: Icons.spa_rounded,
      color: Color(0xFF7B1FA2),
      gradient: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
      subtitle: 'Belleza y bienestar',
    ),
    'cuidado': _VisualData(
      icon: Icons.favorite_rounded,
      color: Color(0xFFC2185B),
      gradient: [Color(0xFFC2185B), Color(0xFFE91E63)],
      subtitle: 'Cuidado de personas',
    ),
    'mascotas': _VisualData(
      icon: Icons.pets_rounded,
      color: Color(0xFFD32F2F),
      gradient: [Color(0xFFD32F2F), Color(0xFFF44336)],
      subtitle: 'Cuidado animal',
    ),
  };

  static const _default = _VisualData(
    icon: Icons.category_rounded,
    color: Color(0xFF1976D2),
    gradient: [Color(0xFF1565C0), Color(0xFF1976D2)],
    subtitle: 'Servicios',
  );

  static int _stableHash(String input) {
    var hash = 0;
    for (final c in input.codeUnits) {
      hash = 0x1fffffff & (hash + c);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  static List<Color> _generatedCategoryGradient(String key) {
    final h = _stableHash(key);
    final hue1 = (h % 360).toDouble();
    final hue2 = ((hue1 + 28) % 360);
    final c1 = HSVColor.fromAHSV(1, hue1, 0.55, 0.92).toColor();
    final c2 = HSVColor.fromAHSV(1, hue2, 0.55, 0.78).toColor();
    return [c1, c2];
  }

  // ── Subcategorías ───────────────────────────────────────────────

  static const _subcategoriaMap = <String, _SubVisualData>{
    'plomería': _SubVisualData(icon: Icons.plumbing, color: Color(0xFF4FA3D1)),
    'plomeria': _SubVisualData(icon: Icons.plumbing, color: Color(0xFF4FA3D1)),
    'electricidad': _SubVisualData(icon: Icons.electrical_services, color: Color(0xFFF5A623)),
    'carpintería': _SubVisualData(icon: Icons.handyman, color: Color(0xFF8B5A2B)),
    'carpinteria': _SubVisualData(icon: Icons.handyman, color: Color(0xFF8B5A2B)),
    'pintura': _SubVisualData(icon: Icons.format_paint, color: Color(0xFFE91E63)),
    'jardinería': _SubVisualData(icon: Icons.yard, color: Color(0xFF2E7D32)),
    'jardineria': _SubVisualData(icon: Icons.yard, color: Color(0xFF2E7D32)),
    'clases particulares': _SubVisualData(icon: Icons.school, color: Colors.purple),
    'cuidado de mascotas': _SubVisualData(icon: Icons.pets, color: Colors.orange),
    'mudanzas': _SubVisualData(icon: Icons.local_shipping, color: Colors.brown),
    'peluquería': _SubVisualData(icon: Icons.content_cut, color: Colors.deepOrange),
    'peluqueria': _SubVisualData(icon: Icons.content_cut, color: Colors.deepOrange),
    'manicura y pedicura': _SubVisualData(icon: Icons.face, color: Colors.pinkAccent),
    'masajes': _SubVisualData(icon: Icons.spa, color: Color(0xFF0D47A1)),
    'paseo de perros': _SubVisualData(icon: Icons.pets, color: Colors.brown),
    'veterinario a domicilio': _SubVisualData(icon: Icons.local_hospital, color: Colors.red),
    'guardería para mascotas': _SubVisualData(icon: Icons.house, color: Colors.amber),
    'reparación de bicicletas': _SubVisualData(icon: Icons.build, color: Color(0xFFE65100)),
    'cuidado de niños': _SubVisualData(icon: Icons.child_care, color: Colors.pink),
    'cuidado de adultos mayores': _SubVisualData(icon: Icons.elderly, color: Colors.deepPurple),
  };

  static const _defaultSub = _SubVisualData(
    icon: Icons.miscellaneous_services_rounded,
    color: Color(0xFF1976D2),
  );

  // ── API pública ─────────────────────────────────────────────────

  static IconData categoryIcon(String nombre) =>
      (_categoriaMap[nombre.toLowerCase().trim()] ?? _default).icon;

  static List<Color> categoryGradient(String nombre) {
    final key = nombre.toLowerCase().trim();
    final data = _categoriaMap[key];
    return data?.gradient ?? _generatedCategoryGradient(key);
  }

  static Color categoryColor(String nombre) {
    final key = nombre.toLowerCase().trim();
    final data = _categoriaMap[key];
    if (data != null) return data.color;
    return categoryGradient(key).first;
  }

  static String categorySubtitle(String nombre, {String? fallback}) =>
      (_categoriaMap[nombre.toLowerCase().trim()] ?? _default).subtitle ??
      fallback ??
      '';

  static IconData subcategoryIcon(String nombre) =>
      (_subcategoriaMap[nombre.toLowerCase().trim()] ?? _defaultSub).icon;

  static Color subcategoryColor(String nombre) =>
      (_subcategoriaMap[nombre.toLowerCase().trim()] ?? _defaultSub).color;

  static IconData servicioIcon(String? tipoNombre) {
    if (tipoNombre == null) return _defaultSub.icon;
    return (_subcategoriaMap[tipoNombre.toLowerCase().trim()] ?? _defaultSub).icon;
  }

  static Color servicioColor(String? tipoNombre) {
    if (tipoNombre == null) return _defaultSub.color;
    return (_subcategoriaMap[tipoNombre.toLowerCase().trim()] ?? _defaultSub).color;
  }
}

// Tipos internos de datos visuales
class _VisualData {
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final String? subtitle;
  const _VisualData({
    required this.icon,
    required this.color,
    required this.gradient,
    this.subtitle,
  });
}

class _SubVisualData {
  final IconData icon;
  final Color color;
  const _SubVisualData({required this.icon, required this.color});
}
