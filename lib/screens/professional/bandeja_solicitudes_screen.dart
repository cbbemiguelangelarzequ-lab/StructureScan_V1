// lib/screens/professional/bandeja_solicitudes_screen.dart
// Pantalla de recepción y triaje para profesionales

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/solicitud_revision.dart';
import '../../models/edificacion.dart';
import '../../services/database_service.dart';
import '../../widgets/modern_alert_dialog.dart';

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

  // Colores personalizados basados en la imagen de referencia
  final Color _purpleSelected = const Color(0xFFE8DEF8);
  final Color _purpleText = const Color(0xFF6750A4);
  final Color _orangeRisk = const Color(0xFFFFA726);
  final Color _orangeRiskBg = const Color(0xFFFFF3E0);

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> solicitudes;
      // Nota: La lógica de filtrado real debería hacerse en la base de datos o filtrando la lista completa
      // Por ahora mantenemos la llamada original pero simulamos el filtro en memoria si es necesario
      // o ajustamos según la API disponible.
      solicitudes = await _dbService.getSolicitudesPendientes();
      
      if (_filtroEstado == 'pendientes') {
        // Filtrar solo pendientes si la API devuelve más cosas (aunque getSolicitudesPendientes sugiere que ya son pendientes)
        // Asumimos que getSolicitudesPendientes trae las asignadas o disponibles.
      }

      setState(() {
        _solicitudes = solicitudes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: 'Error al cargar solicitudes',
          type: AlertType.error,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Fondo gris muy claro
      appBar: AppBar(
        title: const Text(
          'Bandeja de Solicitudes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kAzulPrincipalOscuro,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _cargarSolicitudes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _solicitudes.length,
                          itemBuilder: (context, index) {
                            return _buildSolicitudCard(_solicitudes[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: kGrisMedio.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No hay solicitudes pendientes',
            style: TextStyle(color: kGrisMedio.withOpacity(0.8), fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Text(
            'Filtrar:', 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: kGrisOscuro
            )
          ),
          const SizedBox(width: 12),
          _buildFilterChip('Todas', 'todas'),
          const SizedBox(width: 8),
          _buildFilterChip('Pendientes', 'pendientes'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroEstado == value;
    return InkWell(
      onTap: () {
        setState(() => _filtroEstado = value);
        _cargarSolicitudes();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _purpleSelected : kBlanco,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.transparent : kGrisMedio.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 16, color: _purpleText),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _purpleText : kGrisOscuro,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolicitudCard(Map<String, dynamic> data) {
    final solicitud = SolicitudRevision.fromJson(data);

    // Configuración de riesgo
    Color riesgoColor;
    Color riesgoFondo;
    IconData riesgoIcon;
    
    switch (solicitud.nivelRiesgo) {
      case NivelRiesgo.alto:
        riesgoColor = kRojoAdvertencia;
        riesgoFondo = const Color(0xFFFFEBEE);
        riesgoIcon = Icons.warning_amber_rounded;
        break;
      case NivelRiesgo.medio:
        riesgoColor = _orangeRisk;
        riesgoFondo = _orangeRiskBg;
        riesgoIcon = Icons.info_outline_rounded;
        break;
      case NivelRiesgo.bajo:
        riesgoColor = kVerdeExito;
        riesgoFondo = const Color(0xFFE8F5E9);
        riesgoIcon = Icons.check_circle_outline_rounded;
        break;
    }

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
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              '/revision_preliminar',
              arguments: solicitud.id,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Badge Riesgo + Estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge Riesgo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: riesgoFondo,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: riesgoColor),
                      ),
                      child: Row(
                        children: [
                          Icon(riesgoIcon, color: riesgoColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            solicitud.nivelRiesgo.displayName.toUpperCase(),
                            style: TextStyle(
                              color: riesgoColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kGrisClaro.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        solicitud.estado.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kGrisOscuro,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Título (Síntoma)
                Text(
                  solicitud.sintomaPrincipal,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kGrisOscuro,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Descripción
                Text(
                  solicitud.descripcionBreve,
                  style: TextStyle(
                    color: kGrisOscuro.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Footer: Fecha y Botón Revisar
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
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/revision_preliminar',
                          arguments: solicitud.id,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _purpleText,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text(
                        'Revisar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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


