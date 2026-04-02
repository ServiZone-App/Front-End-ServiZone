import 'package:flutter/material.dart';
import 'package:servizone_app/presentation/views/auth/login_screen.dart';
import 'package:servizone_app/presentation/views/auth/register_screen.dart';
import 'package:servizone_app/presentation/views/client/home_client_screen.dart';
import 'package:servizone_app/presentation/views/admin/dashboard_screen.dart';
import 'package:servizone_app/presentation/views/provider/provider_home_screen.dart';
import 'package:servizone_app/presentation/views/guest/guest_home_screen.dart';
import 'package:servizone_app/presentation/views/splash/splash_screen.dart';

import 'package:servizone_app/presentation/views/auth/forgot_password_screen.dart';
import 'package:servizone_app/presentation/views/provider/provider_request_screen.dart';
import 'package:servizone_app/presentation/views/admin/category_management_screen.dart';

import 'package:servizone_app/presentation/views/provider/provider_requests_view.dart';
import 'package:servizone_app/presentation/views/admin/providers/provider_requests_screen.dart';
import 'package:servizone_app/presentation/views/admin/reports/audit_logs_screen.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/domain/repositories/auth_repository.dart';
import 'package:servizone_app/core/constants/app_constants.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String clientHome = '/client/home';
  static const String providerHome = '/provider/home';
  static const String guestHome = '/guest/home';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProviderRequests = '/admin/provider-requests';
  static const String providerRequests = '/provider/requests';
  static const String reservas = '/reservas';
  static const String account = '/account';
  static const String providerProfile = '/provider/profile';
  static const String providerEditProfile = '/provider/edit-profile';
  static const String providerChangePassword = '/provider/change-password';
  static const String clientApplication = '/provider/client-application';
  static const String auditLogs = '/admin/audit-logs';
  

  static const String forgotPassword = '/auth/forgot-password';
  static const String providerRequest = '/provider/request';
  static const String categoryManagement = '/admin/categories';
  static const String subcategoryManagement = '/admin/subcategories';
  static const String serviceTypeManagement = '/admin/service-types';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final authService = locator<AuthRepository>();
    final routeName = settings.name ?? '';
    final isAdminRoute = routeName.startsWith('/admin');
    final isClientRoute = routeName.startsWith('/client');
    final isProviderRoute = routeName.startsWith('/provider') &&
        routeName != providerRequest &&
        routeName != clientApplication;

    // --- Admin Guard ---
    if (isAdminRoute &&
        (!authService.isLoggedIn || authService.currentRole != 'admin')) {
      return MaterialPageRoute(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : backgroundGray,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: errorRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 64, color: errorRed),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Acceso Restringido', 
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : darkGray,
                        fontFamily: 'Poppins'
                      )
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tu cuenta actual (${authService.currentRole}) no tiene permisos administrativos para acceder a esta sección.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16, 
                        color: isDark ? Colors.white70 : textGray,
                        height: 1.5
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed(login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('VOLVER AL LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      );
    }

    if (isClientRoute &&
        (!authService.isLoggedIn || authService.currentRole != 'cliente')) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    if (isProviderRoute &&
        (!authService.isLoggedIn || authService.currentRole != 'proveedor')) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case clientHome:
        return MaterialPageRoute(builder: (_) => const HomeClientScreen());
      case providerHome:
        return MaterialPageRoute(builder: (_) => const ProviderHomeScreen());
      case guestHome:
        return MaterialPageRoute(builder: (_) => const GuestHomeScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case adminProviderRequests:
        return MaterialPageRoute(builder: (_) => const ProviderRequestsScreen());
      case providerRequests:
        return MaterialPageRoute(builder: (_) => const ProviderRequestsView());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case providerRequest:
        return MaterialPageRoute(builder: (_) => const ProviderRequestScreen());
      case categoryManagement:
        return MaterialPageRoute(builder: (_) => const CategoryManagementScreen());
      case subcategoryManagement:
        // TODO: Implementar SubcategoryManagementScreen
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Subcategory Management'))));
      case serviceTypeManagement:
        // TODO: Implementar ServiceTypeManagementScreen
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Service Type Management'))));
      case auditLogs:
        return MaterialPageRoute(builder: (_) => const AuditLogsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no definida: ${settings.name}')),
          ),
        );
    }
  }
}


