import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servizone_app/core/constants/app_constants.dart';

import 'package:servizone_app/presentation/views/provider/provider_home_screen.dart';
import 'package:servizone_app/presentation/views/provider/services/provider_services_screen.dart';
import 'package:servizone_app/presentation/views/provider/provider_requests_view.dart';
import 'package:servizone_app/presentation/views/provider/provider_bookings_screen.dart';
import 'package:servizone_app/presentation/views/provider/profile/provider_profile_screen.dart';

class ProviderBottomNav extends StatelessWidget {
  final int currentIndex;

  const ProviderBottomNav({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    if (index == currentIndex) return;

    Widget targetScreen;
    switch (index) {
      case 0:
        targetScreen = const ProviderHomeScreen();
        break;
      case 1:
        targetScreen = const ProviderServicesScreen();
        break;
      case 2:
        targetScreen = const ProviderRequestsView();
        break;
      case 3:
        targetScreen = const ProviderBookingsScreen();
        break;
      case 4:
        targetScreen = const ProviderProfileScreen();
        break;
      default:
        targetScreen = const ProviderHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(context, index),
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: primaryBlue, // Activo: #008CFF
        unselectedItemColor: const Color(0xFF666666), // Inactivo: #666666
        selectedLabelStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 10),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 1 ? Icons.grid_view_rounded : Icons.grid_view),
            label: 'Servicios',
          ),
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 2 ? Icons.assignment_rounded : Icons.assignment_outlined),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 3 ? Icons.calendar_month_rounded : Icons.calendar_today_outlined),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 4 ? Icons.person_rounded : Icons.person_outline_rounded),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}
