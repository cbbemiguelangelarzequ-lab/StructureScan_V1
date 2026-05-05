// lib/screens/professional/agendar_cita_screen.dart
// Pantalla para que el profesional agende una cita técnica

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/database_service.dart';
import '../../widgets/modern_alert_dialog.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cita_tecnica.dart';

class AgendarCitaScreen extends StatefulWidget {
  final String idSolicitud;
  final String idPropietario;
  final String nombreEdificacion;
  final String? direccionEdificacion;

  const AgendarCitaScreen({
    super.key,
    required this.idSolicitud,
    required this.idPropietario,
    required this.nombreEdificacion,
    this.direccionEdificacion,
  });

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _costoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.direccionEdificacion != null && widget.direccionEdificacion!.isNotEmpty) {
      _direccionController.text = widget.direccionEdificacion!;
    }
  }

  @override
  void dispose() {
    _costoController.dispose();
    _direccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  Future<void> _seleccionarHora(bool esInicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = hora;
        } else {
          _horaFin = hora;
        }
      });
    }
  }

  Future<void> _guardarCita() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaSeleccionada == null) {
      ModernAlertDialog.showToast(
        context,
        message: 'Por favor selecciona una fecha',
        type: AlertType.warning,
      );
      return;
    }

    if (_horaInicio == null) {
      ModernAlertDialog.showToast(
        context,
        message: 'Por favor selecciona la hora de inicio',
        type: AlertType.warning,
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final idProfesional = Supabase.instance.client.auth.currentUser?.id;
      if (idProfesional == null) throw Exception('Usuario no autenticado');

      final fechaProgramada = DateTime(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        _horaInicio!.hour,
        _horaInicio!.minute,
      );

      final cita = CitaTecnica(
        idSolicitud: widget.idSolicitud,
        idProfesional: idProfesional,
        idPropietario: widget.idPropietario,
        fechaProgramada: fechaProgramada,
        horaInicio: _horaInicio!,
        horaFin: _horaFin,
        costoEstimado: _costoController.text.isEmpty
            ? null
            : double.parse(_costoController.text),
        direccion: _direccionController.text.isEmpty
            ? null
            : _direccionController.text,
        notasProfesional: _notasController.text.isEmpty
            ? null
            : _notasController.text,
        estado: EstadoCita.pendienteConfirmacion,
      );

      await _db.crearCita(cita.toJson());

      await _db.actualizarSolicitudRevision(
        widget.idSolicitud,
        {'estado': 'programada'},
      );

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle_rounded, color: kVerdeExito, size: 60),
            title: const Text('¡Solicitud Enviada!'),
            content: const Text(
              'La cita ha sido programada. El propietario recibirá una notificación para confirmar.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: kVerdeExito),
                child: const Text('Aceptar', style: TextStyle(color: kBlanco)),
              ),
            ],
          ),
        );
        
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/bandeja_solicitudes',
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: 'Error al agendar cita',
          type: AlertType.error,
        );
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Visita Técnica'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info de la edificación
              Card(
                color: kAzulSecundarioClaro.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edificación:',
                        style: TextStyle(
                          fontSize: 12,
                          color: kGrisMedio,
                        ),
                      ),
                      Text(
                        widget.nombreEdificacion,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kAzulPrincipalOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Fecha
              const Text(
                'Fecha de la visita *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _seleccionarFecha,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: kGrisMedio),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: kAzulSecundarioClaro),
                      const SizedBox(width: 12),
                      Text(
                        _fechaSeleccionada == null
                            ? 'Seleccionar fecha'
                            : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _fechaSeleccionada == null
                              ? kGrisMedio
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Horario
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hora inicio *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _seleccionarHora(true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: kGrisMedio),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    color: kAzulSecundarioClaro),
                                const SizedBox(width: 8),
                                Text(
                                  _horaInicio?.format(context) ?? '--:--',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hora fin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _seleccionarHora(false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: kGrisMedio),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    color: kAzulSecundarioClaro),
                                const SizedBox(width: 8),
                                Text(
                                  _horaFin?.format(context) ?? '--:--',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Costo estimado
              const Text(
                'Costo estimado (Bs/.)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _costoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ejemplo: Bs/. 500.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Dirección
              const Text(
                'Dirección de la visita',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _direccionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Dirección completa...',
                  prefixIcon: const Icon(Icons.location_on_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notas
              const Text(
                'Notas adicionales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notasController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Instrucciones o consideraciones especiales...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botón guardar
              ElevatedButton(
                onPressed: _guardando ? null : _guardarCita,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kVerdeExito,
                  foregroundColor: kBlanco,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(kBlanco),
                        ),
                      )
                    : const Text('Agendar Visita'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
