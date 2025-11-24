// lib/screens/professional/bandeja_solicitudes_screen.dart
// Pantalla de recepción y triaje para profesionales

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/solicitud_revision.dart';
import '../../models/edificacion.dart';
import '../../services/database_service.dart';

class BandejaSolicitudesScreen extends StatefulWidget {
  const BandejaSolicitudesScreen({super.key});

  @override
  State<BandejaSolicitudesScreen> createState() => _BandejaSolicitudesScreenState();
}

class _BandejaSolicitudesScreenState extends State<BandejaSolicitudesScreen> {
  final _dbService = DatabaseService();
  List<Map<String, dynamic>> _solicitudes = [];
  bool _isLoading = true;
  String _filtroEstado = 'todas';

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> solicitudes;
      if (_filtroEstado == 'pendientes') {
        solicitudes = await _dbService.getSolicitudesPendientes();
      } else {
        solicitudes = await _dbService.getSolicitudesPendientes();
        // TODO: Cargar todas las solicitudes según filtro
      }

      setState(() {
        _solicitudes = solicitudes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kRojoAdvertencia),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de Solicitudes'),
        backgroundColor: kAzulPrincipalOscuro,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSolicitudes,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _solicitudes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: kGrisMedio),
                            SizedBox(height: 16),
                            Text(
                              'No hay solicitudes pendientes',
                              style: TextStyle(color: kGrisMedio, fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _solicitudes.length,
                        itemBuilder: (context, index) {
                          return _buildSolicitudCard(_solicitudes[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: kGrisClaro,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Filtrar:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Todas'),
            selected: _filtroEstado == 'todas',
            onSelected: (selected) {
              setState(() => _filtroEstado = 'todas');
              _cargarSolicitudes();
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Pendientes'),
            selected: _filtroEstado == 'pendientes',
            onSelected: (selected) {
              setState(() => _filtroEstado = 'pendientes');
              _cargarSolicitudes();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudCard(Map<String, dynamic> data) {
    final solicitud = SolicitudRevision.fromJson(data);

    Color riesgoColor;
    IconData riesgoIcon;
    switch (solicitud.nivelRiesgo) {
      case NivelRiesgo.alto:
        riesgoColor = kRojoAdvertencia;
        riesgoIcon = Icons.warning;
        break;
      case NivelRiesgo.medio:
        riesgoColor = kNaranjaAcento;
        riesgoIcon = Icons.info;
        break;
      case NivelRiesgo.bajo:
        riesgoColor = kVerdeExito;
        riesgoIcon = Icons.check_circle;
        break;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/revision_preliminar',
            arguments: solicitud.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con riesgo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: riesgoColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: riesgoColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(riesgoIcon, color: riesgoColor, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          solicitud.nivelRiesgo.displayName.toUpperCase(),
                          style: TextStyle(
                            color: riesgoColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kGrisClaro,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      solicitud.estado.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Síntoma principal
              Text(
                solicitud.sintomaPrincipal,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Descripción breve
              Text(
                solicitud.descripcionBreve,
                style: const TextStyle(color: kGrisOscuro),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Fecha
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: kGrisMedio),
                  const SizedBox(width: 4),
                  Text(
                    _formatearFecha(solicitud.createdAt),
                    style: const TextStyle(fontSize: 12, color: kGrisMedio),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Botón de acción
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/revision_preliminar',
                      arguments: solicitud.id,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Revisar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha desconocida';

    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
