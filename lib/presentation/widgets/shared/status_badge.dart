import 'package:flutter/material.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/data/models/booking_model.dart';

class StatusBadge extends StatelessWidget {
  final BookingStatus status;
  final String? customText;

  const StatusBadge({
    super.key,
    required this.status,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(20), // Siempre bordes redondeados
      ),
      child: Text(
        (customText ?? status.name).toUpperCase(),
        style: const TextStyle(
          color: Colors.white, // Texto SIEMPRE blanco
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamilyRoboto,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case BookingStatus.pendiente:
        return const Color(0xFFFE9F2A); // Pendiente: Naranja
      case BookingStatus.enRevision:
        return const Color(0xFF0288D1); // En revisión: Azul informativo
      case BookingStatus.enProceso:
        return const Color(0xFF00796B); // En proceso: Verde teal
      case BookingStatus.confirmada:
        return const Color(0xFF4A9F4E); // Confirmada: Verde
      case BookingStatus.cancelada:
        return const Color(0xFFEB3D30); // Cancelada: Rojo Claro
      case BookingStatus.rechazada:
        return const Color(0xFF790102); // Rechazada: Rojo Oscuro
      case BookingStatus.completada:
        return const Color(0xFF00569D); // Completada: Azul Oscuro
    }
  }
}
