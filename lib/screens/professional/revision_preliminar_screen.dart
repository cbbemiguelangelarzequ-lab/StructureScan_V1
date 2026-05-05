// lib/screens/professional/revision_preliminar_screen.dart
// Pantalla de revisión preliminar - FASE A del flujo profesional

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/solicitud_revision.dart';
import '../../models/edificacion.dart';
import '../../services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RevisionPreliminarScreen extends StatefulWidget {
  final String solicitudId;

  const RevisionPreliminarScreen({
    super.key,
    required this.solicitudId,
  });

  @override
  State<RevisionPreliminarScreen> createState() =>
      _RevisionPreliminarScreenState();
}

class _RevisionPreliminarScreenState extends State<RevisionPreliminarScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = true;
  
  Map<String, dynamic>? _solicitudData;
  Map<String, dynamic>? _edificacionData;
  List<Map<String, dynamic>> _sintomas = [];
  
  final _respuestaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _respuestaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // Obtener solicitud con edificación relacionada
      final solicitudConEdif = await _dbService.getSolicitudConEdificacion(
        widget.solicitudId,
      );

      // Obtener síntomas de la edificación
      final idEdificacion = solicitudConEdif['id_edificacion'] as String;
      final sintomas = await _dbService.getSintomasByEdificacionId(
        idEdificacion,
      );

      setState(() {
        _solicitudData = solicitudConEdif;
        _edificacionData = solicitudConEdif['edificaciones'];
        _sintomas = sintomas;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _descartarConConsejo() async {
    if (_respuestaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, escribe un consejo para el propietario'),
          backgroundColor: kNaranjaAcento,
        ),
      );
      return;
    }

    try {
      await _dbService.actualizarSolicitudRevision(
        widget.solicitudId,
        {
          'estado': 'descartada',
          'nota_profesional': _respuestaController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Solicitud rechazada con consejo enviado'),
            backgroundColor: kVerdeExito,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
    }
  }

  Future<void> _agendarVisitaTecnica() async {
    try {
      await _dbService.updateSolicitudEstado(
        widget.solicitudId,
        'programada',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Visita técnica programada'),
            backgroundColor: kVerdeExito,
          ),
        );
        
        // Navegar a la pantalla de inspección técnica
        Navigator.of(context).pushReplacementNamed(
          '/inspeccion_tecnica',
          arguments: widget.solicitudId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
    }
  }

  // Obtener cita programada para esta solicitud
  Future<Map<String, dynamic>?> _obtenerCitaProgramada() async {
    try {
      final response = await Supabase.instance.client
          .from('citas_tecnicas')
          .select()
          .eq('id_solicitud', widget.solicitudId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error al obtener cita: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión Preliminar'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRiesgoHeader(),
                  _buildExpedienteClinico(),
                  _buildSintomas(),
                  _buildAcciones(),
                ],
              ),
            ),
    );
  }

  Widget _buildRiesgoHeader() {
    if (_solicitudData == null) return const SizedBox.shrink();
    
    final solicitud = SolicitudRevision.fromJson(_solicitudData!);
    
    Color riesgoColor;
    IconData riesgoIcon;
    switch (solicitud.nivelRiesgo) {
      case NivelRiesgo.alto:
        riesgoColor = kRojoAdvertencia;
        riesgoIcon = Icons.warning;
        break;
      case NivelRiesgo.medio:
        riesgoColor = kNaranjaAcento;
        riesgoIcon = Icons.info;
        break;
      case NivelRiesgo.bajo:
        riesgoColor = kVerdeExito;
        riesgoIcon = Icons.check_circle;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: riesgoColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: riesgoColor, width: 3),
        ),
      ),
      child: Column(
        children: [
          Icon(riesgoIcon, color: riesgoColor, size: 48),
          const SizedBox(height: 8),
          Text(
            'RIESGO ${solicitud.nivelRiesgo.displayName.toUpperCase()}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: riesgoColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            solicitud.sintomaPrincipal,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpedienteClinico() {
    if (_edificacionData == null) return const SizedBox.shrink();
    
    final edificacion = Edificacion.fromJson(_edificacionData!);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBlanco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.folder_open, color: kAzulPrincipalOscuro),
              SizedBox(width: 8),
              Text(
                'EXPEDIENTE CLÍNICO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kAzulPrincipalOscuro,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Edificación', edificacion.nombreEdificacion),
          if (edificacion.direccion != null)
            _buildInfoRow('Dirección', edificacion.direccion!),
          _buildInfoRow(
            'Material',
            '${edificacion.tipoMaterial.displayName}\n${edificacion.tipoMaterial.description}',
          ),
          _buildInfoRow('Techo', edificacion.tipoTecho.displayName),
          _buildInfoRow(
            'Geometría',
            '${edificacion.formaGeometrica.displayName}\n${edificacion.formaGeometrica.description}',
          ),
          _buildInfoRow(
            'Suelo',
            '${edificacion.tipoSuelo.displayName}\n${edificacion.tipoSuelo.description}',
          ),
          _buildInfoRow(
            'Construcción',
            edificacion.tipoConstruccion.displayName,
          ),
          _buildInfoRow(
            'Modificaciones',
            edificacion.haTenidoModificaciones
                ? 'Sí - ${edificacion.descripcionModificaciones ?? "Sin detalles"}'
                : 'No',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kGrisOscuro,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: kGrisOscuro),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSintomas() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBlanco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.camera_alt, color: kNaranjaAcento),
              SizedBox(width: 8),
              Text(
                'EVIDENCIA FOTOGRÁFICA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kAzulPrincipalOscuro,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (_sintomas.isEmpty)
            const Text('No hay síntomas registrados')
          else
            ..._sintomas.map((sintoma) {
              // fotos_urls es un array en la BD
              final List<dynamic> fotosUrls = sintoma['fotos_urls'] ?? [];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        sintoma['tipo_sintoma'] ?? 'Sin tipo',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(sintoma['descripcion'] ?? 'Sin descripción'),
                    ),
                    // Mostrar todas las fotos del array
                    if (fotosUrls.isNotEmpty)
                      ...fotosUrls.map((fotoUrl) {
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: InteractiveViewer(
                                  child: Image.network(fotoUrl),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                fotoUrl,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    color: Colors.grey[200],
                                    child: const Column(
                                      children: [
                                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Error al cargar imagen'),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }).toList()
                    else
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'Sin fotos',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildAcciones() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBlanco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DECISIÓN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kAzulPrincipalOscuro,
            ),
          ),
          const Divider(height: 24),
          
          // Opción 1: Descartar con consejo
          const Text(
            'Opción 1: Descartar / Consejo Rápido',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _respuestaController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Ej: "Es solo desprendimiento de tarrajeo por humedad, raspar y pintar"',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _descartarConConsejo,
              icon: const Icon(Icons.cancel),
              label: const Text('Enviar Consejo y Descartar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGrisMedio,
                foregroundColor: kBlanco,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          
          // Opción 2: Agendar visita técnica
          const Text(
            'Opción 2: Agendar Visita Técnica',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Se observan indicios de falla estructural. '
            'Requiero inspección física en sitio.',
            style: TextStyle(color: kGrisOscuro),
          ),
          const SizedBox(height: 12),
          
          // Botón condicional según estado de cita
          FutureBuilder<Map<String, dynamic>?>(
            future: _obtenerCitaProgramada(),
            builder: (context, snapshot) {
              final cita = snapshot.data;
              final estadoCita = cita?['estado'] as String?;
              
              // Caso 1: No hay cita → Mostrar "Programar"
              if (cita == null) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/agendar_cita', arguments: {
                        'idSolicitud': widget.solicitudId,
                        'idPropietario': _solicitudData?['id_propietario'],
                        'nombreEdificacion': _edificacionData?['nombre_edificacion'] ?? 'Edificación',
                        'direccionEdificacion': _edificacionData?['direccion'],
                      });
                    },
                    icon: const Icon(Icons.event),
                    label: const Text('Programar Visita Técnica'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kVerdeExito,
                      foregroundColor: kBlanco,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              }
              
              // Caso 2: Cita pendiente → Deshabilitado
              if (estadoCita == 'pendiente_confirmacion') {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Esperando Confirmación del Propietario'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: kGrisMedio.withOpacity(0.3),
                      disabledForegroundColor: kGrisOscuro,
                    ),
                  ),
                );
              }
              
              // Caso 3: Cita confirmada → Ir a inspección
              if (estadoCita == 'confirmada') {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/inspeccion_tecnica',
                        arguments: widget.solicitudId,
                      );
                    },
                    icon: const Icon(Icons.assignment),
                    label: const Text('Realizar Inspección Técnica'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAzulPrincipalOscuro,
                      foregroundColor: kBlanco,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              }
              
              // Caso 4: Otros estados (cancelada, etc.) → Reprogramar
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/agendar_cita', arguments: {
                      'idSolicitud': widget.solicitudId,
                      'idPropietario': _solicitudData?['id_propietario'],
                      'nombreEdificacion': _edificacionData?['nombre_edificacion'] ?? 'Edificación',
                      'direccionEdificacion': _edificacionData?['direccion'],
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reprogramar Visita'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNaranjaAcento,
                    foregroundColor: kBlanco,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
