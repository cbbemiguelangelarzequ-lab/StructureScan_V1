// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:structurescan_app/constants.dart';
import 'package:structurescan_app/widgets/modern_alert_dialog.dart';
import 'package:intl/intl.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  String? _selectedUserType;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  final supabase = Supabase.instance.client;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ModernAlertDialog.showToast(
      context,
      message: message,
      type: isError ? AlertType.error : AlertType.success,
    );
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        !_emailController.text.contains('@')) {
      _showMessage('Por favor, completa todos los campos correctamente', isError: true);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Las contraseñas no coinciden.', isError: true);
      return;
    }
    if (_selectedUserType == null) {
      _showMessage('Por favor, selecciona tu tipo de usuario.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _fullNameController.text.trim(),
          'user_type': _selectedUserType,
        },
      );

      if (res.user != null) {
        final String formattedDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(DateTime.now().toUtc());

        await supabase.from('perfiles').insert({
          'id_usuario': res.user!.id,
          'full_name': _fullNameController.text.trim(),
          'rol': _selectedUserType,
          'created_at': formattedDate,
        });

        _showMessage('Registro exitoso. ¡Bienvenido!', isError: false);
        await _navigateToDashboard();
      } else {
        _showMessage('Registro exitoso. Por favor, verifica tu correo electrónico.', isError: false);
      }
    } on AuthException catch (e) {
      _showMessage('Error de registro: ${e.message}', isError: true);
    } catch (e) {
      _showMessage('Ocurrió un error inesperado durante el registro: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Por favor, introduce tu correo y contraseña.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        _showMessage('Inicio de sesión exitoso. ¡Bienvenido de nuevo!', isError: false);
        await _navigateToDashboard();
      } else {
        _showMessage('Credenciales inválidas. Por favor, verifica tu email y contraseña.', isError: true);
      }
    } on AuthException catch (e) {
      _showMessage('Error al iniciar sesión: ${e.message}', isError: true);
    } catch (e) {
      _showMessage('Ocurrió un error inesperado al iniciar sesión: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToDashboard() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('perfiles')
          .select('rol')
          .eq('id_usuario', user.id)
          .single();

      final rol = response['rol'] as String?;

      if (mounted) {
        if (rol == 'profesional') {
          Navigator.of(context).pushReplacementNamed('/dashboard_profesional');
        } else {
          Navigator.of(context).pushReplacementNamed('/dashboard_propietario');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard_propietario');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kAzulPrincipalOscuro,
              kAzulSecundarioClaro.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Hero(
                      tag: 'logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kBlanco.withOpacity(0.15),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/structurescan_logo.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Título
                    Text(
                      'StructureScan',
                      style: kTituloPrincipalStyle.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: kBlanco,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Bienvenido de Nuevo' : 'Crea tu Cuenta',
                      style: kBodyTextStyle.copyWith(
                        fontSize: 16,
                        color: kBlanco.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Tarjeta flotante
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        color: kBlanco,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            // Título de la tarjeta
                            Text(
                              _isLogin ? 'Iniciar Sesión' : 'Información Personal',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: kAzulPrincipalOscuro,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin 
                                  ? 'Ingresa tus credenciales para continuar' 
                                  : 'Completa tus datos para comenzar',
                              style: const TextStyle(
                                fontSize: 14,
                                color: kGrisMedio,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),

                            // Campos de formulario
                            if (!_isLogin) ...[
                              _buildTextField(
                                controller: _fullNameController,
                                label: 'Nombre Completo',
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            _buildTextField(
                              controller: _emailController,
                              label: 'Correo Electrónico',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              icon: Icons.lock,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: kGrisMedio,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            
                            if (!_isLogin) ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirmar Contraseña',
                                icon: Icons.lock_outline,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                    color: kGrisMedio,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Dropdown tipo de usuario
                              Container(
                                decoration: BoxDecoration(
                                  color: kGrisClaro,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Tipo de Usuario',
                                    prefixIcon: const Icon(Icons.person_outline, color: kAzulSecundarioClaro),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: kGrisClaro,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'propietario', child: Text('Propietario')),
                                    DropdownMenuItem(value: 'profesional', child: Text('Ingeniero/Arquitecto')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUserType = value;
                                    });
                                  },
                                  value: _selectedUserType,
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 24),

                            // Botón principal
                            _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(kAzulSecundarioClaro),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLogin ? _signIn : _signUp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kNaranjaAcento,
                                        foregroundColor: kBlanco,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 5,
                                        shadowColor: kNaranjaAcento.withOpacity(0.5),
                                      ),
                                      child: Text(
                                        _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                            // Olvidaste contraseña (solo en login)
                            if (_isLogin) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/forgot_password');
                                },
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    color: kAzulSecundarioClaro,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],

                            // Cambiar entre login y registro
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  _fullNameController.clear();
                                  _selectedUserType = null;
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                              child: Text(
                                _isLogin
                                    ? '¿No tienes cuenta? Regístrate aquí'
                                    : '¿Ya tienes cuenta? Inicia Sesión',
                                style: const TextStyle(
                                  color: kGrisOscuro,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kGrisClaro,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kAzulSecundarioClaro),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: kGrisClaro,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
