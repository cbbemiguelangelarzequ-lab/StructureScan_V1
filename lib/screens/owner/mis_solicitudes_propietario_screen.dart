// lib/screens/owner/mis_solicitudes_propietario_screen.dart
// Pantalla para ver todas las solicitudes del propietario

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants.dart';
import '../../models/solicitud_revision.dart';
import '../../models/edificacion.dart';
import '../../services/database_service.dart';

class MisSolicitudesPropietarioScreen extends StatefulWidget {
  const MisSolicitudesPropietarioScreen({super.key});

  @override
  State<MisSolicitudesPropietarioScreen> createState() =>
      _MisSolicitudesPropietarioScreenState();
}

class _MisSolicitudesPropietarioScreenState
    extends State<MisSolicitudesPropietarioScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _solicitudes = [];
  List<Map<String, dynamic>> _citasPendientes = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      // Cargar solicitudes
      final solicitudes = await _dbService.getSolicitudesPorPropietario(userId);
      
      // Cargar citas pendientes de confirmación
      final citas = await _dbService.getCitasPorPropietario(userId);
      final citasPendientes = citas.where((cita) => 
        cita['estado'] == 'pendiente_confirmacion'
      ).toList();

      setState(() {
        _solicitudes = solicitudes;
        _citasPendientes = citasPendientes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmarCita(String idCita) async {
    try {
      await _dbService.actualizarCita(idCita, {'estado': 'confirmada'});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cita confirmada exitosamente'),
            backgroundColor: kVerdeExito,
          ),
        );
        _cargarDatos(); // Recargar datos
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

  Future<void> _rechazarCita(String idCita) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Rechazar cita?'),
        content: const Text(
          '¿Estás seguro de que quieres rechazar esta cita? '
          'El profesional deberá agendar una nueva fecha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kRojoAdvertencia),
            child: const Text('Rechazar', style: TextStyle(color: kBlanco)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _dbService.actualizarCita(idCita, {'estado': 'cancelada'});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita rechazada'),
            backgroundColor: kGrisMedio,
          ),
        );
        _cargarDatos(); // Recargar datos
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
      backgroundColor: const Color(0xFFF5F7FA), // Fondo gris muy claro
      appBar: AppBar(
        title: const Text(
          'Mis Solicitudes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kAzulPrincipalOscuro,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Citas pendientes de confirmación
                    if (_citasPendientes.isNotEmpty) ...[
                      _buildSeccionTitulo(
                        '⏰ Citas Pendientes',
                        kNaranjaAcento,
                      ),
                      const SizedBox(height: 12),
                      ..._citasPendientes.map((cita) => _buildCitaCard(cita)),
                      const SizedBox(height: 24),
                    ],

                    // Solicitudes
                    _buildSeccionTitulo('📋 Todas mis Solicitudes', kAzulPrincipalOscuro),
                    const SizedBox(height: 16),
                    
                    if (_solicitudes.isEmpty)
                      _buildEmptyState()
                    else
                      ..._solicitudes.map((solicitud) => _buildSolicitudCard(solicitud)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kAzulPrincipalOscuro.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 64,
                color: kAzulPrincipalOscuro.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes solicitudes aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kGrisOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza una nueva inspección para evaluar tu edificación.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kGrisMedio,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/perfil_vulnerabilidad');
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Nueva Inspección'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kNaranjaAcento,
                foregroundColor: kBlanco,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kGrisOscuro,
          ),
        ),
      ],
    );
  }

  Widget _buildCitaCard(Map<String, dynamic> cita) {
    final fechaProgramada = DateTime.parse(cita['fecha_programada']);
    final horaInicio = cita['hora_inicio'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kBlanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: kNaranjaAcento.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kNaranjaAcento.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: kBlanco,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: kNaranjaAcento),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cita Técnica Programada',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.event, 'Fecha', 
                  '${fechaProgramada.day}/${fechaProgramada.month}/${fechaProgramada.year}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, 'Hora', horaInicio),
                if (cita['direccion'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on, 'Dirección', cita['direccion']),
                ],
                if (cita['costo_estimado'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.attach_money, 'Costo Estimado', 'S/ ${cita['costo_estimado']}'),
                ],
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rechazarCita(cita['id']),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kGrisMedio,
                          side: const BorderSide(color: kGrisMedio),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _confirmarCita(cita['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kVerdeExito,
                          foregroundColor: kBlanco,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Confirmar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudCard(Map<String, dynamic> solicitudData) {
    final solicitud = SolicitudRevision.fromJson(solicitudData);
    
    // Configuración de colores y textos según estado
    Color estadoColor;
    Color estadoFondo;
    String estadoTexto;
    IconData estadoIcon;

    switch (solicitud.estado) {
      case EstadoSolicitud.pendiente:
        estadoColor = kGrisMedio;
        estadoFondo = kGrisClaro;
        estadoTexto = 'Pendiente';
        estadoIcon = Icons.hourglass_empty_rounded;
        break;
      case EstadoSolicitud.enRevision:
        estadoColor = kAzulSecundarioClaro;
        estadoFondo = kAzulSecundarioClaro.withOpacity(0.1);
        estadoTexto = 'En Revisión';
        estadoIcon = Icons.search_rounded;
        break;
      case EstadoSolicitud.programada:
        estadoColor = kNaranjaAcento;
        estadoFondo = kNaranjaAcento.withOpacity(0.1);
        estadoTexto = 'Programada';
        estadoIcon = Icons.event_available_rounded;
        break;
      case EstadoSolicitud.completada:
        estadoColor = kVerdeExito;
        estadoFondo = kVerdeExito.withOpacity(0.1);
        estadoTexto = 'Completada';
        estadoIcon = Icons.check_circle_outline_rounded;
        break;
      case EstadoSolicitud.descartada:
        estadoColor = kRojoAdvertencia;
        estadoFondo = kRojoAdvertencia.withOpacity(0.1);
        estadoTexto = 'Descartada';
        estadoIcon = Icons.cancel_outlined;
        break;
      case EstadoSolicitud.rechazada:
        estadoColor = kRojoAdvertencia;
        estadoFondo = kRojoAdvertencia.withOpacity(0.1);
        estadoTexto = 'Rechazada';
        estadoIcon = Icons.block_rounded;
        break;
    }

    // Configuración de riesgo
    Color riesgoColor;
    Color riesgoFondo;
    String riesgoTexto;

    switch (solicitud.nivelRiesgo) {
      case NivelRiesgo.alto:
        riesgoColor = const Color(0xFFD32F2F); // Rojo más oscuro
        riesgoFondo = const Color(0xFFFFEBEE);
        riesgoTexto = 'Riesgo Alto';
        break;
      case NivelRiesgo.medio:
        riesgoColor = const Color(0xFFF57C00); // Naranja oscuro
        riesgoFondo = const Color(0xFFFFF3E0);
        riesgoTexto = 'Riesgo Medio';
        break;
      case NivelRiesgo.bajo:
        riesgoColor = const Color(0xFF388E3C); // Verde oscuro
        riesgoFondo = const Color(0xFFE8F5E9);
        riesgoTexto = 'Riesgo Bajo';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kBlanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              '/detalle_solicitud_propietario',
              arguments: solicitud.id,
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Icono + Título + Estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono Circular
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700), // Dorado/Amarillo
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          solicitud.nivelRiesgo.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Título y Riesgo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            solicitud.sintomaPrincipal,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kGrisOscuro,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: riesgoFondo,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: riesgoColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              riesgoTexto,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: riesgoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Estado Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kBlanco,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: estadoColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(estadoIcon, size: 14, color: estadoColor),
                          const SizedBox(width: 4),
                          Text(
                            estadoTexto,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: estadoColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Descripción
                Text(
                  solicitud.descripcionBreve,
                  style: TextStyle(
                    fontSize: 14,
                    color: kGrisOscuro.withOpacity(0.8),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Alerta de Consejo Profesional (si aplica)
                if ((solicitud.estado == EstadoSolicitud.rechazada || 
                     solicitud.estado == EstadoSolicitud.descartada) && 
                    solicitud.notaProfesional != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE), // Rojo muy claro
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, 
                              size: 18, color: kRojoAdvertencia),
                            const SizedBox(width: 8),
                            const Text(
                              'Consejo del profesional:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kRojoAdvertencia,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          solicitud.notaProfesional!,
                          style: TextStyle(
                            fontSize: 13,
                            color: kRojoAdvertencia.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Indicador de Calificación (si aplica)
                if (solicitud.estado == EstadoSolicitud.completada &&
                    solicitud.idProfesional != null)
                  FutureBuilder<bool>(
                    future: _dbService.existeValoracion(solicitud.id!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data == true) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, 
                                size: 18, color: kVerdeExito),
                              const SizedBox(width: 6),
                              const Text(
                                'Ya calificaste este servicio',
                                style: TextStyle(
                                  color: kVerdeExito,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Footer: Fecha y Flecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatearFecha(solicitud.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: kGrisMedio.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: kGrisMedio.withOpacity(0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kGrisMedio),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: kGrisOscuro,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: kGrisOscuro),
          ),
        ),
      ],
    );
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha desconocida';
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      return 'Hace un momento';
    } else if (diferencia.inDays == 1) {
      return 'Hace 1 día';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}


