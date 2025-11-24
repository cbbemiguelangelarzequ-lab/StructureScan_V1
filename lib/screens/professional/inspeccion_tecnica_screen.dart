// lib/screens/professional/inspeccion_tecnica_screen.dart
// Pantalla de inspección técnica en sitio - FASE B del flujo profesional

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants.dart';
import '../../models/hallazgo_profesional.dart';
import '../../services/database_service.dart';

class InspeccionTecnicaScreen extends StatefulWidget {
  final String solicitudId;

  const InspeccionTecnicaScreen({
    super.key,
    required this.solicitudId,
  });

  @override
  State<InspeccionTecnicaScreen> createState() =>
      _InspeccionTecnicaScreenState();
}

class _InspeccionTecnicaScreenState extends State<InspeccionTecnicaScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = true;

  Map<String, dynamic>? _solicitudData;
  Map<String, dynamic>? _edificacionData;
  List<Map<String, dynamic>> _hallazgos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final solicitudConEdif = await _dbService.getSolicitudConEdificacion(
        widget.solicitudId,
      );
      
      final hallazgos = await _dbService.getHallazgosBySolicitudId(
        widget.solicitudId,
      );

      setState(() {
        _solicitudData = solicitudConEdif;
        _edificacionData = solicitudConEdif['edificaciones'];
        _hallazgos = hallazgos;
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

  Future<void> _capturarHallazgo() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario no autenticado'),
          backgroundColor: kRojoAdvertencia,
        ),
      );
      return;
    }

    // Navegar a la pantalla de cámara para capturar hallazgo
    final idEdificacion = _edificacionData?['id'] as String?;
    if (idEdificacion == null) return;

    final result = await Navigator.of(context).pushNamed(
      '/analisis_camara',
      arguments: {
        'edificacionId': idEdificacion,
        'userRole': 'professional', // Indicar que es un profesional
      },
    );

    if (result != null && result is Map<String, dynamic>) {
      // Mostrar diálogo para agregar detalles técnicos
      _mostrarDialogoHallazgo(result);
    }
  }

  void _mostrarDialogoHallazgo(Map<String, dynamic> capturaData) {
    final notasController = TextEditingController();
    final elementoController = TextEditingController();
    
    ClasificacionTecnica? clasificacionSeleccionada;
    NivelSeveridad? severidadSeleccionada;
    bool requiereRefuerzo = false;
    bool esHabitable = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Detalles del Hallazgo Técnico'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clasificación Técnica',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<ClasificacionTecnica>(
                  isExpanded: true,
                  value: clasificacionSeleccionada,
                  hint: const Text('Seleccionar...'),
                  items: ClasificacionTecnica.values.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => clasificacionSeleccionada = value);
                  },
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Nivel de Severidad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<NivelSeveridad>(
                  isExpanded: true,
                  value: severidadSeleccionada,
                  hint: const Text('Seleccionar...'),
                  items: NivelSeveridad.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => severidadSeleccionada = value);
                  },
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: elementoController,
                  decoration: const InputDecoration(
                    labelText: 'Elemento Estructural',
                    hintText: 'Ej: Columna C-4, Viga V-102',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: notasController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas Técnicas',
                    hintText: 'Observaciones del ingeniero...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                CheckboxListTile(
                  title: const Text('Requiere Refuerzo'),
                  value: requiereRefuerzo,
                  onChanged: (value) {
                    setDialogState(() => requiereRefuerzo = value ?? false);
                  },
                ),
                
                CheckboxListTile(
                  title: const Text('Estructura Habitable'),
                  value: esHabitable,
                  onChanged: (value) {
                    setDialogState(() => esHabitable = value ?? true);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (clasificacionSeleccionada == null ||
                    severidadSeleccionada == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Debes seleccionar clasificación y severidad',
                      ),
                      backgroundColor: kNaranjaAcento,
                    ),
                  );
                  return;
                }

                await _guardarHallazgo(
                  clasificacion: clasificacionSeleccionada!,
                  severidad: severidadSeleccionada!,
                  elementoEstructural: elementoController.text.trim(),
                  notasTexto: notasController.text.trim(),
                  requiereRefuerzo: requiereRefuerzo,
                  esHabitable: esHabitable,
                  imagenUrl: capturaData['imagenUrl'],
                  detecciones: capturaData['detecciones'],
                );

                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar Hallazgo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarHallazgo({
    required ClasificacionTecnica clasificacion,
    required NivelSeveridad severidad,
    required String elementoEstructural,
    required String notasTexto,
    required bool requiereRefuerzo,
    required bool esHabitable,
    String? imagenUrl,
    dynamic detecciones,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final hallazgoData = {
        'id_solicitud': widget.solicitudId,
        'id_profesional': userId,
        'clasificacion_tecnica': clasificacion.value,
        'nivel_severidad': severidad.value,
        'notas_texto': notasTexto.isNotEmpty ? notasTexto : null,
        'elemento_estructural':
            elementoEstructural.isNotEmpty ? elementoEstructural : null,
        'requiere_refuerzo': requiereRefuerzo,
        'es_habitable': esHabitable,
        // Nota: imagen_url y detecciones podrían guardarse si extiende el schema
      };

      await _dbService.crearHallazgo(hallazgoData);
      
      await _cargarDatos(); // Recargar hallazgos

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Hallazgo guardado'),
            backgroundColor: kVerdeExito,
          ),
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

  Future<void> _finalizarInspeccion() async {
    if (_hallazgos.isEmpty) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar'),
          content: const Text(
            'No has registrado ningún hallazgo. '
            '¿Estás seguro de querer finalizar la inspección?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, finalizar'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;
    }

    // Navegar a la pantalla de generación de informe
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        '/generacion_informe',
        arguments: widget.solicitudId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspección Técnica'),
        backgroundColor: kAzulPrincipalOscuro,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEdificacionInfo(),
                  const SizedBox(height: 24),
                  _buildHallazgosList(),
                  const SizedBox(height: 24),
                  _buildAcciones(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _capturarHallazgo,
        backgroundColor: kNaranjaAcento,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Capturar Hallazgo'),
      ),
    );
  }

  Widget _buildEdificacionInfo() {
    if (_edificacionData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EDIFICACIÓN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kAzulPrincipalOscuro,
              ),
            ),
            const Divider(height: 16),
            Text(
              _edificacionData!['nombre_edificacion'] ?? 'Sin nombre',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_edificacionData!['direccion'] != null)
              Text(_edificacionData!['direccion']),
          ],
        ),
      ),
    );
  }

  Widget _buildHallazgosList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HALLAZGOS REGISTRADOS (${_hallazgos.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kAzulPrincipalOscuro,
              ),
            ),
            const Divider(height: 16),
            if (_hallazgos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No hay hallazgos registrados.\n'
                    'Presiona el botón "Capturar Hallazgo" para comenzar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kGrisMedio),
                  ),
                ),
              )
            else
              ..._hallazgos.map((h) {
                final hallazgo = HallazgoProfesional.fromJson(h);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: kGrisClaro,
                  child: ListTile(
                    leading: Icon(
                      Icons.report_problem,
                      color: hallazgo.nivelSeveridad == NivelSeveridad.critico
                          ? kRojoAdvertencia
                          : hallazgo.nivelSeveridad == NivelSeveridad.severo
                              ? kNaranjaAcento
                              : kVerdeExito,
                    ),
                    title: Text(hallazgo.clasificacionTecnica.displayName),
                    subtitle: Text(
                      'Severidad: ${hallazgo.nivelSeveridad.displayName}',
                    ),
                    trailing: Text(
                      hallazgo.elementoEstructural ?? 'N/A',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAcciones() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _finalizarInspeccion,
        icon: const Icon(Icons.check_circle),
        label: const Text('Finalizar Inspección y Generar Informe'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kVerdeExito,
          foregroundColor: kBlanco,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
