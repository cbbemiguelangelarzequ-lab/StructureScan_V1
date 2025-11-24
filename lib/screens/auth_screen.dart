// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:structurescan_app/constants.dart';
import 'package:intl/intl.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  String? _selectedUserType;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? kRojoAdvertencia : kAzulPrincipalOscuro,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        !_emailController.text.contains('@')) {
      _showMessage('Por favor, completa todos los campos y usa un email válido.', isError: true);
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

        _showMessage('Registro exitoso. ¡Bienvenido, ${res.user!.email}!', isError: false);
        await _navigateToDashboard();
      } else {
        _showMessage('Registro exitoso. Por favor, verifica tu correo electrónico para confirmar tu cuenta.', isError: false);
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
        _showMessage('Inicio de sesión exitoso. ¡Bienvenido de nuevo, ${res.user!.email}!', isError: false);
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
      backgroundColor: kGrisClaro,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'StructureScan',
                  style: kTituloPantallaStyle.copyWith(
                    fontSize: 32,
                    color: kAzulPrincipalOscuro,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Inicia Sesión' : 'Crea tu Cuenta',
                  style: kBodyTextStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 40),
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          TextField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre Completo',
                              prefixIcon: const Icon(Icons.person, color: kAzulSecundarioClaro),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: const Icon(Icons.email, color: kAzulSecundarioClaro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock, color: kAzulSecundarioClaro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          obscureText: true,
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 15),
                          TextField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirmar Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline, color: kAzulSecundarioClaro),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Tipo de Usuario',
                              prefixIcon: const Icon(Icons.person_outline, color: kAzulSecundarioClaro),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                            hint: Text(
                              'Selecciona tu tipo de usuario',
                              style: kBodyTextStyle.copyWith(color: kGrisMedio),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _isLoading
                            ? const CircularProgressIndicator(color: kAzulPrincipalOscuro)
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLogin ? _signIn : _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kAzulPrincipalOscuro,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _isLogin ? 'INICIAR SESIÓN' : 'REGISTRARSE',
                                    style: kButtonTextStyle,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 10),
                        if (_isLogin)
                          TextButton(
                            onPressed: () {
                              _showMessage(
                                'Funcionalidad de "Olvidaste tu contraseña" pendiente de implementar.',
                                isError: false,
                              );
                            },
                            child: Text('¿Olvidaste tu contraseña?', style: kLinkTextStyle),
                          ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _emailController.clear();
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                              _fullNameController.clear();
                              _selectedUserType = null;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? '¿No tienes una cuenta? Regístrate'
                                : '¿Ya tienes una cuenta? Iniciar Sesión',
                            style: kLinkTextStyle,
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
    );
  }
}