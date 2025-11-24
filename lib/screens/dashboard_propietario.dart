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
        title: const Text('StructureScan - Propietario'),
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
                      '¡Bienvenido a tu Asistente Estructural!',
                      style: kTituloPantallaStyle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Detecta problemas en tu edificación antes de que sea tarde',
                      style: kBodyTextStyle.copyWith(color: kGrisOscuro),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón principal: Nueva Inspección
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/perfil_vulnerabilidad');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNaranjaAcento,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                icon: const Icon(Icons.home_work, color: kBlanco, size: 32),
                label: const Text(
                  'Nueva Inspección de Edificación',
                  style: TextStyle(fontSize: 18, color: kBlanco),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mis Solicitudes
            Text(
              'Mis Solicitudes de Revisión',
              style: kTituloPantallaStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.description, color: kAzulSecundarioClaro),
                title: const Text('Ver mis solicitudes'),
                subtitle: const Text('Revisa el estado de tus reportes'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navegar a lista de solicitudes del propietario
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidad en desarrollo')),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Guía rápida
            Text(
              '¿Cómo funciona?',
              style: kTituloPantallaStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            _buildGuiaCard(
              '1',
              'Perfil de la Edificación',
              'Describe las características de tu casa o edificio',
              Icons.business,
            ),
            _buildGuiaCard(
              '2',
              'Reporta Síntomas',
              'Grietas, humedad, deformaciones - con fotos asistidas por IA',
              Icons.warning,
            ),
            _buildGuiaCard(
              '3',
              'Historial del Daño',
              'Cuándo apareció, cómo evoluciona',
              Icons.history,
            ),
            _buildGuiaCard(
              '4',
              'Enviar a Profesional',
              'Un ingeniero experto revisará tu caso',
              Icons.engineering,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuiaCard(String numero, String titulo, String descripcion, IconData icono) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kAzulSecundarioClaro,
          child: Text(numero, style: const TextStyle(color: kBlanco, fontWeight: FontWeight.bold)),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(descripcion, style: const TextStyle(fontSize: 13)),
        trailing: Icon(icono, color: kGrisMedio),
      ),
    );
  }
}
