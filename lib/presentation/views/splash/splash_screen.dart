import 'package:flutter/material.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/presentation/viewmodels/auth_view_model.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = locator<AuthViewModel>();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final res = await _vm.autoLogin();
    final isLoggedIn = res.success && res.data == true;
    
    if (!mounted) return;

    if (isLoggedIn) {
      // Obtener el rol validado
      final role = _vm.currentRole ?? '';
      switch (role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
          break;
        case 'cliente':
        case 'client': // por si acaso
          Navigator.pushReplacementNamed(context, AppRoutes.clientHome);
          break;
        case 'proveedor':
        case 'provider': // por si acaso
          Navigator.pushReplacementNamed(context, AppRoutes.providerHome);
          break;
        default:
          Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      // No hay sesión válida, ir al login
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.handyman,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Servi', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'Zone', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}


