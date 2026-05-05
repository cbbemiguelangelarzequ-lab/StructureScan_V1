// lib/screens/owner/perfil_vulnerabilidad_screen.dart
// Pantalla de Fase A: Perfil de Vulnerabilidad (multi-step form)

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/edificacion.dart';
import '../../services/database_service.dart';
import '../../widgets/location_picker_widget.dart';
import '../../widgets/modern_alert_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilVulnerabilidadScreen extends StatefulWidget {
  final String? edificacionId; // Si existe, modo edición

  const PerfilVulnerabilidadScreen({super.key, this.edificacionId});

  @override
  State<PerfilVulnerabilidadScreen> createState() =>
      _PerfilVulnerabilidadScreenState();
}

class _PerfilVulnerabilidadScreenState
    extends State<PerfilVulnerabilidadScreen> {
  final _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isLoading = false;

  // Controladores de formulario
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _modificacionesController = TextEditingController();

  // Valores seleccionados
  TipoMaterial? _tipoMaterial;
  TipoTecho? _tipoTecho;
  FormaGeometrica? _formaGeometrica;
  TipoSuelo? _tipoSuelo;
  TipoConstruccion? _tipoConstruccion;
  bool _haTenidoModificaciones = false;
  
  // Datos de ubicación
  double? _latitud;
  double? _longitud;

  @override
  void initState() {
    super.initState();
    if (widget.edificacionId != null) {
      _cargarEdificacion();
    }
  }

  Future<void> _cargarEdificacion() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dbService.getEdificacion(widget.edificacionId!);
      final edificacion = Edificacion.fromJson(data);

      _nombreController.text = edificacion.nombreEdificacion;
      _direccionController.text = edificacion.direccion ?? '';
      _modificacionesController.text =
          edificacion.descripcionModificaciones ?? '';

      setState(() {
        _tipoMaterial = edificacion.tipoMaterial;
        _tipoTecho = edificacion.tipoTecho;
        _formaGeometrica = edificacion.formaGeometrica;
        _tipoSuelo = edificacion.tipoSuelo;
        _tipoConstruccion = edificacion.tipoConstruccion;
        _haTenidoModificaciones = edificacion.haTenidoModificaciones;
        _latitud = edificacion.latitud;
        _longitud = edificacion.longitud;
      });
    } catch (e) {
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: 'Error al cargar datos',
          type: AlertType.error,
        );
        if (widget.edificacionId != null) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarEdificacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_haTenidoModificaciones && _modificacionesController.text.trim().isEmpty) {
      ModernAlertDialog.showToast(
        context,
        message: 'Debe describir las modificaciones realizadas',
        type: AlertType.warning,
      );
      return;
    }

    // Validar que todos los campos requeridos estén completos
    if (_tipoMaterial == null ||
        _tipoTecho == null ||
        _formaGeometrica == null ||
        _tipoSuelo == null ||
        _tipoConstruccion == null) {
      ModernAlertDialog.showToast(
        context,
        message: 'Por favor complete todos los pasos',
        type: AlertType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final edificacion = Edificacion(
        id: widget.edificacionId,
        idUsuario: Supabase.instance.client.auth.currentUser!.id,
        nombreEdificacion: _nombreController.text,
        direccion: _direccionController.text.isNotEmpty ? _direccionController.text : null,
        latitud: _latitud,
        longitud: _longitud,
        tipoMaterial: _tipoMaterial!,
        tipoTecho: _tipoTecho!,
        formaGeometrica: _formaGeometrica!,
        tipoSuelo: _tipoSuelo!,
        tipoConstruccion: _tipoConstruccion!,
        haTenidoModificaciones: _haTenidoModificaciones,
        descripcionModificaciones: _haTenidoModificaciones
            ? _modificacionesController.text
            : null,
      );

      if (widget.edificacionId == null) {
        final resultado = await _dbService.crearEdificacion(edificacion.toJson());
        if (mounted) {
          // Navegar a la pantalla de selección de síntoma
          Navigator.of(context).pushReplacementNamed(
            '/seleccion_sintoma',
            arguments: resultado['id'],
          );
        }
      } else {
        await _dbService.actualizarEdificacion(
          widget.edificacionId!,
          edificacion.toJson(),
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Debug: imprimir error completo
      print('ERROR AL GUARDAR EDIFICACIÓN: $e');
      
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: 'Error al guardar edificación',
          type: AlertType.error,
          duration: const Duration(seconds: 5),
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
        title: const Text('Perfil de Vulnerabilidad'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 5) {
                    setState(() => _currentStep++);
                  } else {
                    _guardarEdificacion();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                steps: [
                  _buildInformacionBasica(),
                  _buildMaterialidad(),
                  _buildSistemaTecho(),
                  _buildConfiguracionGeometrica(),
                  _buildEntornoSuelo(),
                  _buildHistoriaConstruccion(),
                ],
              ),
            ),
    );
  }

  Step _buildInformacionBasica() {
    return Step(
      title: const Text('Información Básica'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Edificación',
              hintText: 'Ej: Casa Familiar, Depto 301',
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          // Botón para seleccionar ubicación
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPickerWidget(
                        initialLatitude: _latitud,
                        initialLongitude: _longitud,
                        initialAddress: _direccionController.text,
                      ),
                    ),
                  );
                  
                  if (resultado != null && resultado is Map<String, dynamic>) {
                    setState(() {
                      _direccionController.text = resultado['address'] ?? '';
                      _latitud = resultado['latitude'];
                      _longitud = resultado['longitude'];
                    });
                  }
                },
                icon: const Icon(Icons.location_on_rounded),
                label: Text(
                  _direccionController.text.isEmpty
                      ? 'Seleccionar ubicación en mapa'
                      : 'Cambiar ubicación',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: BorderSide(color: kAzulSecundarioClaro),
                ),
              ),
              if (_direccionController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kAzulSecundarioClaro.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kAzulSecundarioClaro.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: kVerdeExito, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _direccionController.text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Step _buildMaterialidad() {
    return Step(
      title: const Text('Materialidad'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿De qué está hecha la casa principalmente?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...TipoMaterial.values.map((tipo) => RadioListTile<TipoMaterial>(
                title: Text(tipo.displayName),
                subtitle: Text(tipo.description),
                value: tipo,
                groupValue: _tipoMaterial,
                onChanged: (value) => setState(() => _tipoMaterial = value),
              )),
        ],
      ),
    );
  }

  Step _buildSistemaTecho() {
    return Step(
      title: const Text('Sistema de Techo'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cómo es el techo?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...TipoTecho.values.map((tipo) => RadioListTile<TipoTecho>(
                title: Text(tipo.displayName),
                subtitle: Text(tipo.description),
                value: tipo,
                groupValue: _tipoTecho,
                onChanged: (value) => setState(() => _tipoTecho = value),
              )),
        ],
      ),
    );
  }

  Step _buildConfiguracionGeometrica() {
    return Step(
      title: const Text('Configuración Geométrica'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Qué forma tiene la casa vista desde arriba?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...FormaGeometrica.values.map((forma) => RadioListTile<FormaGeometrica>(
                title: Text(forma.displayName),
                subtitle: Text(forma.description),
                value: forma,
                groupValue: _formaGeometrica,
                onChanged: (value) => setState(() => _formaGeometrica = value),
              )),
        ],
      ),
    );
  }

  Step _buildEntornoSuelo() {
    return Step(
      title: const Text('Entorno y Suelo'),
      isActive: _currentStep >= 4,
      state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Sobre qué terreno está construida?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...TipoSuelo.values.map((suelo) => RadioListTile<TipoSuelo>(
                title: Text(suelo.displayName),
                subtitle: Text(suelo.description),
                value: suelo,
                groupValue: _tipoSuelo,
                onChanged: (value) => setState(() => _tipoSuelo = value),
              )),
        ],
      ),
    );
  }

  Step _buildHistoriaConstruccion() {
    return Step(
      title: const Text('Historia Constructiva'),
      isActive: _currentStep >= 5,
      state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cómo se construyó?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...TipoConstruccion.values.map((tipo) => RadioListTile<TipoConstruccion>(
                title: Text(tipo.displayName),
                subtitle: Text(tipo.description),
                value: tipo,
                groupValue: _tipoConstruccion,
                onChanged: (value) => setState(() => _tipoConstruccion = value),
              )),
          const SizedBox(height: 24),
          const Text(
            '¿Ha sufrido modificaciones?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Se han quitado muros, añadido pisos, etc.'),
            value: _haTenidoModificaciones,
            onChanged: (value) =>
                setState(() => _haTenidoModificaciones = value),
          ),
          if (_haTenidoModificaciones) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _modificacionesController,
              decoration: const InputDecoration(
                labelText: 'Describa las modificaciones',
                hintText: 'Ej: Se quitó un muro en el segundo piso',
              ),
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _modificacionesController.dispose();
    super.dispose();
  }
}
