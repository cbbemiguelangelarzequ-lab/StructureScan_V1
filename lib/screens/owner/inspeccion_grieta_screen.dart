// lib/screens/owner/inspeccion_grieta_screen.dart
// Pantalla de inspección específica para grietas (CRÍTICO para ingenieros)

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/sintoma_inspeccion.dart';
import '../../services/database_service.dart';

class InspeccionGrietaScreen extends StatefulWidget {
  final String edificacionId;

  const InspeccionGrietaScreen({super.key, required this.edificacionId});

  @override
  State<InspeccionGrietaScreen> createState() => _InspeccionGrietaScreenState();
}

class _InspeccionGrietaScreenState extends State<InspeccionGrietaScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = false;

  // Selecciones del usuario
  UbicacionElemento? _ubicacion;
  DireccionGrieta? _direccion;
  EspesorGrieta? _espesor;
  CantidadGrietas? _cantidad;
  List<String> _fotosUrls = [];

  Future<void> _guardarSintoma() async {
    // Validación
    if (_ubicacion == null || _direccion == null || _espesor == null || _cantidad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos'),
          backgroundColor: kNaranjaAcento,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sintoma = SintomaInspeccion(
        idEdificacion: widget.edificacionId,
        tipoSintoma: TipoSintoma.grieta,
        ubicacion: _ubicacion!,
        direccionGrieta: _direccion,
        espesorGrieta: _espesor,
        cantidadGrietas: _cantidad,
        fotosUrls: _fotosUrls.isNotEmpty ? _fotosUrls : null,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kRojoAdvertencia),
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
        title: const Text('Inspección de Grieta'),
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
                  _buildDireccionSection(),
                  const SizedBox(height: 24),
                  _buildEspesorSection(),
                  const SizedBox(height: 24),
                  _buildCantidadSection(),
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
          '1. ¿Dónde está la grieta?',
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

  Widget _buildDireccionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. ¿Cómo es la línea de la grieta? (CRÍTICO)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Card(
          color: Color(0xFFFFF3CD),
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La dirección de la grieta es VITAL para el diagnóstico del ingeniero',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...DireccionGrieta.values.map((direccion) {
          final bool esAlerta = direccion == DireccionGrieta.diagonal ||
              direccion == DireccionGrieta.xPattern;
          
          return Card(
            color: esAlerta ? Colors.red.shade50 : null,
            child: RadioListTile<DireccionGrieta>(
              title: Text(
                direccion.displayName,
                style: TextStyle(
                  fontWeight: esAlerta ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                direccion.interpretacion,
                style: TextStyle(
                  color: esAlerta ? kRojoAdvertencia : kGrisOscuro,
                ),
              ),
              value: direccion,
              groupValue: _direccion,
              onChanged: (value) => setState(() => _direccion = value),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEspesorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. ¿Qué tan ancha es la grieta?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...EspesorGrieta.values.map((espesor) {
          return RadioListTile<EspesorGrieta>(
            title: Text(espesor.displayName),
            subtitle: Text(espesor.description),
            value: espesor,
            groupValue: _espesor,
            onChanged: (value) => setState(() => _espesor = value),
          );
        }),
      ],
    );
  }

  Widget _buildCantidadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4. ¿Es una sola o hay varias?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...CantidadGrietas.values.map((cantidad) {
          return RadioListTile<CantidadGrietas>(
            title: Text(cantidad.displayName),
            value: cantidad,
            groupValue: _cantidad,
            onChanged: (value) => setState(() => _cantidad = value),
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
          '5. Fotos (recomendado)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            // Navegar a la cámara IA y esperar el resultado
            final resultado = await Navigator.of(context).pushNamed(
              '/analisis_camara',
              arguments: widget.edificacionId,
            );
            
            if (resultado != null && resultado is String) {
              setState(() {
                _fotosUrls.add(resultado);
              });
            }
          },
          icon: const Icon(Icons.camera_alt),
          label: const Text('Tomar Foto con IA'),
        ),
        if (_fotosUrls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fotosUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: kVerdeExito, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _fotosUrls.removeAt(index)),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: kRojoAdvertencia,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: kBlanco,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
