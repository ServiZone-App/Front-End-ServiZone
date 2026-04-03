import 'package:flutter/material.dart';

// ------------------- SISTEMA DE COLORES -------------------

// Colores Primarios
const Color primaryBlue = Color(0xFF008CFF);
const Color primaryDarkBlue = Color(0xFF00569D);
const Color backgroundGray = Color(0xFFF1F1F1);
const Color borderGray = Color(0xFFD9D9D9);
const Color textGray = Color(0xFF666666);

// Colores Secundarios (Estados)
const Color successGreen = Color(0xFF4A9F4E);    // Confirmado / Completado
const Color warningOrange = Color(0xFFFE9F2A);   // Pendiente
const Color errorRed = Color(0xFFB40023);        // Rechazado / Cancelado
const Color primaryRed = Color(0xFFB40023);      // Alias para errorRed
const Color secondaryRed = Color(0xFFEB3D30);    // Rechazado / Cancelado (Variación)

// Otros Colores Secundarios
const Color bordeauxRed = Color(0xFF790102);
const Color purple = Color(0xFF9A459E);
const Color pink = Color(0xFFDD5A8F);

// Colores de Interfaz
const Color darkGray = Color(0xFF262626);
const Color lightGray = Color(0xFFF8F9FA);
const Color mediumGray = Color(0xFF8E8E93);
const Color cardShadow = Color(0x1A000000);

// ------------------- CLAVES DE ALMACENAMIENTO SEGURO -------------------

class StorageKeys {
  StorageKeys._();
  static const String token = 'token';
  static const String role = 'role';
  static const String userId = 'userId';
  static const String accessToken = 'accessToken';
  static const String refreshToken = 'refreshToken';
}

// ------------------- SISTEMA DE TIPOGRAFÍA -------------------

const String fontFamilyPoppins = 'Poppins';
const String fontFamilyRoboto = 'Roboto';

// Títulos: Poppins Semibold, 24-28px
const TextStyle textStyleTitleLarge = TextStyle(
  fontFamily: fontFamilyPoppins,
  fontWeight: FontWeight.w600,
  fontSize: 28,
  color: textGray,
);

const TextStyle textStyleTitleMedium = TextStyle(
  fontFamily: fontFamilyPoppins,
  fontWeight: FontWeight.w600,
  fontSize: 24,
  color: textGray,
);

// Subtítulos: Poppins Medium, 18-20px
const TextStyle textStyleSubtitleLarge = TextStyle(
  fontFamily: fontFamilyPoppins,
  fontWeight: FontWeight.w500,
  fontSize: 20,
  color: textGray,
);

const TextStyle textStyleSubtitleMedium = TextStyle(
  fontFamily: fontFamilyPoppins,
  fontWeight: FontWeight.w500,
  fontSize: 18,
  color: textGray,
);

// Texto general: Roboto Regular, 14-16px
const TextStyle textStyleBodyLarge = TextStyle(
  fontFamily: fontFamilyRoboto,
  fontWeight: FontWeight.w400,
  fontSize: 16,
  color: textGray,
);

const TextStyle textStyleBodyMedium = TextStyle(
  fontFamily: fontFamilyRoboto,
  fontWeight: FontWeight.w400,
  fontSize: 14,
  color: textGray,
);

// Texto de ayuda: Roboto Light, 12-13px
const TextStyle textStyleHelperLarge = TextStyle(
  fontFamily: fontFamilyRoboto,
  fontWeight: FontWeight.w300,
  fontSize: 13,
  color: textGray,
);

const TextStyle textStyleHelperSmall = TextStyle(
  fontFamily: fontFamilyRoboto,
  fontWeight: FontWeight.w300,
  fontSize: 12,
  color: textGray,
);
