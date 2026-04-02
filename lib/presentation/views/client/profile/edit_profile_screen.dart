import 'package:flutter/material.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/providers/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String _userName = 'Usuario';
  String _userLastName = '';
  String _userEmail = '';
  String _userPhone = '';

  bool _isEditing = false;
  bool _isLoading = false;
  bool _showSuccess = false;
  bool _showError = false;
  String _errorMessage = 'Error al actualizar';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final data = locator<AuthService>().currentUserProfile;
    if (mounted && data != null) {
      setState(() {
        _userName = data['nombre'] ?? data['Nombre'] ?? 'Usuario';
        _userLastName = data['apellido'] ?? data['Apellido'] ?? '';
        _userEmail = data['correo'] ?? data['Correo'] ?? '';
        _userPhone = data['celular'] ?? data['Celular'] ?? '';

        _emailController.text = _userEmail;
        _phoneController.text = _userPhone;
      });
    }
  }

  String _getInitials(String name) {
    String trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    List<String> parts = trimmed.split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + (parts[1].isNotEmpty ? parts[1].substring(0, 1) : '')).toUpperCase();
  }

  Future<void> _updateData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await locator<AuthService>().updatePerfilCliente({
      'correo': _emailController.text.trim(),
      'celular': _phoneController.text.trim(),
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        setState(() {
          _isEditing = false;
          _userEmail = _emailController.text.trim();
          _userPhone = _phoneController.text.trim();
          _showSuccess = true;
        });
        
        // Recargar datos desde el perfil para asegurar consistencia
        _loadUserData();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showSuccess = false);
        });
      } else {
        // Solo redirigir al login si el error es 401 Unauthorized (token expirado y refresh falló)
        if (result['statusCode'] == 401) {
          // El ApiClient ya disparó onSessionExpired, pero podemos forzar navegación si es necesario
          return;
        }

        setState(() {
          _showError = true;
          _errorMessage = result['message'] ?? 'Error al actualizar la información';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showError = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Stack(
        children: [
          Column(
            children: [
              // Header con avatar, nombre y botón Volver azul
              Container(
                height: 80,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_userName),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(70, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Volver',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Row(
                            children: [
                              Text(
                                _isEditing ? 'Editar información' : 'Información personal',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: darkGray,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isEditing ? Icons.edit : Icons.person,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Nombre (siempre solo lectura)
                          _buildInfoRow('Nombre', _userName, isReadOnly: true),
                          const SizedBox(height: 20),

                          // Apellido (siempre solo lectura)
                          _buildInfoRow('Apellido', _userLastName.isNotEmpty ? _userLastName : 'No especificado', isReadOnly: true),
                          const SizedBox(height: 20),

                          // Correo electrónico (editable solo en modo edición)
                          _buildEditableField(
                            label: 'Correo electrónico',
                            value: _userEmail,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            isEditing: _isEditing,
                          ),
                          const SizedBox(height: 20),

                          // Número de celular (editable solo en modo edición)
                          _buildEditableField(
                            label: 'Número de celular',
                            value: _userPhone,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            isEditing: _isEditing,
                          ),

                          const SizedBox(height: 32),

                          // Botones según modo
                          if (_isEditing)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        // Restaurar valores originales
                                        _emailController.text = _userEmail;
                                        _phoneController.text = _userPhone;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: const BorderSide(color: textGray),
                                    ),
                                    child: const Text(
                                      'Cancelar',
                                      style: TextStyle(color: textGray, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _updateData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Text(
                                      'Guardar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _isEditing = true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Editar información personal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Barra de gestos iOS
              Container(
                height: 20,
                alignment: Alignment.topCenter,
                child: Container(
                  width: 140,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),

          // Modales
          if (_showSuccess)
            _buildModal(
              icon: Icons.check_circle,
              color: Colors.green,
              message: 'Datos actualizados',
            ),
          if (_showError)
            _buildModal(
              icon: Icons.cancel,
              color: Colors.red,
              message: _errorMessage,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: isReadOnly ? Colors.grey.shade600 : darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required bool isEditing,
    int maxLines = 1,
  }) {
    if (!isEditing) {
      return _buildInfoRow(label, value);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 16,
            color: darkGray,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              borderSide: const BorderSide(color: primaryBlue),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Campo requerido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildModal({required IconData icon, required Color color, required String message}) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 70, color: color),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: darkGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}