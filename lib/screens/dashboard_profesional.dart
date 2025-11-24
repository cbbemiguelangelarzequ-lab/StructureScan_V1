// lib/screens/dashboard_profesional.dart
// Dashboard específico para ingenieros/arquitectos

import 'package:flutter/material.dart';
import 'package:structurescan_app/constants.dart';

class DashboardProfesional extends StatelessWidget {
  const DashboardProfesional({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StructureScan - Profesional'),
        backgroundColor: kAzulPrincipalOscuro,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: kBlanco),
            onPressed: () => Navigator.of(context).pushNamed('/help'),
            tooltip: 'Ayuda',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: kBlanco),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
            tooltip: 'Perfil',
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: kGrisClaro,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            Card(
              color: kBlanco,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel Profesional',
                      style: kTituloPantallaStyle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestiona solicitudes y realiza inspecciones técnicas',
                      style: kBodyTextStyle.copyWith(color: kGrisOscuro),
                    ),
                  ],
                ),
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
              children: [
                _buildActionCard(
                  context,
                  '📥 Bandeja de\nSolicitudes',
                  'Ver solicitudes pendientes',
                  kAzulSecundarioClaro,
                  () => Navigator.of(context).pushNamed('/bandeja_solicitudes'),
                ),
                _buildActionCard(
                  context,
                  '📊 Mis Informes',
                  'Informes generados',
                  kVerdeExito,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo - Ver informes completados'),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  '👤 Mi Perfil',
                  'Datos profesionales',
                  kNaranjaAcento,
                  () => Navigator.of(context).pushNamed('/profile'),
                ),
                _buildActionCard(
                  context,
                  '❓ Ayuda',
                  'Guía de uso',
                  kGrisOscuro,
                  () => Navigator.of(context).pushNamed('/help'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Estadísticas (simuladas)
            Text(
              'Resumen del Mes',
              style: kTituloPantallaStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('0', 'Solicitudes\nNuevas', kRojoAdvertencia),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('0', 'En Proceso', kNaranjaAcento),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('0', 'Completadas', kVerdeExito),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String titulo,
    String subtitulo,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.touch_app, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: kGrisMedio),
              ),
            ],
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
