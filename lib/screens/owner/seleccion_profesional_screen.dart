// lib/screens/owner/seleccion_profesional_screen.dart
// Pantalla para seleccionar profesional - Diseño Moderno

import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../constants.dart';
import '../../widgets/modern_loading_overlay.dart';
import '../../widgets/modern_alert_dialog.dart';

class SeleccionProfesionalScreen extends StatefulWidget {
  const SeleccionProfesionalScreen({super.key});

  @override
  State<SeleccionProfesionalScreen> createState() =>
      _SeleccionProfesionalScreenState();
}

class _SeleccionProfesionalScreenState
    extends State<SeleccionProfesionalScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _profesionales = [];
  List<Map<String, dynamic>> _profesionalesFiltrados = [];
  
  bool _cargando = true;
  String? _error;
  
  // Datos de solicitud si viene del flujo de envío
  Map<String, dynamic>? _solicitudData;
  bool _fromSolicitud = false;

  @override
  void initState() {
    super.initState();
    _cargarProfesionales();
    _searchController.addListener(_filtrarProfesionales);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtener argumentos pasados desde solicitud_revision_screen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _solicitudData = args['solicitud_data'] as Map<String, dynamic>?;
      _fromSolicitud = args['from_solicitud'] == true;
    }
  }

  void _filtrarProfesionales() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _profesionalesFiltrados = List.from(_profesionales);
      } else {
        _profesionalesFiltrados = _profesionales.where((prof) {
          final nombre = (prof['full_name'] ?? '').toString().toLowerCase();
          final especialidad = (prof['especializacion'] ?? '').toString().toLowerCase();
          return nombre.contains(query) || especialidad.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _cargarProfesionales() async {
    try {
      final profesionales = await _db.getProfesionalesDisponibles();

      // Enriquecer con estadísticas
      final profesionalesConStats = await Future.wait(
        profesionales.map((prof) async {
          try {
            final promedio = await _db.getPromedioValoraciones(prof['id_usuario']);
            return {
              ...prof,
              'valoracion_promedio': promedio,
            };
          } catch (e) {
            return {...prof, 'valoracion_promedio': 0.0};
          }
        }),
      );

      if (mounted) {
        setState(() {
          _profesionales =
              profesionalesConStats.where((p) => p['rol'] == 'profesional').toList();
          _profesionalesFiltrados = List.from(_profesionales);
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Seleccionar Profesional',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kAzulPrincipalOscuro,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const ModernLoadingOverlay(
        message: 'Buscando profesionales disponibles...',
        isOverlay: false,
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: kRojoAdvertencia),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kGrisOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: kGrisMedio)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarProfesionales,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAzulPrincipalOscuro,
                foregroundColor: kBlanco,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _profesionalesFiltrados.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _profesionalesFiltrados.length,
                  itemBuilder: (context, index) {
                    final profesional = _profesionalesFiltrados[index];
                    return _buildProfesionalCard(profesional);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: kAzulPrincipalOscuro,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o especialidad...',
            prefixIcon: const Icon(Icons.search, color: kGrisMedio),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: kGrisMedio),
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: kGrisMedio.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _profesionales.isEmpty
                ? 'No hay profesionales disponibles'
                : 'No se encontraron resultados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: kGrisOscuro,
            ),
          ),
          if (_profesionales.isNotEmpty)
            TextButton(
              onPressed: () => _searchController.clear(),
              child: const Text('Limpiar búsqueda'),
            ),
        ],
      ),
    );
  }

  Widget _buildProfesionalCard(Map<String, dynamic> profesional) {
    final String nombre = profesional['full_name'] ?? 'Sin nombre';
    final String especializacion = profesional['especializacion'] ?? 'No especificado';
    final int experiencia = profesional['years_experiencia'] ?? 0;
    final double valoracion = (profesional['valoracion_promedio'] ?? 0.0).toDouble();
    final double? tarifaDesde = profesional['tarifa_desde'] != null
        ? (profesional['tarifa_desde'] as num).toDouble()
        : null;
    final double? tarifaHasta = profesional['tarifa_hasta'] != null
        ? (profesional['tarifa_hasta'] as num).toDouble()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          borderRadius: BorderRadius.circular(16),
          onTap: () => _verPerfilCompleto(profesional),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Hero(
                      tag: 'profesional_${profesional['id_usuario']}',
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kAzulSecundarioClaro.withOpacity(0.1),
                          image: profesional['foto_perfil_url'] != null
                              ? DecorationImage(
                                  image: NetworkImage(profesional['foto_perfil_url']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: profesional['foto_perfil_url'] == null
                            ? Center(
                                child: Text(
                                  nombre.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: kAzulSecundarioClaro,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kAzulPrincipalOscuro,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kAzulPrincipalOscuro.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              especializacion,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: kAzulPrincipalOscuro,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 18, color: kNaranjaAcento),
                              const SizedBox(width: 4),
                              Text(
                                valoracion.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '($experiencia años exp.)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kGrisMedio,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (tarifaDesde != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tarifa estimada',
                            style: TextStyle(fontSize: 10, color: kGrisMedio),
                          ),
                          Text(
                            'Bs. ${tarifaDesde.toInt()} - ${tarifaHasta?.toInt() ?? "?"}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kVerdeExito,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(),
                    
                    ElevatedButton(
                      onPressed: () => _seleccionarProfesional(profesional),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAzulPrincipalOscuro,
                        foregroundColor: kBlanco,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Seleccionar'),
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

  void _verPerfilCompleto(Map<String, dynamic> profesional) {
    Navigator.pushNamed(
      context,
      '/perfil_profesional',
      arguments: profesional['id_usuario'],
    );
  }

  void _seleccionarProfesional(Map<String, dynamic> profesional) async {
    if (_fromSolicitud && _solicitudData != null) {
      // Guardar la solicitud con el profesional seleccionado
      try {
        await _db.crearSolicitudRevision({
          ..._solicitudData!,
          'id_profesional': profesional['id_usuario'],
        });

        if (!mounted) return;

        // Mostrar diálogo de éxito moderno
        ModernAlertDialog.showSuccess(
          context,
          title: 'Solicitud Enviada',
          message: 'Tu solicitud ha sido enviada a ${profesional['full_name']}. Recibirás una respuesta en 24-48 horas.',
          onConfirm: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      } catch (e) {
        if (mounted) {
          ModernAlertDialog.showError(
            context,
            title: 'Error',
            message: 'No se pudo enviar la solicitud: $e',
          );
        }
      }
    } else {
      // Flujo normal - solo retornar el ID del profesional seleccionado
      Navigator.pop(context, profesional['id_usuario']);
    }
  }
}
