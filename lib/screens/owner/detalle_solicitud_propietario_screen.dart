// lib/screens/owner/detalle_solicitud_propietario_screen.dart
// Pantalla para ver el detalle de una solicitud como propietario

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../widgets/modern_alert_dialog.dart';
import '../../models/solicitud_revision.dart';
import '../../models/informe_tecnico.dart';
import '../../services/database_service.dart';

class DetalleSolicitudPropietarioScreen extends StatefulWidget {
  final String solicitudId;

  const DetalleSolicitudPropietarioScreen({
    super.key,
    required this.solicitudId,
  });

  @override
  State<DetalleSolicitudPropietarioScreen> createState() =>
      _DetalleSolicitudPropietarioScreenState();
}

class _DetalleSolicitudPropietarioScreenState
    extends State<DetalleSolicitudPropietarioScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = true;

  Map<String, dynamic>? _solicitudData;
  Map<String, dynamic>? _profesionalPerfil;
  InformeTecnico? _informe;
  bool _yaCalificado = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // Cargar solicitud
      final solicitudConEdif = await _dbService.getSolicitudConEdificacion(
        widget.solicitudId,
      );

      // Cargar informe si existe
      final informeData = await _dbService.getInformePorSolicitud(
        widget.solicitudId,
      );

      InformeTecnico? informe;
      if (informeData != null) {
        informe = InformeTecnico.fromJson(informeData);
      }

      // Verificar si ya fue calificado
      final yaCalificado = await _dbService.existeValoracion(
        widget.solicitudId,
      );

      // Obtener el ID del profesional asignado desde la solicitud (puede ser nulo)
      final idProfesional = solicitudConEdif['id_profesional'];
      Map<String, dynamic>? perfilProf;
      
      if (idProfesional != null) {
        perfilProf = await _dbService.getPerfil(idProfesional);
      }

      setState(() {
        _solicitudData = solicitudConEdif;
        _profesionalPerfil = perfilProf;
        _informe = informe;
        _yaCalificado = yaCalificado;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calificarProfesional() async {
    if (_solicitudData == null) return;

    final solicitud = SolicitudRevision.fromJson(_solicitudData!);
    
    final resultado = await Navigator.pushNamed(
      context,
      '/valorar_profesional',
      arguments: {
        'idSolicitud': solicitud.id,
        'idProfesional': solicitud.idProfesional,
        'nombreProfesional': 'el profesional',
      },
    );

    if (resultado == true) {
      _cargarDatos(); // Recargar para actualizar estado
    }
  }

  Future<void> _contactarWhatsApp(String? telefono) async {
    if (telefono == null || telefono.trim().isEmpty) {
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: 'El profesional no tiene un número de teléfono registrado',
          type: AlertType.error,
        );
      }
      return;
    }

    final numeroLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('https://wa.me/$numeroLimpio');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se pudo abrir WhatsApp');
      }
    } catch (e) {
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: 'No se pudo abrir WhatsApp. Verifica si está instalado.',
          type: AlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEstadoSolicitud(),
                  const SizedBox(height: 24),
                  
                  if (_profesionalPerfil != null) ...[ 
                    _buildContactoProfesional(),
                    const SizedBox(height: 24),
                  ],

                  if (_informe != null) ...[ 
                    _buildInformeCard(),
                    const SizedBox(height: 24),
                  ] else ...[
                    _buildSinInforme(),
                    const SizedBox(height: 24),
                  ],

                  // Botón de calificar
                  if (_informe != null && !_yaCalificado)
                    _buildCalificarButton(),
                  
                  if (_yaCalificado)
                    _buildYaCalificado(),
                ],
              ),
            ),
    );
  }

  Widget _buildEstadoSolicitud() {
    if (_solicitudData == null) return const SizedBox.shrink();

    final solicitud = SolicitudRevision.fromJson(_solicitudData!);
    final edificacion = _solicitudData!['edificaciones'];

    Color estadoColor;
    IconData estadoIcon;
    switch (solicitud.estado) {
      case EstadoSolicitud.pendiente:
        estadoColor = kGrisMedio;
        estadoIcon = Icons.hourglass_empty;
        break;
      case EstadoSolicitud.enRevision:
        estadoColor = kAzulSecundarioClaro;
        estadoIcon = Icons.search;
        break;
      case EstadoSolicitud.programada:
        estadoColor = kNaranjaAcento;
        estadoIcon = Icons.event;
        break;
      case EstadoSolicitud.completada:
        estadoColor = kVerdeExito;
        estadoIcon = Icons.check_circle;
        break;
      case EstadoSolicitud.descartada:
      case EstadoSolicitud.rechazada:
        estadoColor = kRojoAdvertencia;
        estadoIcon = Icons.cancel;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  solicitud.nivelRiesgo.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    edificacion['nombre_edificacion'] ?? 'Edificación',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('📋 Síntoma Principal', solicitud.sintomaPrincipal),
            _buildInfoRow('📍 Dirección', edificacion['direccion'] ?? 'No especificada'),
            _buildInfoRow('⚠️ Nivel de Riesgo', solicitud.nivelRiesgo.displayName),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(estadoIcon, size: 18, color: estadoColor),
              label: Text(
                'Estado: ${solicitud.estado.displayName}',
                style: const TextStyle(fontSize: 14),
              ),
              backgroundColor: estadoColor.withOpacity(0.1),
              side: BorderSide(color: estadoColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformeCard() {
    if (_informe == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description, color: kAzulPrincipalOscuro, size: 28),
                SizedBox(width: 8),
                Text(
                  'INFORME TÉCNICO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kAzulPrincipalOscuro,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Vista previa del informe (scroll limitado)
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                border: Border.all(color: kGrisClaro),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Markdown(
                  data: _informe!.contenidoMarkdown,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Conclusión final destacada
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _informe!.esHabitable
                    ? kVerdeExito.withOpacity(0.1)
                    : kRojoAdvertencia.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _informe!.esHabitable ? kVerdeExito : kRojoAdvertencia,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _informe!.esHabitable ? Icons.home : Icons.warning,
                        color: _informe!.esHabitable ? kVerdeExito : kRojoAdvertencia,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _informe!.esHabitable
                            ? 'Estructura HABITABLE'
                            : 'Estructura NO HABITABLE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _informe!.esHabitable ? kVerdeExito : kRojoAdvertencia,
                        ),
                      ),
                    ],
                  ),
                  if (_informe!.requiereRefuerzo) ...[ 
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.construction, color: kNaranjaAcento, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Requiere refuerzo estructural',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: kNaranjaAcento,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Conclusión del Ingeniero:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_informe!.conclusionFinal),
                  if (_informe!.firmaProfesional != null) ...[ 
                    const SizedBox(height: 12),
                    Text(
                      '— ${_informe!.firmaProfesional}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: kGrisOscuro,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinInforme() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: kGrisMedio.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Informe técnico aún no disponible',
              style: TextStyle(
                fontSize: 16,
                color: kGrisMedio,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El profesional aún no ha completado el informe técnico.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kGrisMedio,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactoProfesional() {
    final nombre = _profesionalPerfil!['full_name'] ?? 'Profesional asignado';
    final telefono = _profesionalPerfil!['phone'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: kAzulPrincipalOscuro, size: 24),
                SizedBox(width: 8),
                Text(
                  'Profesional Asignado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kAzulPrincipalOscuro,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              nombre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _contactarWhatsApp(telefono),
                icon: const Icon(Icons.chat),
                label: const Text('Contactar por WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: kBlanco,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalificarButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _calificarProfesional,
        icon: const Icon(Icons.star_rate),
        label: const Text('Calificar Profesional'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kNaranjaAcento,
          foregroundColor: kBlanco,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildYaCalificado() {
    return Card(
      color: kVerdeExito.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: kVerdeExito, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: const Text(
                '¡Gracias! Ya calificaste este servicio',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kVerdeExito,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
