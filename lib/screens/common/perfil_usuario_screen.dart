// lib/screens/common/perfil_usuario_screen.dart
// Pantalla de perfil de usuario para propietarios y profesionales

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants.dart';
import '../../services/database_service.dart';
import '../../services/image_processing_service.dart';
import '../../widgets/modern_alert_dialog.dart';
import '../../services/localization_service.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final DatabaseService _db = DatabaseService();
  final ImageProcessingService _imageService = ImageProcessingService();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _perfil;
  bool _cargando = true;
  bool _subiendoFoto = false;
  String _rol = '';

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final perfil = await _db.getPerfil(user.id);

      setState(() {
        _perfil = perfil;
        _rol = perfil?['rol'] ?? '';
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _cambiarFotoPerfil() async {
    try {
      // Seleccionar imagen
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _subiendoFoto = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Subir foto
      final fotoUrl = await _imageService.subirFotoPerfil(
        imagen: File(image.path),
        userId: user.id,
      );

      // Actualizar perfil en DB
      await _db.actualizarPerfil(user.id, {'foto_perfil_url': fotoUrl});

      // Recargar perfil
      await _cargarPerfil();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto de perfil actualizada'),
            backgroundColor: kVerdeExito,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar foto: $e'),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
    } finally {
      setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kRojoAdvertencia),
            child: const Text('Cerrar Sesión',
                style: TextStyle(color: kBlanco)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('profile_title')),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header con foto y nombre
                  Container(
                    color: kAzulPrincipalOscuro,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: kBlanco,
                              backgroundImage: _perfil?['foto_perfil_url'] != null
                                  ? NetworkImage(_perfil!['foto_perfil_url'])
                                  : null,
                              child: _perfil?['foto_perfil_url'] == null
                                  ? Text(
                                      (_perfil?['full_name'] ?? 'U')
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        color: kAzulPrincipalOscuro,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            if (_subiendoFoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(kBlanco),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _subiendoFoto ? null : _cambiarFotoPerfil,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: kVerdeExito,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: kBlanco, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: kBlanco,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _perfil?['full_name'] ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kBlanco,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: kBlanco,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_perfil?['especializacion'] != null)
                          Text(
                            _perfil!['especializacion'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: kBlanco,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Información Personal
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSeccionTitulo(LocalizationService().translate('personal_info')),
                        _buildInfoCard([
                          _buildInfoRow(
                              Icons.person, LocalizationService().translate('role'), _getRolTexto(_rol)),
                          if (_perfil?['phone'] != null)
                            _buildInfoRow(
                                Icons.phone, LocalizationService().translate('phone'), _perfil!['phone']),
                          if (_perfil?['ubicacion'] != null)
                            _buildInfoRow(Icons.location_on, LocalizationService().translate('location'),
                                _perfil!['ubicacion']),
                          if (_perfil?['organizacion'] != null)
                            _buildInfoRow(Icons.business, LocalizationService().translate('organization'),
                                _perfil!['organizacion']),
                        ]),

                        const SizedBox(height: 24),

                        // Botón Editar Perfil Profesional (solo para profesionales)
                        if (_rol == 'profesional') ...[
                          _buildSeccionTitulo(LocalizationService().translate('professional_profile')),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.edit,
                                  color: kAzulPrincipalOscuro),
                              title: Text(LocalizationService().translate('edit_professional_profile')),
                              subtitle: Text(
                                  LocalizationService().translate('update_professional_info')),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                final resultado = await Navigator.pushNamed(
                                  context,
                                  '/editar_perfil_profesional',
                                );
                                if (resultado == true) {
                                  _cargarPerfil(); // Recargar perfil
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Ajustes de la Aplicación
                        _buildSeccionTitulo(LocalizationService().translate('settings_title')),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.notifications,
                                    color: kAzulPrincipalOscuro),
                                title: Text(LocalizationService().translate('notifications')),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.pushNamed(context, '/settings/notificaciones');
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.security,
                                    color: kAzulPrincipalOscuro),
                                title: Text(LocalizationService().translate('security')),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.pushNamed(context, '/settings/seguridad');
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.language,
                                    color: kAzulPrincipalOscuro),
                                title: Text(LocalizationService().translate('language')),
                                subtitle: Text(LocalizationService().currentLocale.languageCode.toUpperCase()),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: _mostrarSelectorIdioma,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Acciones
                        _buildSeccionTitulo(LocalizationService().translate('actions')),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.logout,
                                    color: kRojoAdvertencia),
                                title: Text(LocalizationService().translate('logout')),
                                onTap: _cerrarSesion,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kAzulPrincipalOscuro,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kGrisMedio),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kGrisMedio,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorIdioma() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocalizationService().translate('select_language'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kAzulPrincipalOscuro,
              ),
            ),
            const SizedBox(height: 20),
            _buildIdiomaOption('Español', 'es'),
            _buildIdiomaOption('English', 'en'),
            _buildIdiomaOption('Português', 'pt'),
          ],
        ),
      ),
    );
  }

  Widget _buildIdiomaOption(String idioma, String code) {
    bool seleccionado = LocalizationService().currentLocale.languageCode == code;
    return ListTile(
      title: Text(idioma),
      trailing: seleccionado
          ? const Icon(Icons.check_circle, color: kVerdeExito)
          : null,
      onTap: () {
        Navigator.pop(context);
        if (!seleccionado) {
          LocalizationService().changeLocale(code);
          ModernAlertDialog.showToast(
            context,
            message: '${LocalizationService().translate('language_changed')} $idioma',
            type: AlertType.success,
          );
        }
      },
    );
  }

  String _getRolTexto(String rol) {
    switch (rol) {
      case 'propietario':
        return LocalizationService().translate('owner');
      case 'profesional':
        return LocalizationService().translate('professional');
      default:
        return LocalizationService().translate('user');
    }
  }
}
