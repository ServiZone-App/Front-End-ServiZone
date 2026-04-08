import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/providers/auth_service.dart';

class ProviderRequestScreen extends StatefulWidget {
  const ProviderRequestScreen({super.key});

  @override
  State<ProviderRequestScreen> createState() => _ProviderRequestScreenState();
}

class _ProviderRequestScreenState extends State<ProviderRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingStatus = true;
  bool _isBlocked = false;
  // Guardamos los PlatformFile en lugar de File (de dart:io) para compatibilidad Web
  final List<PlatformFile> _selectedFiles = [];
  final List<String> _allowedExtensions = ['pdf', 'doc', 'docx'];

  @override
  void initState() {
    super.initState();
    _checkBlockedStatus();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  int? _parseId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Future<void> _checkBlockedStatus() async {
    final authService = locator<AuthService>();
    final userId = await authService.getCurrentClienteId();

    if (!mounted) return;

    if (userId == null) {
      setState(() => _isCheckingStatus = false);
      return;
    }

    final result = await authService.getProveedoresVerificados();
    if (!mounted) return;

    bool blocked = false;
    if (result['success'] == true && result['data'] is List) {
      final lista = result['data'] as List;
      final match = lista.firstWhere(
        (p) =>
            p is Map<String, dynamic> &&
            _parseId(p['usuarioId'] ?? p['UsuarioId']) == userId,
        orElse: () => null,
      );
      if (match != null) {
        final estado =
            ((match as Map<String, dynamic>)['estado'] ?? match['Estado'] ?? '')
                .toString()
                .toLowerCase();
        blocked = estado == 'bloqueado';
      }
    }

    setState(() {
      _isBlocked = blocked;
      _isCheckingStatus = false;
    });

    if (blocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showBlockedDialog());
    }
  }

  void _showBlockedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: errorRed, size: 28),
            SizedBox(width: 10),
            Text('Cuenta bloqueada', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Tu cuenta se encuentra bloqueada. No puedes enviar solicitudes de proveedor. Contacta al administrador para más información.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    if (_isLoading) return;
    
    HapticFeedback.lightImpact();
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: kIsWeb, // Necesario en Web para obtener bytes
      );

      if (result != null && mounted) {
        setState(() {
          for (var file in result.files) {
            // Evitar duplicados por nombre
            if (!_selectedFiles.any((f) => f.name == file.name)) {
              _selectedFiles.add(file);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivos: $e'), backgroundColor: errorRed),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitRequest() async {
    if (_isBlocked) {
      _showBlockedDialog();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    if (_selectedFiles.isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes adjuntar al menos un archivo (PDF, DOC o DOCX)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final authService = locator<AuthService>();
      
      // En Web no usamos path, enviamos bytes si fuera necesario, 
      // pero AuthService espera paths. Vamos a ajustar esto.
      final result = await authService.enviarSolicitudProveedor(
        descripcion: _descriptionController.text.trim(),
        experiencia: _experienceController.text.trim(),
        files: _selectedFiles,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error desconocido al enviar solicitud'),
            backgroundColor: errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e'), backgroundColor: errorRed),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: successGreen, size: 30),
            SizedBox(width: 10),
            Text('Solicitud enviada'),
          ],
        ),
        content: const Text(
          'Tu solicitud de proveedor ha sido recibida correctamente. Nuestro equipo la revisará pronto.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Entendido', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: const Text('Ser Proveedor', style: TextStyle(color: textGray, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      body: _isCheckingStatus
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Completa tu perfil profesional',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textGray),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuéntanos sobre tu experiencia para que podamos validar tu cuenta de proveedor.',
                style: TextStyle(fontSize: 14, color: textGray),
              ),
              const SizedBox(height: 32),

              _buildLabel('Descripción profesional'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('Ej: Especialista en limpieza profunda con técnicas ecológicas...'),
                validator: (v) => (v == null || v.trim().length < 20) ? 'Mínimo 20 caracteres' : null,
              ),
              const SizedBox(height: 20),

              _buildLabel('Años de experiencia'),
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration('Ej: 5'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final numVal = int.tryParse(v);
                  if (numVal == null || numVal <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              _buildLabel('Documentos de soporte (PDF, DOC, DOCX)'),
              const SizedBox(height: 8),
              _buildFilePicker(),
              
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildFileList(),
              ],

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enviar Solicitud', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textGray),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
    );
  }

  Widget _buildFilePicker() {
    return InkWell(
      onTap: _pickFiles,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryBlue.withValues(alpha: 0.5), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 40, color: primaryBlue.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            const Text('Seleccionar archivos', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('PDF', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return Column(
      children: List.generate(_selectedFiles.length, (index) {
        final file = _selectedFiles[index];
        final name = file.name;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: primaryBlue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: errorRed, size: 20),
                onPressed: () => _removeFile(index),
              ),
            ],
          ),
        );
      }),
    );
  }
}
