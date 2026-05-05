// lib/screens/owner/inspeccion_deformacion_screen.dart
// Pantalla de inspección específica para deformación/hundimiento

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/sintoma_inspeccion.dart';
import '../../services/database_service.dart';
import '../../widgets/modern_alert_dialog.dart';

class InspeccionDeformacionScreen extends StatefulWidget {
  final String edificacionId;

  const InspeccionDeformacionScreen({super.key, required this.edificacionId});

  @override
  State<InspeccionDeformacionScreen> createState() =>
      _InspeccionDeformacionScreenState();
}

class _InspeccionDeformacionScreenState
    extends State<InspeccionDeformacionScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = false;

  // Selecciones del usuario
  UbicacionElemento? _ubicacion;
  final List<SintomaFuncional> _sintomasFuncionales = [];
  
  // Fotos capturadas con IA
  final List<Map<String, dynamic>> _fotosCapturadasConIA = [];

  Future<void> _guardarSintoma() async {
    // Validación
    if (_ubicacion == null || _sintomasFuncionales.isEmpty) {
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
        tipoSintoma: TipoSintoma.deformacion,
        ubicacion: _ubicacion!,
        sintomasFuncionales: _sintomasFuncionales,
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
        title: const Text('Inspección de Deformación'),
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
                  _buildSintomasFuncionalesSection(),
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
          '1. ¿Dónde observas la deformación?',
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
      ],
    );
  }

  Widget _buildSintomasFuncionalesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. ¿Cuáles de estos síntomas observas? (Puede seleccionar varios)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Card(
          color: Color(0xFFFFF3CD),
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estos síntomas indican que la estructura se está moviendo',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...SintomaFuncional.values.map((sintoma) {
          final isSelected = _sintomasFuncionales.contains(sintoma);
          return CheckboxListTile(
            title: Text(sintoma.displayName),
            value: isSelected,
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _sintomasFuncionales.add(sintoma);
                } else {
                  _sintomasFuncionales.remove(sintoma);
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
            child: Text(
              '${_fotosCapturadasConIA.length} foto(s) capturada(s) ✓',
              style: const TextStyle(
                color: kVerdeExito,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
