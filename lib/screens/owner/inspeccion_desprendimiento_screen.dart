// lib/screens/owner/inspeccion_desprendimiento_screen.dart
// Pantalla de inspección específica para desprendimientos

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/sintoma_inspeccion.dart';
import '../../services/database_service.dart';
import '../../widgets/modern_alert_dialog.dart';

class InspeccionDesprendimientoScreen extends StatefulWidget {
  final String edificacionId;

  const InspeccionDesprendimientoScreen({super.key, required this.edificacionId});

  @override
  State<InspeccionDesprendimientoScreen> createState() =>
      _InspeccionDesprendimientoScreenState();
}

class _InspeccionDesprendimientoScreenState
    extends State<InspeccionDesprendimientoScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = false;

  // Selecciones del usuario
  UbicacionElemento? _ubicacion;
  
  // Fotos capturadas con IA
  List<Map<String, dynamic>> _fotosCapturadasConIA = [];

  Future<void> _guardarSintoma() async {
    // Validación
    if (_ubicacion == null) {
      ModernAlertDialog.showToast(
        context,
        message: 'Por favor seleccione la ubicación',
        type: AlertType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sintoma = SintomaInspeccion(
        idEdificacion: widget.edificacionId,
        tipoSintoma: TipoSintoma.desprendimiento,
        ubicacion: _ubicacion!,
        fotosUrls: _fotosCapturadasConIA.isNotEmpty
            ? _fotosCapturadasConIA
                .map((foto) => foto['foto_anotada_url'] as String)
                .toList()
            : null,
        fotoOriginalUrl: _fotosCapturadasConIA.isNotEmpty
            ? _fotosCapturadasConIA.first['foto_original_url'] as String?
            : null,
        fotoAnotadaUrl: _fotosCapturadasConIA.isNotEmpty
            ? _fotosCapturadasConIA.first['foto_anotada_url'] as String?
            : null,
        deteccionesIA: _fotosCapturadasConIA.isNotEmpty
            ? _fotosCapturadasConIA.first['detecciones_ia'] as Map<String, dynamic>?
            : null,
      );

      await _dbService.crearSintoma(sintoma.toJson());

      if (mounted) {
        // Navegar a anamnesis
        Navigator.of(context).pushReplacementNamed(
          '/anamnesis',
          arguments: widget.edificacionId,
        );
      }
    } catch (e) {
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: 'Error al guardar síntoma',
          type: AlertType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspección de Desprendimiento'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUbicacionSection(),
                  const SizedBox(height: 24),
                  _buildFotosSection(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardarSintoma,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kVerdeExito,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Continuar a Anamnesis',
                        style: TextStyle(fontSize: 18, color: kBlanco),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUbicacionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. ¿Dónde está el desprendimiento?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: UbicacionElemento.values.map((ubicacion) {
            return ChoiceChip(
              label: Text(ubicacion.displayName),
              selected: _ubicacion == ubicacion,
              onSelected: (selected) {
                setState(() => _ubicacion = selected ? ubicacion : null);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Card(
          color: Color(0xFFF8D7DA),
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pistas importantes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('• Revoque: Material de acabado caído\n'
                    '• Enchape: Cerámicos o azulejos despegados\n'
                    '• Pintura: Descascaramiento'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Fotos (Recomendado)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final resultado = await Navigator.of(context).pushNamed(
              '/analisis_camara',
              arguments: widget.edificacionId,
            );
            if (resultado != null && resultado is Map<String, dynamic>) {
              setState(() {
                _fotosCapturadasConIA.add({
                  'foto_original_url': resultado['foto_original_url'],
                  'foto_anotada_url': resultado['foto_anotada_url'],
                  'detecciones_ia': resultado['detecciones_ia'],
                });
              });
            }
          },
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Tomar Foto con IA'),
        ),
        if (_fotosCapturadasConIA.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fotosCapturadasConIA.length} foto(s) capturada(s) ✓',
                  style: const TextStyle(
                      color: kVerdeExito, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _fotosCapturadasConIA.asMap().entries.map((entry) {
                    final index = entry.key;
                    final foto = entry.value;
                    final urlAnotada = foto['foto_anotada_url'] as String;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            urlAnotada,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _fotosCapturadasConIA.removeAt(index));
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
