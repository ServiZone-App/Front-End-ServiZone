import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuditLog {
  final String action;
  final String details;
  final DateTime timestamp;
  final String adminEmail;

  AuditLog({
    required this.action,
    required this.details,
    required this.timestamp,
    required this.adminEmail,
  });

  Map<String, dynamic> toJson() => {
    'action': action,
    'details': details,
    'timestamp': timestamp.toIso8601String(),
    'adminEmail': adminEmail,
  };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    action: json['action'],
    details: json['details'],
    timestamp: DateTime.parse(json['timestamp']),
    adminEmail: json['adminEmail'] ?? 'admin@servizone.com',
  );
}

class AdminAuditService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _storageKey = 'admin_audit_logs';
  List<AuditLog> _logs = [];

  List<AuditLog> get logs => List.unmodifiable(_logs);

  AdminAuditService() {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final String? storedLogs = await _storage.read(key: _storageKey);
      if (storedLogs != null) {
        final List<dynamic> decoded = jsonDecode(storedLogs);
        _logs = decoded.map((e) => AuditLog.fromJson(e)).toList();
        _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cargando logs de auditoría: $e');
    }
  }

  Future<void> logAction(String action, String details, {String? adminEmail}) async {
    final newLog = AuditLog(
      action: action,
      details: details,
      timestamp: DateTime.now(),
      adminEmail: adminEmail ?? 'admin@servizone.com',
    );

    _logs.insert(0, newLog);
    
    // Mantener un límite razonable (ej. 500 logs)
    if (_logs.length > 500) {
      _logs = _logs.sublist(0, 500);
    }

    await _saveLogs();
    notifyListeners();
  }

  Future<void> _saveLogs() async {
    try {
      final String encoded = jsonEncode(_logs.map((e) => e.toJson()).toList());
      await _storage.write(key: _storageKey, value: encoded);
    } catch (e) {
      debugPrint('Error guardando logs de auditoría: $e');
    }
  }

  Future<void> clearLogs() async {
    _logs.clear();
    await _storage.delete(key: _storageKey);
    notifyListeners();
  }
}
