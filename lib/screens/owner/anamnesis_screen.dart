// lib/screens/owner/anamnesis_screen.dart
// Pan talla de Fase C: Anamnesis (Historia y Evolución)

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/anamnesis.dart';
import '../../services/database_service.dart';

class AnamnesisScreen extends StatefulWidget {
  final String edificacionId;

  const AnamnesisScreen({super.key, required this.edificacionId});

  @override
  State<AnamnesisScreen> createState() => _AnamnesisScreenState();
}

class _AnamnesisScreenState extends State<AnamnesisScreen> {
  final _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores de texto
  final _ruidosController = TextEditingController();
  final _vibracionesController = TextEditingController();

  // Selecciones del usuario
  CuandoDescubrio? _cuandoDescubrio;
  ComportamientoDanio? _comportamiento;
  List<FactorDetonante> _factoresDetonantes = [];
  bool _tieneRuidos = false;
  bool _tieneVibraciones = false;

  Future<void> _guardarAnamnesis() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_cuandoDescubrio == null || _comportamiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos requeridos'),
          backgroundColor: kNaranjaAcento,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final anamnesis = Anamnesis(
        idEdificacion: widget.edificacionId,
        cuandoDescubrio: _cuandoDescubrio!,
        comportamiento: _comportamiento!,
        factoresDetonantes: _factoresDetonantes.isNotEmpty
            ? _factoresDetonantes
            : [FactorDetonante.ninguno],
        tieneRuidos: _tieneRuidos,
        descripcionRuidos:
            _tieneRuidos ? _ruidosController.text : null,
        tieneVibraciones: _tieneVibraciones,
        descripcionVibraciones:
            _tieneVibraciones ? _vibracionesController.text : null,
      );

      await _dbService.crearAnamnesis(anamnesis.toJson());

      if (mounted) {
        // Navegar a solicitud de revisión
        Navigator.of(context).pushReplacementNamed(
          '/solicitud_revision',
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
        title: const Text('Historia del Daño'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimelineSection(),
                    const SizedBox(height: 24),
                    _buildComportamientoSection(),
                    const SizedBox(height: 24),
                    _buildDetonantesSection(),
                    const SizedBox(height: 24),
                    _buildSensorialSection(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardarAnamnesis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kVerdeExito,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Enviar Solicitud de Revisión',
                          style: TextStyle(fontSize: 18, color: kBlanco),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. ¿Cuándo te diste cuenta del daño?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...CuandoDescubrio.values.map((cuando) {
          return RadioListTile<CuandoDescubrio>(
            title: Text(cuando.displayName),
            value: cuando,
            groupValue: _cuandoDescubrio,
            onChanged: (value) => setState(() => _cuandoDescubrio = value),
          );
        }),
      ],
    );
  }

  Widget _buildComportamientoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. ¿El daño cambia?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...ComportamientoDanio.values.map((comp) {
          final bool esUrgente = comp == ComportamientoDanio.crecimientoRapido;

          return Card(
            color: esUrgente ? Colors.red.shade50 : null,
            child: RadioListTile<ComportamientoDanio>(
              title: Text(
                comp.displayName,
                style: TextStyle(
                  fontWeight: esUrgente ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                comp.interpretacion,
                style: TextStyle(
                  color: esUrgente ? kRojoAdvertencia : kGrisOscuro,
                ),
              ),
              value: comp,
              groupValue: _comportamiento,
              onChanged: (value) => setState(() => _comportamiento = value),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetonantesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. ¿Pasó algo antes de que apareciera? (Puede seleccionar varios)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...FactorDetonante.values.map((factor) {
          final isSelected = _factoresDetonantes.contains(factor);
          final bool esAlerta = factor == FactorDetonante.sismo;

          return Card(
            color: esAlerta && isSelected ? Colors.red.shade50 : null,
            child: CheckboxListTile(
              title: Text(
                factor.displayName,
                style: TextStyle(
                  fontWeight: esAlerta ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                factor.interpretacion,
                style: TextStyle(
                  color: esAlerta ? kRojoAdvertencia : kGrisOscuro,
                  fontSize: 12,
                ),
              ),
              value: isSelected,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _factoresDetonantes.add(factor);
                  } else {
                    _factoresDetonantes.remove(factor);
                  }
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSensorialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4. Observaciones Sensoriales',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('¿Escuchas ruidos?'),
          subtitle: const Text('Crujidos, golpes secos, etc.'),
          value: _tieneRuidos,
          onChanged: (value) => setState(() => _tieneRuidos = value),
        ),
        if (_tieneRuidos) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _ruidosController,
            decoration: const InputDecoration(
              labelText: 'Describe los ruidos',
              hintText: 'Ej: Crujidos por la noche',
            ),
            maxLines: 2,
          ),
        ],
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('¿Sientes vibraciones?'),
          subtitle: const Text('Al caminar o cuando pasan vehículos'),
          value: _tieneVibraciones,
          onChanged: (value) => setState(() => _tieneVibraciones = value),
        ),
        if (_tieneVibraciones) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _vibracionesController,
            decoration: const InputDecoration(
              labelText: 'Describe las vibraciones',
              hintText: 'Ej: Vibración excesiva al pasar camiones',
            ),
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _ruidosController.dispose();
    _vibracionesController.dispose();
    super.dispose();
  }
}
