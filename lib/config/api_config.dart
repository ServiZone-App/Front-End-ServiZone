class ApiConfig {
  static String get authBaseUrl =>
      const String.fromEnvironment('AUTH_BASE_URL',
          defaultValue: 'https://api-auth-zofr.onrender.com/api');

  static String get catalogBaseUrl =>
      const String.fromEnvironment('CATALOG_BASE_URL',
          defaultValue: 'https://api-service-88ld.onrender.com/api');

  static String get bookingBaseUrl =>
      const String.fromEnvironment('BOOKING_BASE_URL',
          defaultValue: 'https://api-booking-pulm.onrender.com/api');
}
