import 'package:flutter/material.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/core/routes/app_routes.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/data/providers/catalog_notifier.dart';
import 'package:servizone_app/core/constants/app_constants.dart';

class ProviderEditProfileScreen extends StatefulWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  State<ProviderEditProfileScreen> createState() => _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState extends State<ProviderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  late TextEditingController _experienceController;

  String _userName = 'Usuario';
  String _userLastName = 'Apellido';
  String _userEmail = 'proveedor@ejemplo.com';
  String _userPhone = '+57 300 000 0000';
  String _userDescription = 'Especialista en servicios del hogar con alta atención al detalle.';
  String _userExperience = '5';

  bool _isLoading = false;
  bool _isEditing = false;

  bool _showSuccess = false;
  bool _showError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: _userEmail);
    _phoneController = TextEditingController(text: _userPhone);
    _descriptionController = TextEditingController(text: _userDescription);
    _experienceController = TextEditingController(text: _userExperience);
    _loadUserData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
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
        _userDescription = data['descripcionPerfil'] ?? data['DescripcionPerfil'] ?? 'Sin descripción';
        _userExperience = data['anosExperiencia']?.toString() ?? data['AnosExperiencia']?.toString() ?? '0';

        _emailController.text = _userEmail;
        _phoneController.text = _userPhone;
        _descriptionController.text = _userDescription;
        _experienceController.text = _userExperience;
      });
    }
  }

  String _getInitials(String name) {
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _performLogout() async {
    locator<CatalogNotifier>().clearProviderSession();
    await locator<AuthService>().logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  Future<void> _updateData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await locator<AuthService>().updatePerfilProveedor({
      'correo': _emailController.text.trim(),
      'celular': _phoneController.text.trim(),
      'descripcionPerfil': _descriptionController.text.trim(),
      'anosExperiencia': int.tryParse(_experienceController.text.trim()) ?? 0,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      // Tratar requiresRelogin como éxito: el PATCH funcionó pero el backend
      // invalidó la sesión, así que mostramos el modal de éxito y cerramos sesión.
      if (result['success'] == true || result['requiresRelogin'] == true) {
        setState(() {
          _isEditing = false;
          _userEmail = _emailController.text.trim();
          _userPhone = _phoneController.text.trim();
          _userDescription = _descriptionController.text.trim();
          _userExperience = _experienceController.text.trim();
          _showSuccess = true;
        });
      } else {
        setState(() {
          _showError = true;
          _errorMessage = result['message'] ?? 'Error al actualizar la información';
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
                      '@$_userName',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    // Botón Volver azul
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
                          
                          _buildInfoRow('Nombre', _userName, isReadOnly: true),
                          const SizedBox(height: 20),
                          _buildInfoRow('Apellido', _userLastName, isReadOnly: true),
                          const SizedBox(height: 20),
                          _buildEditableField('Correo electrónico', _userEmail, _emailController, TextInputType.emailAddress),
                          const SizedBox(height: 20),
                          _buildEditableField('Número de celular', _userPhone, _phoneController, TextInputType.phone),
                          const SizedBox(height: 20),
                          _buildEditableField('Descripción de perfil', _userDescription, _descriptionController, TextInputType.multiline, maxLines: 3),
                          const SizedBox(height: 20),
                          _buildEditableField('Años de experiencia', _userExperience, _experienceController, TextInputType.number),
                          const SizedBox(height: 20),
                          
                          const SizedBox(height: 24),
                          if (_isEditing)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        // Reset controllers to current values
                                        _emailController.text = _userEmail;
                                        _phoneController.text = _userPhone;
                                        _descriptionController.text = _userDescription;
                                        _experienceController.text = _userExperience;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      side: const BorderSide(color: textGray),
                                    ),
                                    child: const Text('Cancelar', style: TextStyle(color: textGray, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _updateData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isLoading 
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ]
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Editar información personal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
              message: 'Datos actualizados correctamente, inicie sesion nuevamente.',
              buttonLabel: 'Aceptar',
              onClose: _performLogout,
            ),
          if (_showError)
            _buildModal(
              icon: Icons.cancel,
              color: Colors.red,
              message: _errorMessage,
              buttonLabel: 'Cerrar',
              onClose: () => setState(() => _showError = false),
            ),
        ],
      ),
    );
  }



  Widget _buildModal({
    required IconData icon,
    required Color color,
    required String message,
    required String buttonLabel,
    required VoidCallback onClose,
  }) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 70, color: color),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildEditableField(String label, String value, TextEditingController controller, TextInputType keyboardType, {int maxLines = 1}) {
    if (!_isEditing) {
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

}

