// lib/screens/dashboard_profesional.dart
// Dashboard específico para ingenieros/arquitectos

import 'package:flutter/material.dart';
import 'package:structurescan_app/constants.dart';
import 'package:structurescan_app/services/database_service.dart';
import 'package:structurescan_app/widgets/modern_action_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardProfesional extends StatefulWidget {
  const DashboardProfesional({super.key});

  @override
  State<DashboardProfesional> createState() => _DashboardProfesionalState();
}

class _DashboardProfesionalState extends State<DashboardProfesional> {
  final DatabaseService _dbService = DatabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Variables para almacenar las estadísticas
  int _solicitudesNuevas = 0;
  int _enProceso = 0;
  int _completadas = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtener estadísticas del mes usando la función de base de datos
      final estadisticas = await _dbService.getEstadisticasMes(userId);

      setState(() {
        _solicitudesNuevas = estadisticas['solicitudes_nuevas'] ?? 0;
        _enProceso = estadisticas['en_proceso'] ?? 0;
        _completadas = estadisticas['completadas'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando estadísticas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StructureScan - Profesional'),
        backgroundColor: kAzulPrincipalOscuro,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: kBlanco),
            onPressed: () => Navigator.of(context).pushNamed('/help'),
            tooltip: 'Ayuda',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: kBlanco),
            onPressed: () => Navigator.of(context).pushNamed('/perfil_usuario'),
            tooltip: 'Perfil',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kAzulPrincipalOscuro.withOpacity(0.05),
              kBlanco,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _cargarEstadisticas,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bienvenida con gradiente moderno
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kAzulPrincipalOscuro,
                        kAzulSecundarioClaro,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: kAzulPrincipalOscuro.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kBlanco.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.engineering_rounded,
                              color: kBlanco,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Panel Profesional',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: kBlanco,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Gestiona solicitudes y realiza inspecciones técnicas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: kBlanco,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Acciones rápidas
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.80,
                  children: [
                    ModernActionCard(
                      icon: Icons.inbox_rounded,
                      title: 'Bandeja de Solicitudes',
                      subtitle: 'Ver solicitudes pendientes',
                      color: kAzulSecundarioClaro,
                      onTap: () => Navigator.of(context).pushNamed('/bandeja_solicitudes'),
                    ),
                    ModernActionCard(
                      icon: Icons.description_rounded,
                      title: 'Mis Informes',
                      subtitle: 'Informes generados',
                      color: kVerdeExito,
                      onTap: () => Navigator.of(context).pushNamed('/mis_informes'),
                    ),
                    ModernActionCard(
                      icon: Icons.person_rounded,
                      title: 'Mi Perfil',
                      subtitle: 'Editar perfil profesional',
                      color: kNaranjaAcento,
                      onTap: () => Navigator.of(context).pushNamed('/editar_perfil_profesional'),
                    ),
                    ModernActionCard(
                      icon: Icons.help_rounded,
                      title: 'Ayuda',
                      subtitle: 'Guía de uso',
                      color: kGrisOscuro,
                      onTap: () => Navigator.of(context).pushNamed('/help'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Estadísticas (ahora funcionales)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Resumen del Mes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kAzulPrincipalOscuro,
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      _isLoading ? '-' : _solicitudesNuevas.toString(),
                      'Solicitudes\nNuevas',
                      kRojoAdvertencia,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      _isLoading ? '-' : _enProceso.toString(),
                      'En Proceso',
                      kNaranjaAcento,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      _isLoading ? '-' : _completadas.toString(),
                      'Completadas',
                      kVerdeExito,
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

  Widget _buildStatCard(String numero, String label, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              numero,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: kGrisOscuro),
            ),
          ],
        ),
      ),
    );
  }
}
