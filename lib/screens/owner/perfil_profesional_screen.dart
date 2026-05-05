// lib/screens/owner/perfil_profesional_screen.dart
// Pantalla que muestra el perfil completo de un profesional

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/database_service.dart';
import '../../constants.dart';
import '../../widgets/modern_alert_dialog.dart';

class PerfilProfesionalScreen extends StatefulWidget {
  final String idProfesional;

  const PerfilProfesionalScreen({super.key, required this.idProfesional});

  @override
  State<PerfilProfesionalScreen> createState() =>
      _PerfilProfesionalScreenState();
}

class _PerfilProfesionalScreenState extends State<PerfilProfesionalScreen> {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _perfilCompleto;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfil = await _db.getPerfilProfesionalCompleto(widget.idProfesional);
      setState(() {
        _perfilCompleto = perfil;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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

    // Limpiar número (dejar solo el + y los números)
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
        title: const Text('Perfil Profesional'),
        backgroundColor: kAzulPrincipalOscuro,
        actions: [
          if (_perfilCompleto != null)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () => Navigator.pop(context, widget.idProfesional),
              tooltip: 'Seleccionar este profesional',
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _perfilCompleto == null
              ? const Center(child: Text('No se pudo cargar el perfil'))
              : _buildPerfil(_perfilCompleto!),
    );
  }

  Widget _buildPerfil(Map<String, dynamic> perfil) {
    final String nombre = perfil['full_name'] ?? 'Sin nombre';
    final double valoracion = (perfil['valoracion_promedio'] ?? 0.0).toDouble();
    final int trabajos = perfil['trabajos_completados'] ?? 0;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con foto y valoración
          Container(
            color: kAzulPrincipalOscuro,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: kBlanco,
                  child: Text(
                    nombre.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      color: kAzulPrincipalOscuro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kBlanco,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (perfil['especializacion'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    perfil['especializacion'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: kBlanco,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < valoracion.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: kNaranjaAcento,
                        size: 28,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      valoracion.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 20,
                        color: kBlanco,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$trabajos trabajos completados',
                  style: const TextStyle(color: kBlanco),
                ),
              ],
            ),
          ),

          // Información profesional
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeccionTitulo('Información Profesional'),
                _buildInfoRow('Universidad', perfil['universidad']),
                _buildInfoRow('Título', perfil['titulo_academico']),
                _buildInfoRow('CIP', perfil['cip_numero']),
                _buildInfoRow(
                  'Experiencia',
                  '${perfil['years_experiencia'] ?? 0} años',
                ),
                if (perfil['tarifa_desde'] != null &&
                    perfil['tarifa_hasta'] != null)
                  _buildInfoRow(
                    'Tarifa estimada',
                    'Bs/. ${perfil['tarifa_desde']} - ${perfil['tarifa_hasta']}',
                  ),

                if (perfil['descripcion_profesional'] != null) ...[
                  const SizedBox(height: 16),
                  _buildSeccionTitulo('Sobre mí'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        perfil['descripcion_profesional'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],

                // Certificaciones
                if (perfil['certificaciones'] != null &&
                    (perfil['certificaciones'] as List).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSeccionTitulo('Certificaciones'),
                  ...((perfil['certificaciones'] as List).map((cert) {
                    return Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.verified, color: kVerdeExito),
                        title: Text(cert.toString()),
                      ),
                    );
                  }).toList()),
                ],

                // Últimas valoraciones
                if (perfil['ultimas_valoraciones'] != null &&
                    (perfil['ultimas_valoraciones'] as List).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSeccionTitulo('Últimas Valoraciones'),
                  ...((perfil['ultimas_valoraciones'] as List).map((val) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < (val['calificacion'] ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: kNaranjaAcento,
                                    size: 16,
                                  );
                                }),
                              ],
                            ),
                            if (val['comentario'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                val['comentario'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList()),
                ],

                const SizedBox(height: 32),
                
                // Botón de WhatsApp
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _contactarWhatsApp(perfil['phone']),
                    icon: const Icon(Icons.chat),
                    label: const Text('Contactar por WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // Color oficial de WhatsApp
                      foregroundColor: kBlanco,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 80), // Espacio para el botón flotante
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.toString() == 'null') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kGrisMedio,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
