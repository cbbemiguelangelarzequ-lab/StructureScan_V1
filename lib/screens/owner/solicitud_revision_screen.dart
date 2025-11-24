// lib/screens/owner/solicitud_revision_screen.dart
// Pantalla de resumen final y envío de solicitud de revisión

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/edificacion.dart';
import '../../models/sintoma_inspeccion.dart';
import '../../models/anamnesis.dart';
import '../../models/solicitud_revision.dart';
import '../../services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SolicitudRevisionScreen extends StatefulWidget {
  final String edificacionId;

  const SolicitudRevisionScreen({super.key, required this.edificacionId});

  @override
  State<SolicitudRevisionScreen> createState() =>
      _SolicitudRevisionScreenState();
}

class _SolicitudRevisionScreenState extends State<SolicitudRevisionScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = true;
  bool _isSubmitting = false;

  Edificacion? _edificacion;
  List<SintomaInspeccion> _sintomas = [];
  Anamnesis? _anamnesis;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final data = await _dbService.getEdificacionCompleta(widget.edificacionId);

      setState(() {
        _edificacion = Edificacion.fromJson(data['edificacion']);
        _sintomas = (data['sintomas'] as List)
            .map((s) => SintomaInspeccion.fromJson(s))
            .toList();
        if (data['anamnesis'] != null) {
          _anamnesis = Anamnesis.fromJson(data['anamnesis']);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kRojoAdvertencia),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _enviarSolicitud() async {
    setState(() => _isSubmitting = true);
    try {
      // Generar descripción breve
      String sintomaPrincipal = _sintomas.isNotEmpty
          ? _sintomas.first.tipoSintoma.displayName
          : 'Daño estructural';

      String descripcionBreve = 'Edificación de ${_edificacion!.tipoMaterial.displayName}, ';
      descripcionBreve += 'suelo ${_edificacion!.tipoSuelo.displayName}. ';
      descripcionBreve += 'Síntoma: $sintomaPrincipal. ';

      if (_anamnesis != null) {
        descripcionBreve += 'Descubierto hace ${_anamnesis!.cuandoDescubrio.displayName.toLowerCase()}, ';
        descripcionBreve += 'comportamiento: ${_anamnesis!.comportamiento.displayName.toLowerCase()}.';
      }

      final solicitud = SolicitudRevision(
        idEdificacion: widget.edificacionId,
        idPropietario: Supabase.instance.client.auth.currentUser!.id,
        sintomaPrincipal: sintomaPrincipal,
        descripcionBreve: descripcionBreve,
        nivelRiesgo: _edificacion!.riesgoCalculado ?? NivelRiesgo.medio,
      );

      await _dbService.crearSolicitudRevision(solicitud.toJson());

      if (mounted) {
        // Mostrar diálogo de confirmación
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: kVerdeExito, size: 32),
                SizedBox(width: 12),
                Text('Solicitud Enviada'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Su solicitud de revisión ha sido enviada exitosamente a los profesionales.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  '⏱️ Tiempo estimado de respuesta: 24-48 horas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Recibirá una notificación cuando un ingeniero revise su caso.',
                  style: TextStyle(fontSize: 14, color: kGrisOscuro),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver al dashboard
                  Navigator.of(context).pop(); // Volver al dashboard
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kRojoAdvertencia),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Solicitud'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildEdificacionCard(),
                  const SizedBox(height: 16),
                  _buildSintomasCard(),
                  const SizedBox(height: 16),
                  _buildAnamnesisCard(),
                  const SizedBox(height: 16),
                  _buildRiesgoCard(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _enviarSolicitud,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAzulSecundarioClaro,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: kBlanco)
                          : const Text(
                              'Enviar Solicitud a Profesional',
                              style: TextStyle(fontSize: 18, color: kBlanco),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return const Card(
      color: Color(0xFFD1ECF1),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: kAzulSecundarioClaro, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Revise la información antes de enviar. Un ingeniero estructural recibirá todos estos datos.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEdificacionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil de la Edificación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Nombre', _edificacion!.nombreEdificacion),
            _buildInfoRow('Material', _edificacion!.tipoMaterial.displayName),
            _buildInfoRow('Techo', _edificacion!.tipoTecho.displayName),
            _buildInfoRow('Forma', _edificacion!.formaGeometrica.displayName),
            _buildInfoRow('Suelo', _edificacion!.tipoSuelo.displayName),
            _buildInfoRow('Construcción', _edificacion!.tipoConstruccion.displayName),
            if (_edificacion!.haTenidoModificaciones)
              _buildInfoRow('Modificaciones',
                  _edificacion!.descripcionModificaciones ?? 'Sí'),
          ],
        ),
      ),
    );
  }

  Widget _buildSintomasCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Síntomas Reportados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ..._sintomas.map((sintoma) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            sintoma.tipoSintoma.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sintoma.tipoSintoma.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Ubicación: ${sintoma.ubicacion.displayName}'),
                      if (sintoma.direccionGrieta != null)
                        Text(
                          'Dirección: ${sintoma.direccionGrieta!.displayName}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      if (sintoma.espesorGrieta != null)
                        Text('Espesor: ${sintoma.espesorGrieta!.displayName}'),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAnamnesisCard() {
    if (_anamnesis == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historia del Daño',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Descubierto', _anamnesis!.cuandoDescubrio.displayName),
            _buildInfoRow('Comportamiento', _anamnesis!.comportamiento.displayName),
            if (_anamnesis!.factoresDetonantes.isNotEmpty)
              _buildInfoRow(
                  'Factores',
                  _anamnesis!.factoresDetonantes
                      .map((f) => f.displayName)
                      .join(', ')),
            if (_anamnesis!.tieneRuidos)
              _buildInfoRow('Ruidos', _anamnesis!.descripcionRuidos ?? 'Sí'),
            if (_anamnesis!.tieneVibraciones)
              _buildInfoRow('Vibraciones',
                  _anamnesis!.descripcionVibraciones ?? 'Sí'),
          ],
        ),
      ),
    );
  }

  Widget _buildRiesgoCard() {
    final riesgo = _edificacion!.riesgoCalculado ?? NivelRiesgo.medio;
    Color riesgoColor;
    switch (riesgo) {
      case NivelRiesgo.alto:
        riesgoColor = kRojoAdvertencia;
        break;
      case NivelRiesgo.medio:
        riesgoColor = kNaranjaAcento;
        break;
      case NivelRiesgo.bajo:
        riesgoColor = kVerdeExito;
        break;
    }

    return Card(
      color: riesgoColor.withOpacity(0.1),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(
              riesgo.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nivel de Riesgo Calculado',
                    style: TextStyle(fontSize: 14, color: kGrisOscuro),
                  ),
                  Text(
                    riesgo.displayName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: riesgoColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
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
