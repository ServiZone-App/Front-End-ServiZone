import 'package:flutter/material.dart';
import 'package:servizone_app/config/environment_config.dart';
import 'package:servizone_app/core/routes/app_routes.dart';
import 'package:servizone_app/core/themes/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/core/network/api_client.dart';
import 'package:servizone_app/data/providers/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización concurrente de configuraciones base para optimizar el inicio
  await Future.wait([
    EnvironmentConfig.load(),
    // Añadir aquí otras inicializaciones asíncronas futuras (Firebase, etc.)
  ]);

  setupLocator(); // Inyección de dependencias (GetIt es síncrono y ultra rápido)

  final navigatorKey = GlobalKey<NavigatorState>();
  void handleSessionExpired() {
    // Limpiar estado interno de AuthService para evitar sesión fantasma
    locator<AuthService>().logout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  locator<ApiClient>(instanceName: 'auth').onSessionExpired = handleSessionExpired;
  locator<ApiClient>(instanceName: 'catalog').onSessionExpired = handleSessionExpired;

  runApp(ServiZoneApp(navigatorKey: navigatorKey));
}

class ServiZoneApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const ServiZoneApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ServiZone',
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
    );
  }
}
