import 'package:flutter/foundation.dart';

class EnvironmentConfig {
  // CONFIGURACIÓN DE RED: Cambia esta IP por la de tu máquina en la red Wi-Fi
  // TIP: En terminal usa 'ipconfig' (Windows) o 'ifconfig' (Mac/Linux)
  static const String _localIp = '192.168.1.5';
  static const String _apiPort = '5059';
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const bool _allowCleartext =
      bool.fromEnvironment('ALLOW_CLEARTEXT', defaultValue: true);

  static late String apiBaseUrl;
  static late String googleMapsApiKey;
  
  static Future<void> load() async {
    // Inicialización inmediata de variables de entorno
    _initializeSync();
  }
  
  static void _initializeSync() {
    if (_apiBaseUrlOverride.isNotEmpty) {
      apiBaseUrl = _apiBaseUrlOverride;
      googleMapsApiKey = 'TU_API_KEY';
      return;
    }
    if (kIsWeb) {
      // En Web, si el servidor está en la misma máquina, 'localhost' es más seguro para evitar bloqueos de CORS/Red
      apiBaseUrl = 'http://localhost:$_apiPort/api';
    } else {
      // En móvil, usamos la IP local de la red Wi-Fi
      apiBaseUrl = 'http://$_localIp:$_apiPort/api';
    }
    if (!_allowCleartext && apiBaseUrl.startsWith('http://')) {
      apiBaseUrl = apiBaseUrl.replaceFirst('http://', 'https://');
    }
    googleMapsApiKey = 'TU_API_KEY';
  }
  
  // Para diferentes entornos
  static void loadDevelopment() {
    _initializeSync();
    googleMapsApiKey = 'dev_key';
  }
  
  static void loadProduction() {
    apiBaseUrl = 'https://api.servizone.com/v1';
    googleMapsApiKey = 'prod_key';
  }
}


