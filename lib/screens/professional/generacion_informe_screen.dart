// lib/screens/professional/generacion_informe_screen.dart
// Pantalla de generación de informe técnico - FASE C del flujo profesional

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../models/informe_tecnico.dart';

class GeneracionInformeScreen extends StatefulWidget {
  final String solicitudId;

  const GeneracionInformeScreen({
    super.key,
    required this.solicitudId,
  });

  @override
  State<GeneracionInformeScreen> createState() =>
      _GeneracionInformeScreenState();
}

class _GeneracionInformeScreenState extends State<GeneracionInformeScreen> {
  final _dbService = DatabaseService();
  final _aiService = AIService();
  
  bool _isGenerating = false;
  bool _isEditing = false;
  String? _informeMarkdown;
  
  final _conclusionController = TextEditingController();
  final _firmaController = TextEditingController();
  final _contenidoController = TextEditingController();
  
  bool _esHabitable = true;
  bool _requiereRefuerzo = false;

  @override
  void initState() {
    super.initState();
    _verificarInformeExistente();
  }

  @override
  void dispose() {
    _conclusionController.dispose();
    _firmaController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  Future<void> _verificarInformeExistente() async {
    try {
      final informeExistente = await _dbService.getInformePorSolicitud(
        widget.solicitudId,
      );

      if (informeExistente != null) {
        final informe = InformeTecnico.fromJson(informeExistente);
        setState(() {
          _informeMarkdown = informe.contenidoMarkdown;
          _contenidoController.text = informe.contenidoMarkdown;
          _conclusionController.text = informe.conclusionFinal;
          _firmaController.text = informe.firmaProfesional ?? '';
          _esHabitable = informe.esHabitable;
          _requiereRefuerzo = informe.requiereRefuerzo;
        });
      }
    } catch (e) {
      debugPrint('Error verificando informe: $e');
    }
  }

  Future<void> _generarInforme() async {
    setState(() => _isGenerating = true);

    try {
      // Obtener datos necesarios
      final solicitudConEdif = await _dbService.getSolicitudConEdificacion(
        widget.solicitudId,
      );
      
      final edificacionData = solicitudConEdif['edificaciones'];
      final idEdificacion = edificacionData['id'] as String;
      
      final sintomas = await _dbService.getSintomasByEdificacionId(
        idEdificacion,
      );
      
      final hallazgos = await _dbService.getHallazgosBySolicitudId(
        widget.solicitudId,
      );

      // Generar informe con IA
      final markdown = await _aiService.generateTechnicalReport(
        edificacionData: edificacionData,
        sintomasData: sintomas,
        hallazgosData: hallazgos,
      );

      setState(() {
        _informeMarkdown = markdown;
        _contenidoController.text = markdown;
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Informe generado exitosamente'),
            backgroundColor: kVerdeExito,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar informe: $e'),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
    }
  }

  Future<void> _guardarInforme() async {
    if (_informeMarkdown == null || _informeMarkdown!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero genera el informe'),
          backgroundColor: kNaranjaAcento,
        ),
      );
      return;
    }

    if (_conclusionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar una conclusión final'),
          backgroundColor: kNaranjaAcento,
        ),
      );
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final contenidoFinal = _isEditing
          ? _contenidoController.text.trim()
          : _informeMarkdown!;

      final informeData = {
        'id_solicitud': widget.solicitudId,
        'id_profesional': userId,
        'contenido_markdown': contenidoFinal,
        'conclusion_final': _conclusionController.text.trim(),
        'es_habitable': _esHabitable,
        'requiere_refuerzo': _requiereRefuerzo,
        'firma_profesional': _firmaController.text.trim().isNotEmpty
            ? _firmaController.text.trim()
            : null,
      };

      // Verificar si ya existe un informe
      final informeExistente = await _dbService.getInformePorSolicitud(
        widget.solicitudId,
      );

      if (informeExistente != null) {
        // Actualizar informe existente
        await _dbService.actualizarInformeTecnico(
          informeExistente['id'],
          informeData,
        );
      } else {
        // Crear nuevo informe
        await _dbService.saveInformeTecnico(informeData);
      }

      // Actualizar estado de la solicitud
      await _dbService.updateSolicitudEstado(
        widget.solicitudId,
        'completada',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Informe guardado y propietario notificado'),
            backgroundColor: kVerdeExito,
            duration: Duration(seconds: 3),
          ),
        );

        // Volver a la bandeja de solicitudes
        Navigator.of(context).popUntil((route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generación de Informe'),
        backgroundColor: kAzulPrincipalOscuro,
        actions: [
          if (_informeMarkdown != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
              onPressed: () {
                setState(() => _isEditing = !_isEditing);
              },
              tooltip: _isEditing ? 'Vista previa' : 'Editar',
            ),
        ],
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kNaranjaAcento),
                  SizedBox(height: 24),
                  Text(
                    'Generando informe con IA...\nEsto puede tomar unos momentos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_informeMarkdown == null) ...[
                    _buildGenerarInformeCard(),
                  ] else ...[
                    _buildVisualizacionInforme(),
                    const SizedBox(height: 24),
                    _buildConclusionesFinales(),
                    const SizedBox(height: 24),
                    _buildAccionesFinales(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildGenerarInformeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 64,
              color: kNaranjaAcento,
            ),
            const SizedBox(height: 16),
            const Text(
              'Generar Informe Técnico',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'La IA generará un informe profesional basado en:\n\n'
              '• Datos de vulnerabilidad de la edificación\n'
              '• Síntomas reportados por el propietario\n'
              '• Hallazgos técnicos de la inspección\n',
              textAlign: TextAlign.center,
              style: TextStyle(color: kGrisOscuro),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generarInforme,
                icon: const Icon(Icons.psychology),
                label: const Text('Generar Informe con IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNaranjaAcento,
                  foregroundColor: kBlanco,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizacionInforme() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description, color: kAzulPrincipalOscuro),
                SizedBox(width: 8),
                Text(
                  'INFORME TÉCNICO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kAzulPrincipalOscuro,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_isEditing)
              TextField(
                controller: _contenidoController,
                maxLines: 20,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Edita el contenido del informe...',
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 500),
                child: Markdown(
                  data: _informeMarkdown!,
                  shrinkWrap: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConclusionesFinales() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONCLUSIONES FINALES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kAzulPrincipalOscuro,
              ),
            ),
            const Divider(height: 24),
            TextField(
              controller: _conclusionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Conclusión del Ingeniero',
                hintText: 'Ej: La estructura es INHABITABLE hasta...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            CheckboxListTile(
              title: const Text('La estructura es HABITABLE'),
              value: _esHabitable,
              onChanged: (value) {
                setState(() => _esHabitable = value ?? true);
              },
              activeColor: kVerdeExito,
            ),
            
            CheckboxListTile(
              title: const Text('Requiere REFUERZO estructural'),
              value: _requiereRefuerzo,
              onChanged: (value) {
                setState(() => _requiereRefuerzo = value ?? false);
              },
              activeColor: kNaranjaAcento,
            ),
            
            const SizedBox(height: 16),
            TextField(
              controller: _firmaController,
              decoration: const InputDecoration(
                labelText: 'Firma Digital (Opcional)',
                hintText: 'Ing. Juan Pérez - CIP 12345',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionesFinales() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _guardarInforme,
            icon: const Icon(Icons.save),
            label: const Text('Guardar y Publicar Informe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kVerdeExito,
              foregroundColor: kBlanco,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _generarInforme,
            icon: const Icon(Icons.refresh),
            label: const Text('Re-generar Informe'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
