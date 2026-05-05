// lib/screens/owner/inspeccion_humedad_screen.dart
// Pantalla de inspección específica para humedad

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/sintoma_inspeccion.dart';
import '../../services/database_service.dart';
import '../../widgets/modern_alert_dialog.dart';

class InspeccionHumedadScreen extends StatefulWidget {
  final String edificacionId;

  const InspeccionHumedadScreen({super.key, required this.edificacionId});

  @override
  State<InspeccionHumedadScreen> createState() =>
      _InspeccionHumedadScreenState();
}

class _InspeccionHumedadScreenState extends State<InspeccionHumedadScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = false;

  // Selecciones del usuario
  UbicacionElemento? _ubicacion;
  final List<AparienciaHumedad> _apariencias = [];
  
  final List<Map<String, dynamic>> _fotosCapturadasConIA = [];

  Future<void> _guardarSintoma() async {
    // Validación
    if (_ubicacion == null || _apariencias.isEmpty) {
      ModernAlertDialog.showToast(
        context,
        message: 'Por favor complete todos los campos',
        type: AlertType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sintoma = SintomaInspeccion(
        idEdificacion: widget.edificacionId,
        tipoSintoma: TipoSintoma.humedad,
        ubicacion: _ubicacion!,
        aparienciaHumedad: _apariencias,
        // Guardar URLs de imágenes anotadas
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
        title: const Text('Inspección de Humedad'),
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
                  _buildAparienciaSection(),
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
          '1. ¿Dónde está la humedad?',
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
          color: Color(0xFFD1ECF1),
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pistas según la ubicación:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('• Techo: Posible gotera\n'
                    '• Parte baja pared: Salitre/capilaridad\n'
                    '• Pared intermedia: Tubería rota'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAparienciaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. ¿Cómo se ve la humedad? (Puede seleccionar varios)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...AparienciaHumedad.values.map((apariencia) {
          final isSelected = _apariencias.contains(apariencia);
          return CheckboxListTile(
            title: Text(apariencia.displayName),
            value: isSelected,
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _apariencias.add(apariencia);
                } else {
                  _apariencias.remove(apariencia);
                }
              });
            },
          );
        }),
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
                                Icons.close,
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
