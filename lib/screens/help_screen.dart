// lib/screens/help_screen.dart
import 'package:flutter/material.dart';
import 'package:structurescan_app/constants.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrisClaro,
      appBar: AppBar(
        backgroundColor: kAzulPrincipalOscuro,
        title: Text('Ayuda y Soporte', style: kTituloPrincipalStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlanco),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preguntas Frecuentes (FAQ)',
              style: kTituloPantallaStyle.copyWith(fontSize: 20, color: kAzulPrincipalOscuro),
            ),
            const SizedBox(height: 15),
            _buildExpansionTile(
              title: '¿Cómo inicio una nueva inspección?',
              content: 'Para iniciar una nueva inspección, presiona el botón flotante de la cámara en la esquina inferior derecha de la pantalla principal (Dashboard).',
            ),
            _buildExpansionTile(
              title: '¿Cómo interpreto los resultados del análisis?',
              content: 'Los resultados muestran las grietas detectadas categorizadas por tipo (lineal, ramificada, capilar, etc.) y severidad (leve, moderada, severa), indicadas por colores.',
            ),
            _buildExpansionTile(
              title: '¿Puedo exportar los informes a PDF?',
              content: 'Sí, desde la pantalla de "Informes Técnicos" puedes seleccionar un informe y tendrás la opción de exportarlo o compartirlo en formato PDF.',
            ),
            const SizedBox(height: 25),
            Text(
              'Contacto y Soporte',
              style: kTituloPantallaStyle.copyWith(fontSize: 20, color: kAzulPrincipalOscuro),
            ),
            const SizedBox(height: 15),
            Card(
              margin: EdgeInsets.zero,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email, color: kAzulSecundarioClaro),
                    title: Text('Correo Electrónico', style: kBodyTextStyle),
                    subtitle: Text('soporte@structurescan.com', style: kMiniaturaTextStyle),
                    onTap: () {
                      print('Enviar correo a soporte');
                      // Implement email launch
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.phone, color: kAzulSecundarioClaro),
                    title: Text('Teléfono', style: kBodyTextStyle),
                    subtitle: Text('+591 71427312', style: kMiniaturaTextStyle),
                    onTap: () {
                      print('Llamar a soporte');
                      // Implement phone call launch
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.web, color: kAzulSecundarioClaro),
                    title: Text('Visita nuestra Web', style: kBodyTextStyle),
                    subtitle: Text('www.structurescan.com', style: kMiniaturaTextStyle),
                    onTap: () {
                      print('Abrir sitio web de soporte');
                      // Implement URL launch
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for FAQ expansion tiles
  Widget _buildExpansionTile({required String title, required String content}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(title, style: kBodyTextStyle.copyWith(fontWeight: FontWeight.bold, color: kAzulPrincipalOscuro)),
        childrenPadding: const EdgeInsets.all(16.0),
        children: [
          Text(content, style: kBodyTextStyle.copyWith(color: kGrisOscuro)),
        ],
      ),
    );
  }
}