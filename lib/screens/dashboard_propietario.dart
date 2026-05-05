// lib/screens/dashboard_propietario.dart
// Dashboard específico para usuarios propietarios

import 'package:flutter/material.dart';
import 'package:structurescan_app/constants.dart';

class DashboardPropietario extends StatelessWidget {
  const DashboardPropietario({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StructureScan'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bienvenida con gradiente
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
                      color: kAzulPrincipalOscuro.withOpacity(0.3),
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
                            color: kBlanco.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.home_work_rounded,
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
                                '¡Bienvenido!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: kBlanco,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tu asistente de seguridad estructural',
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

              // Botón principal: Nueva Inspección
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kNaranjaAcento,
                      kNaranjaAcento.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kNaranjaAcento.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/perfil_vulnerabilidad');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_home_work_rounded, color: kBlanco, size: 28),
                  label: const Text(
                    'Nueva Inspección de Edificación',
                    style: TextStyle(fontSize: 16, color: kBlanco, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Acciones rápidas
              const Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kAzulPrincipalOscuro,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      'Mis\nSolicitudes',
                      Icons.description_rounded,
                      kAzulSecundarioClaro,
                      () => Navigator.of(context).pushNamed('/mis_solicitudes_propietario'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      'Buscar\nProfesionales',
                      Icons.person_search_rounded,
                      kVerdeExito,
                      () => Navigator.of(context).pushNamed('/seleccion_profesional'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Guía rápida
              const Text(
                '¿Cómo funciona?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kAzulPrincipalOscuro,
                ),
              ),
              const SizedBox(height: 16),
              _buildModernGuiaCard(
                '1',
                'Perfil de Edificación',
                'Describe las características estructurales',
                Icons.apartment_rounded,
                kAzulSecundarioClaro,
              ),
              _buildModernGuiaCard(
                '2',
                'Reporta Síntomas',
                'Documenta grietas, humedad con IA',
                Icons.camera_alt_rounded,
                kNaranjaAcento,
              ),
              _buildModernGuiaCard(
                '3',
                'Historial del Daño',
                'Cuándo apareció y cómo evoluciona',
                Icons.timeline_rounded,
                Colors.purple,
              ),
              _buildModernGuiaCard(
                '4',
                'Revisión Profesional',
                'Un experto evaluará tu caso',
                Icons.engineering_rounded,
                kVerdeExito,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kBlanco,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: kGrisOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGuiaCard(
    String numero,
    String titulo,
    String descripcion,
    IconData icono,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBlanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(
                  color: kBlanco,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: kAzulPrincipalOscuro,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kGrisMedio,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
        ],
      ),
    );
  }
}
