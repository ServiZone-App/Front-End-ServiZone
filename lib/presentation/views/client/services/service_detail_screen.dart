import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/models/booking/resena_dto.dart';
import 'package:servizone_app/data/providers/booking_api_service.dart';
import 'package:servizone_app/presentation/viewmodels/solicitudes_reservas_view_model.dart';

enum BookingState { idle, checkingAvailability, confirming, processing, success, error }

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  static const _bannerColors = [
    Color(0xFFFF7A1A), Color(0xFF1A73E8), Color(0xFF43A047),
    Color(0xFF8E24AA), Color(0xFFE53935), Color(0xFF00897B),
    Color(0xFFFFB300), Color(0xFF3949AB),
  ];

  BookingState _bookingState = BookingState.idle;
  List<ResenaDto> _resenas = [];
  bool _resenasLoading = true;
  late final Color _bannerColor;

  @override
  void initState() {
    super.initState();
    _bannerColor = _bannerColors[Random().nextInt(_bannerColors.length)];
    _loadResenas();
  }

  Future<void> _loadResenas() async {
    final serviceId = widget.service['id'];
    if (serviceId == null) {
      setState(() => _resenasLoading = false);
      return;
    }
    final apiService = locator<BookingApiService>();
    final res = await apiService.getResenasServicio(serviceId as int);
    if (!mounted) return;
    setState(() {
      _resenas = res.success ? (res.data ?? []) : [];
      _resenasLoading = false;
    });
  }

  Future<void> _solicitarReserva() async {
    if (_bookingState == BookingState.processing) return;
    final serviceId = widget.service['id'];
    if (serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar el servicio.'), backgroundColor: errorRed),
      );
      return;
    }
    setState(() => _bookingState = BookingState.processing);
    final vm = locator<SolicitudesReservasViewModel>();
    final res = await vm.solicitarServicio(serviceId as int);
    if (!mounted) return;
    if (res.success) {
      setState(() => _bookingState = BookingState.success);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud enviada! El proveedor la revisará pronto.'),
          backgroundColor: successGreen,
        ),
      );
    } else {
      setState(() => _bookingState = BookingState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'No se pudo enviar la solicitud.'),
          backgroundColor: errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int reviewCount = _resenas.length;

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
                    color: _bannerColor,
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
                content: _resenasLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2))
                    : _resenas.isEmpty
                        ? const Text('Aún no hay reseñas para este servicio.',
                            style: TextStyle(color: textGray))
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _resenas.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 24),
                            itemBuilder: (context, index) =>
                                _buildResenaItem(_resenas[index]),
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
                text: '(${_resenas.length}) Reseñas',
                style: const TextStyle(color: textGray, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingComponent() {
    if (_bookingState == BookingState.success) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: successGreen,
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              '¡Solicitud enviada!',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      );
    }
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
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Solicitar reserva',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildResenaItem(ResenaDto resena) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                resena.clienteNombre ?? 'Cliente',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: darkGray),
              ),
            ),
            Row(
              children: List.generate(5, (i) => Icon(
                i < resena.calificacion ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFFFA726),
                size: 18,
              )),
            ),
          ],
        ),
        if (resena.comentario != null && resena.comentario!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            resena.comentario!,
            style: const TextStyle(fontSize: 13, color: textGray, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}
