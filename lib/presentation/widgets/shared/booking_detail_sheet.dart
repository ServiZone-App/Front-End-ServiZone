import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/data/models/booking/resena_dto.dart';
import 'package:servizone_app/data/models/booking_model.dart';
import 'package:servizone_app/presentation/widgets/shared/status_badge.dart';

class BookingDetailSheet extends StatelessWidget {
  final BookingModel booking;
  final bool isProvider;
  final Widget? actionButtons;
  final ResenaDto? resena;

  const BookingDetailSheet({
    super.key,
    required this.booking,
    this.isProvider = false,
    this.actionButtons,
    this.resena,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Detalles de la Reserva',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 24),

          // Cards container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : backgroundGray,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Categoría', booking.serviceType),
                const SizedBox(height: 16),
                _buildDetailRow('Nombre del servicio', booking.serviceName),
                const SizedBox(height: 16),
                _buildDetailRow(
                  isProvider ? 'Cliente' : 'Proveedor',
                  isProvider ? booking.clientName : (booking.providerName ?? 'No asignado')
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Fecha y hora',
                  DateFormat('EEEE, dd MMMM yyyy - hh:mm a', 'es_ES').format(booking.date),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Estado de la reserva', _statusDisplayName(booking.status)),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Precio', 
                  '\$${NumberFormat('#,###').format(booking.price)}',
                  textColor: primaryBlue,
                  isHighlight: true,
                ),
              ],
            ),
          ),
          
          // Reseña (visible cuando hay reseña en reservas completadas)
          if (resena != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFA726).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        isProvider ? 'Reseña del cliente' : 'Tu reseña',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isProvider)
                        Text(
                          resena!.clienteNombre ?? 'Cliente',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            color: textGray,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < resena!.calificacion
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFFA726),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (resena!.comentario != null && resena!.comentario!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      resena!.comentario!,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        color: textGray,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (actionButtons != null) ...[
            const SizedBox(height: 24),
            actionButtons!,
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _statusDisplayName(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendiente:  return 'Pendiente';
      case BookingStatus.enRevision: return 'En revisión';
      case BookingStatus.enProceso:  return 'En proceso';
      case BookingStatus.confirmada: return 'Confirmada';
      case BookingStatus.completada: return 'Completada';
      case BookingStatus.cancelada:  return 'Cancelada';
      case BookingStatus.rechazada:  return 'Rechazada';
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor, bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: textGray,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isHighlight ? 18 : 15,
              fontWeight: FontWeight.bold,
              color: textColor ?? darkGray,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
