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

class _ServiceDetailScreenState extends State<ServiceDetailScreen> with SingleTickerProviderStateMixin {
  BookingState _bookingState = BookingState.idle;
  String? _errorMessage;
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;

  @override
  void initState() {
    super.initState();
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expansionController.dispose();
    super.dispose();
  }

  Future<void> _startBookingFlow() async {
    setState(() {
      _bookingState = BookingState.checkingAvailability;
    });

    // Simular validación asíncrona de disponibilidad (API REST mock)
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock de error aleatorio (4xx/5xx)
      // if (DateTime.now().second % 5 == 0) throw 'Error de red (500)';

      setState(() {
        _bookingState = BookingState.confirming;
      });
      _expansionController.forward();
    } catch (e) {
      setState(() {
        _bookingState = BookingState.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmBooking() async {
    setState(() {
      _bookingState = BookingState.processing;
    });

    // Simular guardado en backend
    try {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _bookingState = BookingState.success;
      });
      
      // Feedback táctil y visual
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Reserva confirmada exitosamente!'),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _bookingState = BookingState.error;
        _errorMessage = 'No se pudo procesar la reserva. Reintento automático en curso...';
      });
      // Simular reintento automático
      await Future.delayed(const Duration(seconds: 3));
      _confirmBooking();
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

              // Componente de Reserva Dinámico
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _bookingState == BookingState.idle || _bookingState == BookingState.checkingAvailability
          ? _buildInitialButton()
          : _buildEmbeddedConfirmation(),
    );
  }

  Widget _buildInitialButton() {
    return SizedBox(
      key: const ValueKey('initial_button'),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _bookingState == BookingState.checkingAvailability ? null : _startBookingFlow,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF43A047),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: _bookingState == BookingState.checkingAvailability
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Reservar Ahora',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildEmbeddedConfirmation() {
    final now = DateTime.now();
    final bookingDate = now.add(const Duration(days: 1));

    return Column(
      key: const ValueKey('confirmation_panel'),
      children: [
        SizeTransition(
          sizeFactor: _expansionAnimation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verificación de disponibilidad exitosa',
                  style: TextStyle(color: successGreen, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildConfirmRow('Fecha:', DateFormat('dd MMM yyyy').format(bookingDate)),
                _buildConfirmRow('Hora:', '10:30 AM'),
                _buildConfirmRow('Duración:', '60 min'),
                _buildConfirmRow('Total:', '\$${NumberFormat('#,###').format(widget.service['price'])}', isTotal: true),
                const Divider(height: 24),
                const Text(
                  'Política: Cancelación gratuita hasta 24h antes.',
                  style: TextStyle(fontSize: 12, color: textGray),
                ),
                const SizedBox(height: 20),
                if (_bookingState == BookingState.error)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_errorMessage ?? 'Error desconocido', style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                _buildFinalActionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textGray, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isTotal ? primaryBlue : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalActionButtons() {
    if (_bookingState == BookingState.success) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: successGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: successGreen),
            SizedBox(width: 8),
            Text('¡Reserva Confirmada!', style: TextStyle(color: successGreen, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 250) {
          // Fallback for very narrow screens
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _bookingState == BookingState.processing ? null : () {
                    _expansionController.reverse().then((_) {
                      setState(() => _bookingState = BookingState.idle);
                    });
                  },
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Modificar'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _bookingState == BookingState.processing ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _bookingState == BookingState.processing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirmar'),
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _bookingState == BookingState.processing ? null : () {
                  _expansionController.reverse().then((_) {
                    setState(() => _bookingState = BookingState.idle);
                  });
                },
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Modificar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _bookingState == BookingState.processing ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _bookingState == BookingState.processing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmar'),
              ),
            ),
          ],
        );
      },
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
