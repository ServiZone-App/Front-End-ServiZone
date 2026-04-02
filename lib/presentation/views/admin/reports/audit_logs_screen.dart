import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/providers/admin_audit_service.dart';
import 'package:servizone_app/presentation/views/admin/shared/admin_shared_widgets.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final AdminAuditService _auditService = locator<AdminAuditService>();
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _auditService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _auditService.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredLogs = _auditService.logs.where((log) {
      final query = _filterQuery.toLowerCase();
      return log.action.toLowerCase().contains(query) ||
          log.details.toLowerCase().contains(query) ||
          log.adminEmail.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: AdminHeader(
          title: 'Logs de Auditoría',
          subtitle: 'Historial de acciones administrativas críticas',
          action: IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: errorRed),
            onPressed: () => _confirmClearLogs(),
            tooltip: 'Borrar historial',
          ),
        ),
      ),
      body: Column(
        children: [
          AdminSearchBar(
            controller: _searchController,
            hintText: 'Buscar en el historial...',
            onChanged: (val) => setState(() => _filterQuery = val),
          ),
          Expanded(
            child: filteredLogs.isEmpty
                ? const AdminEmptyState(
                    icon: Icons.history_rounded,
                    title: 'Sin registros',
                    subtitle: 'Aún no se han registrado acciones de auditoría en este dispositivo.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: filteredLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return _buildLogCard(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(AuditLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AdminDataBadge(label: log.action, color: Colors.blueGrey),
              Text(
                dateFormat.format(log.timestamp),
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            log.details,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey),
              const SizedBox(width: 4),
              Text(
                log.adminEmail,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmClearLogs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          '¿Borrar historial?', 
          style: TextStyle(color: isDark ? Colors.white : darkGray)
        ),
        content: Text(
          'Esta acción eliminará permanentemente todos los registros de auditoría almacenados en este dispositivo.',
          style: TextStyle(color: isDark ? Colors.white70 : textGray)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              _auditService.clearLogs();
              Navigator.pop(context);
            },
            child: const Text('BORRAR TODO', style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );
  }
}
