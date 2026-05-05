// lib/screens/owner/confirmar_cita_screen.dart
// Pantalla para que el propietario confirme o rechace una cita

import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/cita_tecnica.dart';
import '../../constants.dart';

class ConfirmarCitaScreen extends StatefulWidget {
  final String idCita;

  const ConfirmarCitaScreen({super.key, required this.idCita});

  @override
  State<ConfirmarCitaScreen> createState() => _ConfirmarCitaScreenState();
}

class _ConfirmarCitaScreenState extends State<ConfirmarCitaScreen> {
  final DatabaseService _db = DatabaseService();
  CitaTecnica? _cita;
  Map<String, dynamic>? _profesional;
  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarCita();
  }

  Future<void> _cargarCita() async {
    try {
      final citaData = await _db.getCitaPorSolicitud(widget.idCita);
      if (citaData != null) {
        final cita = CitaTecnica.fromJson(citaData);
        final profesional = await _db.getPerfil(cita.idProfesional);

        setState(() {
          _cita = cita;
          _profesional = profesional;
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmarCita() async {
    setState(() => _procesando = true);

    try {
      await _db.actualizarEstadoCita(_cita!.id!, 'confirmada');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cita confirmada correctamente'),
            backgroundColor: kVerdeExito,
          ),
        );
        Navigator.pop(context, true);
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
    } finally {
      setState(() => _procesando = false);
    }
  }

  Future<void> _rechazarCita() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Rechazar cita?'),
        content: const Text(
          '¿Estás seguro que deseas rechazar esta cita? El profesional será notificado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: kRojoAdvertencia),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _procesando = true);

    try {
      await _db.actualizarEstadoCita(_cita!.id!, 'cancelada');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita cancelada'),
            backgroundColor: kNaranjaAcento,
          ),
        );
        Navigator.pop(context, false);
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
    } finally {
      setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Cita'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _cita == null
              ? const Center(child: Text('No se encontró la cita'))
              : _buildContenido(),
    );
  }

  Widget _buildContenido() {
    final nombreProfesional = _profesional?['full_name'] ?? 'Profesional';
    final fecha = _cita!.fechaProgramada;
    final horaInicio = _cita!.horaInicio.format(context);
    final horaFin = _cita!.horaFin?.format(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Estado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kNaranjaAcento.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kNaranjaAcento),
            ),
            child: const Row(
              children: [
                Icon(Icons.pending_actions, color: kNaranjaAcento),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pendiente de confirmación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kNaranjaAcento,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Profesional
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profesional',
                    style: TextStyle(
                      fontSize: 12,
                      color: kGrisMedio,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nombreProfesional,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kAzulPrincipalOscuro,
                    ),
                  ),
                  if (_profesional?['especializacion'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _profesional!['especializacion'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: kGrisMedio,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Detalles de la cita
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalles de la visita',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetalle(
                    Icons.calendar_today,
                    'Fecha',
                    '${fecha.day}/${fecha.month}/${fecha.year}',
                  ),
                  _buildDetalle(
                    Icons.access_time,
                    'Horario',
                    horaFin != null
                        ? '$horaInicio - $horaFin'
                        : 'Desde $horaInicio',
                  ),
                  if (_cita!.costoEstimado != null)
                    _buildDetalle(
                      Icons.attach_money,
                      'Costo estimado',
                      'S/. ${_cita!.costoEstimado!.toStringAsFixed(2)}',
                    ),
                  if (_cita!.direccion != null)
                    _buildDetalle(
                      Icons.location_on,
                      'Dirección',
                      _cita!.direccion!,
                    ),
                  if (_cita!.notasProfesional != null) ...[
                    const Divider(height: 24),
                    const Text(
                      'Notas del profesional:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_cita!.notasProfesional!),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _procesando ? null : _rechazarCita,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kRojoAdvertencia,
                    side: const BorderSide(color: kRojoAdvertencia),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _procesando ? null : _confirmarCita,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kVerdeExito,
                    foregroundColor: kBlanco,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _procesando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(kBlanco),
                          ),
                        )
                      : const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetalle(IconData icono, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: kAzulSecundarioClaro),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kGrisMedio,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
