import 'package:flutter/material.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/providers/auth_service.dart';
import 'package:servizone_app/core/constants/app_constants.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _userName = 'Usuario';
  bool _isLoading = false;

  // Visibilidad de contraseñas
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Estados para modales
  bool _showSuccess = false;
  bool _showError = false;
  String _errorMessage = 'Algo salió mal';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final data = locator<AuthService>().currentUserProfile;
    if (data != null && mounted) {
      setState(() {
        _userName = "${data['nombre'] ?? data['Nombre'] ?? ''} ${data['apellido'] ?? data['Apellido'] ?? ''}".trim();
        if (_userName.isEmpty) {
          _userName = 'Usuario Cliente';
        }
      });
    }
  }

  String _getInitials(String name) {
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // Validaciones
  bool _hasMinLength(String pwd) => pwd.length >= 8;
  bool _hasUppercase(String pwd) => pwd.contains(RegExp(r'[A-Z]'));
  bool _hasLowercase(String pwd) => pwd.contains(RegExp(r'[a-z]'));
  bool _hasNumber(String pwd) => pwd.contains(RegExp(r'[0-9]'));
  bool _hasSpecial(String pwd) => pwd.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool _passwordsMatch(String pwd, String confirm) => pwd == confirm && confirm.isNotEmpty;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 14),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _changePassword() async {
    // Validar campos no vacíos
    if (_currentPasswordController.text.isEmpty) {
      _showErrorSnackBar('La contraseña actual es obligatoria');
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      _showErrorSnackBar('La nueva contraseña es obligatoria');
      return;
    }
    if (_confirmPasswordController.text.isEmpty) {
      _showErrorSnackBar('Debes confirmar la nueva contraseña');
      return;
    }

    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;

    // Validar requisitos de la nueva contraseña
    if (!_hasMinLength(newPwd)) {
      _showErrorSnackBar('La nueva contraseña debe tener al menos 8 caracteres');
      return;
    }
    if (!_hasUppercase(newPwd)) {
      _showErrorSnackBar('La nueva contraseña debe incluir una mayúscula');
      return;
    }
    if (!_hasLowercase(newPwd)) {
      _showErrorSnackBar('La nueva contraseña debe incluir una minúscula');
      return;
    }
    if (!_hasNumber(newPwd)) {
      _showErrorSnackBar('La nueva contraseña debe incluir un número');
      return;
    }
    if (!_hasSpecial(newPwd)) {
      _showErrorSnackBar('La nueva contraseña debe incluir un carácter especial');
      return;
    }
    if (!_passwordsMatch(newPwd, confirmPwd)) {
      _showErrorSnackBar('Las contraseñas no coinciden');
      return;
    }
    if (!_hasUppercase(newPwd)) {
      _showErrorSnackBar('Debe contener al menos una letra mayúscula');
      return;
    }
    if (!_hasLowercase(newPwd)) {
      _showErrorSnackBar('Debe contener al menos una letra minúscula');
      return;
    }
    if (!_hasNumber(newPwd)) {
      _showErrorSnackBar('Debe contener al menos un número');
      return;
    }
    if (!_hasSpecial(newPwd)) {
      _showErrorSnackBar('Debe contener al menos un carácter especial (!@#\$%^&*)');
      return;
    }
    if (!_passwordsMatch(newPwd, confirmPwd)) {
      _showErrorSnackBar('Las contraseñas no coinciden');
      return;
    }

    // Cambio de contraseña real con el backend
    setState(() => _isLoading = true);

    final payload = {
      'ContrasenaActual': _currentPasswordController.text,
      'Contrasena': newPwd,
    };

    final role = locator<AuthService>().currentRole;
    Map<String, dynamic> result;
    
    if (role == 'proveedor') {
      result = await locator<AuthService>().updatePerfilProveedor(payload);
    } else {
      result = await locator<AuthService>().updatePerfilCliente(payload);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _showSuccess = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showSuccess = false);
          Navigator.pop(context);
        }
      });
    } else {
      setState(() {
        _showError = true;
        _errorMessage = result['message'] ?? 'Error al cambiar la contraseña';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showError = false);
      });
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
              // Header blanco de 80px
              Container(
                height: 80,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Avatar circular gris
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
                    // Nombre con @
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
                    // Botón Volver con fondo azul
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

              // Contenedor principal con fondo blanco (tarjeta)
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
                          // Título con icono de candado
                          Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 22,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Cambiar contraseña',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: darkGray,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Campo: Contraseña actual
                          const Text(
                            'Contraseña actual',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: darkGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrent,
                            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),

                          const SizedBox(height: 20),

                          // Campo: Contraseña nueva
                          const Text(
                            'Contraseña nueva',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: darkGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPasswordField(
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            onToggle: () => setState(() => _obscureNew = !_obscureNew),
                          ),

                          const SizedBox(height: 20),

                          // Campo: Confirmar contraseña
                          const Text(
                            'Confirmar contraseña',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: darkGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),

                          const SizedBox(height: 32),

                          // Botón Cambiar contraseña
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Cambiar contraseña',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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

          // Modal de éxito
          if (_showSuccess)
            _buildModal(
              icon: Icons.check_circle,
              color: Colors.green,
              message: 'Contraseña actualizada',
            ),

          // Modal de error
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: darkGray,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          // CORRECCIÓN: padding vertical para centrar los asteriscos
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: textGray,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          hintText: '********',
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: textGray,
          ),
        ),
      ),
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
              Icon(
                icon,
                size: 70,
                color: color,
              ),
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


