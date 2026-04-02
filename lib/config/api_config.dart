import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get authBaseUrl {
    const env = String.fromEnvironment('AUTH_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    return kIsWeb ? 'http://localhost:5059/api' : 'https://10.0.2.2:5059/api';
  }

  static String get catalogBaseUrl {
    const env = String.fromEnvironment('CATALOG_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    return kIsWeb ? 'http://localhost:5257/api' : 'https://10.0.2.2:5257/api';
  }
}
