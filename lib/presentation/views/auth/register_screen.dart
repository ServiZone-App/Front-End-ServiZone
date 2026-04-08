import 'package:flutter/material.dart';
import 'package:servizone_app/core/constants/app_constants.dart';
import 'package:servizone_app/core/routes/app_routes.dart';
import 'package:servizone_app/core/locator.dart';
import 'package:servizone_app/data/providers/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _documento = TextEditingController();
  final _celular = TextEditingController();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  bool _showLoadingScreen = false;
  bool _showSuccessScreen = false;
  bool _showErrorScreen = false;
  String _errorMessage = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nombres.dispose();
    _apellidos.dispose();
    _documento.dispose();
    _celular.dispose();
    _correo.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar términos de forma no invasiva
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes aceptar los términos y condiciones'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showLoadingScreen = true;
    });

    final result = await locator<AuthService>().register({
      "nombre": _nombres.text.trim(),
      "apellido": _apellidos.text.trim(),
      "documento": _documento.text.trim(),
      "celular": _celular.text.trim(),
      "correo": _correo.text.trim(),
      "contrasena": _pass.text.trim(),
    });

    if (result['success'] == true) {
      setState(() {
        _showLoadingScreen = false;
        _showSuccessScreen = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      _limpiarFormulario();
    } else {
      String errorMsg = result['message'] ?? 'Error del servidor';
      final lower = errorMsg.toLowerCase();
      if (lower.contains('already') ||
          lower.contains('duplicate') ||
          lower.contains('taken') ||
          lower.contains('registrado') ||
          lower.contains('existe') ||
          lower.contains('en uso')) {
        errorMsg = 'El correo ya se encuentra registrado. Intenta con otro o inicia sesión.';
      }
      _showError(errorMsg);
      setState(() {
        _showLoadingScreen = false;
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _showErrorScreen = true;
      _errorMessage = message;
      _showLoadingScreen = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showErrorScreen = false);
    });
  }

  void _limpiarFormulario() {
    _nombres.clear();
    _apellidos.clear();
    _documento.clear();
    _celular.clear();
    _correo.clear();
    _pass.clear();
    _pass2.clear();
    setState(() => _acceptTerms = false);
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    bool isEmail = false,
    bool isConfirm = false,
    int? minLength,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? (label.contains('Contraseña') && !label.contains('Confirmar') ? _obscure1 : _obscure2) : false,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo requerido';
        if (minLength != null && value.length < minLength) return 'Mínimo $minLength caracteres';
        if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Correo inválido';
        }
        if (isPassword && !isConfirm && !value.startsWith('3')) {
          return 'La contraseña debe comenzar con el número 3';
        }
        if (isConfirm && value != _pass.text) return 'Las contraseñas no coinciden';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        filled: true,
        fillColor: lightGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (label.contains('Contraseña') && !label.contains('Confirmar'))
                      ? (_obscure1 ? Icons.visibility_off : Icons.visibility)
                      : (_obscure2 ? Icons.visibility_off : Icons.visibility),
                  color: textGray,
                ),
                onPressed: () {
                  if (label.contains('Contraseña') && !label.contains('Confirmar')) {
                    setState(() => _obscure1 = !_obscure1);
                  } else if (label.contains('Confirmar')) {
                    setState(() => _obscure2 = !_obscure2);
                  }
                },
              )
            : null,
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return AnimatedOpacity(
      opacity: _showLoadingScreen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: _showLoadingScreen
          ? Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const CircularProgressIndicator(),
                ),
              ),
            )
          : const SizedBox(),
    );
  }

  Widget _buildSuccessScreen() {
    return AnimatedOpacity(
      opacity: _showSuccessScreen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: _showSuccessScreen
          ? Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 60),
                      SizedBox(height: 20),
                      Text(
                        '¡Registro exitoso!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(),
    );
  }

  Widget _buildErrorScreen() {
    return AnimatedOpacity(
      opacity: _showErrorScreen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: _showErrorScreen
          ? Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 60),
                      const SizedBox(height: 20),
                      const Text(
                        'Error',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(_errorMessage, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 254),
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Logo / título
                              const Text(
                                'Crear Cuenta',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: darkGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Regístrate para comenzar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textGray,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Nombres
                              _buildTextField(
                                label: 'Nombres',
                                controller: _nombres,
                              ),
                              const SizedBox(height: 16),

                              // Apellidos
                              _buildTextField(
                                label: 'Apellidos',
                                controller: _apellidos,
                              ),
                              const SizedBox(height: 16),

                              // Documento y Celular (en la misma fila)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Documento',
                                      controller: _documento,
                                      keyboardType: TextInputType.number,
                                      minLength: 8,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Celular',
                                      controller: _celular,
                                      keyboardType: TextInputType.phone,
                                      minLength: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Correo
                              _buildTextField(
                                label: 'Correo',
                                controller: _correo,
                                keyboardType: TextInputType.emailAddress,
                                isEmail: true,
                              ),
                              const SizedBox(height: 16),

                              // Contraseña
                              _buildTextField(
                                label: 'Contraseña',
                                controller: _pass,
                                isPassword: true,
                                minLength: 6,
                              ),
                              const SizedBox(height: 16),

                              // Confirmar Contraseña
                              _buildTextField(
                                label: 'Confirmar Contraseña',
                                controller: _pass2,
                                isPassword: true,
                                isConfirm: true,
                              ),
                              const SizedBox(height: 24),

                              // Términos y condiciones
                              CheckboxListTile(
                                value: _acceptTerms,
                                onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                title: const Text(
                                  'Acepto los términos y condiciones',
                                  style: TextStyle(color: darkGray),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 16),

                              // Botón de registro
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _crearCuenta,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Crear Cuenta',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Enlace a iniciar sesión
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                                },
                                child: RichText(
                                  text: const TextSpan(
                                    text: '¿Ya tienes cuenta? ',
                                    style: TextStyle(
                                      color: textGray,
                                      fontSize: 15,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Inicia sesión',
                                        style: TextStyle(
                                          color: primaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Términos legales
                              const Text(
                                'Al registrarte, aceptas nuestros Términos de servicio y Política de privacidad',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGray,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildLoadingScreen(),
          _buildSuccessScreen(),
          _buildErrorScreen(),
        ],
      ),
    );
  }
}


