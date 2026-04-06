import 'package:flutter/material.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/data/providers/admin_audit_service.dart';
import 'package:servizone_app/data/models/auth/solicitud_model.dart';
import 'package:servizone_app/presentation/views/admin/shared/admin_shared_widgets.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  final List<SolicitudDto> _requests = [];
  final List<SolicitudDto> _filteredRequests = [];
  final TextEditingController _searchController = TextEditingController();
  final AdminAuditService _auditService = locator<AdminAuditService>();
  
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await locator<AuthService>().getSolicitudesProveedor();
      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        if (mounted) {
          setState(() {
            _requests.clear();
            final parsed = data.map((e) => SolicitudDto.fromJson(e)).toList();
            final seen = <int>{};
            _requests.addAll(parsed.where((s) => seen.add(s.id)));
            _applyFilter(_searchQuery);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error inesperado: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter(String query) {
    _searchQuery = query;
    _filteredRequests.clear();
    if (query.isEmpty) {
      _filteredRequests.addAll(_requests);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredRequests.addAll(_requests.where((r) => 
        r.usuarioNombre.toLowerCase().contains(lowerQuery) || 
        r.usuarioCorreo.toLowerCase().contains(lowerQuery) ||
        r.descripcionPerfil.toLowerCase().contains(lowerQuery)
      ));
    }
  }

  Future<void> _handleRequest(SolicitudDto request, bool accept) async {
    setState(() => _isProcessing = true);

    try {
      final result = await locator<AuthService>().procesarSolicitudProveedor(request.id, accept);
      
      if (result['success']) {
        await _auditService.logAction(
          accept ? 'APROBACIÓN PROVEEDOR' : 'RECHAZO PROVEEDOR',
          'Solicitud #${request.id} de ${request.usuarioNombre} (${request.usuarioCorreo}) fue ${accept ? 'APROBADA' : 'RECHAZADA'}.'
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? (accept ? 'Solicitud Aprobada' : 'Solicitud Rechazada')),
              backgroundColor: accept ? successGreen : errorRed,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        _loadRequests();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['message']}'), 
              backgroundColor: errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error crítico: $e'), backgroundColor: errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(130),
            child: AdminHeader(
              title: 'Solicitudes',
              subtitle: 'Revisión técnica de aspirantes a proveedores',
              action: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: primaryBlue),
                onPressed: _loadRequests,
                tooltip: 'Actualizar lista',
              ),
            ),
          ),
          body: Column(
            children: [
              AdminSearchBar(
                controller: _searchController,
                hintText: 'Filtrar por nombre o correo...',
                onChanged: (val) => setState(() => _applyFilter(val)),
              ),
              Expanded(
                child: _isLoading
                    ? const AdminLoadingOverlay()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _filteredRequests.isEmpty
                            ? const AdminEmptyState(
                                icon: Icons.person_add_disabled_rounded,
                                title: 'Sin solicitudes',
                                subtitle: 'No se encontraron peticiones pendientes que coincidan con tu búsqueda.',
                              )
                            : _buildRequestsList(),
              ),
            ],
          ),
        ),
        if (_isProcessing)
          const AdminLoadingOverlay(),
      ],
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: errorRed),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white70 : textGray, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('REINTENTAR CONEXIÓN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) => _buildRequestCard(_filteredRequests[index]),
    );
  }

  Widget _buildRequestCard(SolicitudDto request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: isDark ? null : const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: isDark ? Colors.white54 : textGray,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          iconColor: primaryBlue,
          collapsedIconColor: isDark ? Colors.white54 : textGray,
          leading: _buildAvatar(request.usuarioNombre),
          title: Text(
            request.usuarioNombre,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : darkGray,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.usuarioCorreo, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : textGray)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone_rounded, size: 12, color: isDark ? Colors.white38 : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    request.usuarioTelefono,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : textGray),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                   Icon(Icons.access_time_rounded, size: 12, color: isDark ? Colors.white38 : Colors.grey),
                   const SizedBox(width: 4),
                   Text(
                     'Hace ${_getDaysAgo(request.fechaSolicitud)}',
                     style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey),
                   ),
                ],
              ),
            ],
          ),
          trailing: AdminDataBadge.status(request.estado),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 32, color: isDark ? Colors.white10 : null),
                  _buildDetailRow(Icons.phone_iphone_rounded, 'Teléfono', request.usuarioTelefono),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.history_edu_rounded, 'Experiencia', '${request.anosExperiencia} años'),
                  const SizedBox(height: 20),
                  const Text(
                    'PROPUESTA DE SERVICIO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : backgroundGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      request.descripcionPerfil.isEmpty ? 'Sin descripción proporcionada.' : request.descripcionPerfil,
                      style: TextStyle(
                        fontSize: 13, 
                        color: isDark ? Colors.white70 : darkGray, 
                        height: 1.5
                      ),
                    ),
                  ),
                  if (request.documentos.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'DOCUMENTACIÓN VERIFICABLE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: request.documentos.length,
                        itemBuilder: (ctx, i) => _buildDocItem(request.documentos[i]),
                      ),
                    ),
                  ],
                  if (!['aprobada', 'rechazada'].contains(request.estado.toLowerCase())) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleRequest(request, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: errorRed,
                              side: const BorderSide(color: errorRed),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('RECHAZAR', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleRequest(request, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('APROBAR', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: primaryBlue.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
          style: TextStyle(
            color: isDark ? Colors.white : primaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white38 : Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : textGray)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : darkGray)),
      ],
    );
  }

  Widget _buildDocItem(String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawName = url.split('/').last.split('?').first;
    final displayName = rawName.isNotEmpty ? rawName : 'Documento';

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.file_present_rounded, size: 16, color: primaryBlue),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              displayName,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : darkGray),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getDaysAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'hoy';
    if (diff == 1) return 'ayer';
    return '$diff días';
  }
}