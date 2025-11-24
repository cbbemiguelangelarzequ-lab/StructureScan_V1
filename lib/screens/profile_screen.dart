// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:structurescan_app/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrisClaro,
      appBar: AppBar(
        backgroundColor: kAzulPrincipalOscuro,
        title: Text('Perfil de Usuario', style: kTituloPrincipalStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlanco),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: kBlanco),
            onPressed: () {
              print('Editar Perfil');
              // Navigate to an edit profile screen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: kAzulSecundarioClaro,
                    child: Icon(Icons.person, size: 80, color: kBlanco),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Miguel Arze',
                    style: kTituloPantallaStyle.copyWith(fontSize: 24, color: kAzulPrincipalOscuro),
                  ),
                  Text(
                    'Miguel.arze@gmail.com',
                    style: kBodyTextStyle.copyWith(color: kGrisOscuro),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Especialista en Estructuras',
                    style: kMiniaturaTextStyle.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const Divider(height: 40, thickness: 1),
            Text(
              'Información Personal',
              style: kTituloPantallaStyle.copyWith(fontSize: 18, color: kAzulPrincipalOscuro),
            ),
            const SizedBox(height: 15),
            _buildInfoRow(Icons.phone, 'Teléfono', '+591 71427312'),
            _buildInfoRow(Icons.location_on, 'Ubicación', 'Cochabamba, Bolivia'),
            _buildInfoRow(Icons.apartment, 'Organización', 'ScanPro Solutions'),
            const SizedBox(height: 30),
            Text(
              'Ajustes de la Aplicación',
              style: kTituloPantallaStyle.copyWith(fontSize: 18, color: kAzulPrincipalOscuro),
            ),
            const SizedBox(height: 15),
            ListTile(
              leading: Icon(Icons.notifications_active, color: kAzulSecundarioClaro),
              title: Text('Notificaciones', style: kBodyTextStyle),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: kGrisMedio),
              onTap: () {
                print('Ajustes de Notificaciones');
                // Navigate to Notification Settings
              },
            ),
            ListTile(
              leading: Icon(Icons.security, color: kAzulSecundarioClaro),
              title: Text('Seguridad y Privacidad', style: kBodyTextStyle),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: kGrisMedio),
              onTap: () {
                print('Ajustes de Seguridad');
                // Navigate to Security Settings
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: kAzulSecundarioClaro),
              title: Text('Idioma', style: kBodyTextStyle),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: kGrisMedio),
              onTap: () {
                print('Ajustes de Idioma');
                // Navigate to Language Settings
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  print('Cerrar Sesión');
                  // Implement logout logic (e.g., clear user session and navigate to login)
                  Navigator.of(context).pushNamedAndRemoveUntil('/auth', (Route<dynamic> route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRojoAdvertencia,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.logout, color: kBlanco),
                label: Text('Cerrar Sesión', style: kButtonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: kAzulSecundarioClaro, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kMiniaturaTextStyle.copyWith(color: kGrisOscuro),
                ),
                Text(
                  value,
                  style: kBodyTextStyle.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}