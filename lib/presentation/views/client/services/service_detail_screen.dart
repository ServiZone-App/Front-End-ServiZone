import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:servizone_app/core/constants/app_constants.dart';

enum BookingState { idle, checkingAvailability, confirming, processing, success, error }

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  BookingState _bookingState = BookingState.idle;

  Future<void> _solicitarReserva() async {
    if (_bookingState == BookingState.processing) return;
    setState(() => _bookingState = BookingState.processing);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _bookingState = BookingState.idle);
    } catch (_) {
      if (!mounted) return;
      setState(() => _bookingState = BookingState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    const reviews = <Map<String, String>>[];
    final int reviewCount = (widget.service['reviewCount'] as int?) ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Regresar',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner superior
              Semantics(
                label: 'Imagen ilustrativa del servicio ${widget.service['name']}',
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A1A),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Icon(Icons.chair_rounded, size: 80, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Información del servicio
              Text(
                widget.service['name'],
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                widget.service['professional'],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textGray),
              ),
              const SizedBox(height: 8),
              _buildRatingRow(),
              const SizedBox(height: 24),

              // Solicitud de reserva
              _buildBookingComponent(),

              const SizedBox(height: 32),

              // Detalles
              _buildCardSection(
                title: 'Detalles del servicio',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.service['description'] as String?)?.trim().isNotEmpty == true
                          ? widget.service['description']
                          : 'Sin descripción disponible.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    Text(
                      'Costo: \$${NumberFormat('#,###').format(widget.service['price'])}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: primaryBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reseñas
              _buildCardSection(
                title: 'Reseñas',
                subtitle: '($reviewCount) Reseñas',
                content: reviews.isEmpty
                    ? const Text('Aún no hay reseñas para este servicio.',
                        style: TextStyle(color: textGray))
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 32),
                        itemBuilder: (context, index) =>
                            _buildReviewItem(reviews[index]),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 20),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${widget.service['rating']} ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text:
                    '(${(widget.service['reviewCount'] as int?) ?? 0}) Reseñas',
                style: const TextStyle(color: textGray, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingComponent() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _bookingState == BookingState.processing ? null : _solicitarReserva,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF43A047),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: _bookingState == BookingState.processing
            ? const SizedBox(
                height: 24,
                width: 24,
                child:
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Solicitar reserva',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildCardSection({required String title, String? subtitle, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) Text(subtitle, style: const TextStyle(color: textGray, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, String> review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(review['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(review['comment']!, style: const TextStyle(color: textGray, fontSize: 14)),
      ],
    );
  }
}
