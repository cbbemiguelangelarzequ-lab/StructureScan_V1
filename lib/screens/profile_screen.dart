// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:structurescan_app/constants.dart';
import 'package:structurescan_app/widgets/modern_alert_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _perfil;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No hay sesión activa');

      final perfil = await _supabase
          .from('perfiles')
          .select()
          .eq('id_usuario', user.id)
          .single();

      setState(() {
        _perfil = perfil;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: 'Error al cargar perfil: $e',
          type: AlertType.error,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _mostrarDialogoEditarTelefono() async {
    final TextEditingController phoneController = TextEditingController(
      text: _perfil?['phone'] ?? '',
    );
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Teléfono'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu número de teléfono (con código de país, ej. +591...) para que puedan contactarte por WhatsApp.',
                    style: TextStyle(fontSize: 14, color: kGrisOscuro),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Número de WhatsApp',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setStateDialog(() => isSaving = true);
                          try {
                            final user = _supabase.auth.currentUser;
                            final phone = phoneController.text.trim();
                            await _supabase
                                .from('perfiles')
                                .update({'phone': phone})
                                .eq('id_usuario', user!.id);
                            
                            if (mounted) {
                              Navigator.pop(context);
                              _cargarPerfil(); // Recargar datos
                              ModernAlertDialog.showToast(
                                context,
                                message: 'Teléfono actualizado correctamente',
                                type: AlertType.success,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ModernAlertDialog.showToast(
                                context,
                                message: 'Error al guardar: $e',
                                type: AlertType.error,
                              );
                            }
                            setStateDialog(() => isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: kNaranjaAcento),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: kBlanco, strokeWidth: 2),
                        )
                      : const Text('Guardar', style: TextStyle(color: kBlanco)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: kAzulPrincipalOscuro,
          title: const Text('Perfil de Usuario', style: TextStyle(color: kBlanco)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final nombreCompleto = _perfil?['full_name'] ?? 'Usuario';
    final rol = _perfil?['rol'] == 'profesional' ? 'Ingeniero/Arquitecto' : 'Propietario';
    final email = _supabase.auth.currentUser?.email ?? '';
    final telefono = _perfil?['phone'] ?? 'No registrado';

    return Scaffold(
      backgroundColor: kGrisClaro,
      appBar: AppBar(
        backgroundColor: kAzulPrincipalOscuro,
        title: Text('Perfil de Usuario', style: kTituloPrincipalStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlanco),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: kAzulSecundarioClaro,
                    child: Text(
                      nombreCompleto.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 48, color: kBlanco, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    nombreCompleto,
                    style: kTituloPantallaStyle.copyWith(fontSize: 24, color: kAzulPrincipalOscuro),
                  ),
                  Text(
                    email,
                    style: kBodyTextStyle.copyWith(color: kGrisOscuro),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    rol,
                    style: kMiniaturaTextStyle.copyWith(fontStyle: FontStyle.italic, color: kAzulSecundarioClaro, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 40, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Información Personal',
                  style: kTituloPantallaStyle.copyWith(fontSize: 18, color: kAzulPrincipalOscuro),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: kAzulSecundarioClaro),
                  tooltip: 'Editar información',
                  onPressed: _mostrarDialogoEditarTelefono,
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildInfoRow(Icons.phone, 'Teléfono (WhatsApp)', telefono, onTap: _mostrarDialogoEditarTelefono),
            
            // Más campos si los hubiera en Supabase
            if (_perfil?['especializacion'] != null)
              _buildInfoRow(Icons.work, 'Especialización', _perfil!['especializacion']),
            if (_perfil?['cip_numero'] != null)
              _buildInfoRow(Icons.badge, 'CIP', _perfil!['cip_numero']),

            const SizedBox(height: 30),
            Text(
              'Ajustes de la Aplicación',
              style: kTituloPantallaStyle.copyWith(fontSize: 18, color: kAzulPrincipalOscuro),
            ),
            const SizedBox(height: 15),
            ListTile(
              leading: Icon(Icons.notifications_active, color: kAzulSecundarioClaro),
              title: Text('Notificaciones', style: kBodyTextStyle),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: kGrisMedio),
              onTap: () {
                Navigator.of(context).pushNamed('/notificaciones');
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _supabase.auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (Route<dynamic> route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRojoAdvertencia,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.logout, color: kBlanco),
                label: Text('Cerrar Sesión', style: kButtonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, color: kAzulSecundarioClaro, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: kMiniaturaTextStyle.copyWith(color: kGrisOscuro),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: kBodyTextStyle.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.edit, size: 16, color: kGrisMedio),
          ],
        ),
      ),
    );
  }
}