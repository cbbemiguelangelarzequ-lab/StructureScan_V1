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
              content: 'Para iniciar una nueva inspección, presiona el botón flotante de la cámara en la esquina inferior derecha de la pantalla principal (Dashboard) o selecciona una categoría específica (Grietas, Humedad, etc.) en el menú.',
            ),
            _buildExpansionTile(
              title: '¿Cómo interpreto los resultados del análisis?',
              content: 'Los resultados muestran las patologías detectadas por la IA, categorizadas por tipo y severidad. Los colores indican el riesgo: Verde (Bajo), Naranja (Medio) y Rojo (Alto).',
            ),
            _buildExpansionTile(
              title: '¿Cómo contacto a un ingeniero especialista?',
              content: 'Si la app detecta un problema o tienes dudas, puedes usar la opción "Solicitar Revisión" en el detalle de la inspección. Esto enviará tus datos a un ingeniero certificado para una evaluación profesional.',
            ),
            _buildExpansionTile(
              title: '¿Puedo exportar los informes a PDF?',
              content: 'Sí, desde la pantalla de "Informes Técnicos" puedes seleccionar cualquier informe completado y tendrás la opción de descargarlo o compartirlo en formato PDF.',
            ),
            _buildExpansionTile(
              title: '¿Qué hago si la app detecta un riesgo alto?',
              content: 'Si obtienes un resultado de "Riesgo Alto" (Rojo), te recomendamos contactar inmediatamente a un profesional a través de la app y evitar habitar la zona afectada hasta tener una opinión experta.',
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
                    leading: const Icon(Icons.email, color: kAzulSecundarioClaro),
                    title: const Text('Correo Electrónico', style: kBodyTextStyle),
                    subtitle: const Text('soporte@structurescan.com', style: kMiniaturaTextStyle),
                    onTap: () {
                      // Implement email launch
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone, color: kAzulSecundarioClaro),
                    title: const Text('Teléfono', style: kBodyTextStyle),
                    subtitle: const Text('+591 71427312', style: kMiniaturaTextStyle),
                    onTap: () {
                      // Implement phone call launch
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.web, color: kAzulSecundarioClaro),
                    title: const Text('Visita nuestra Web', style: kBodyTextStyle),
                    subtitle: const Text('www.structurescan.com', style: kMiniaturaTextStyle),
                    onTap: () {
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
      elevation: 1,
      color: const Color(0xFFF3E5F5), // Fondo lila suave
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.purple.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        title: Text(
          title, 
          style: kBodyTextStyle.copyWith(
            fontWeight: FontWeight.bold, 
            color: const Color(0xFF4A148C), // Morado oscuro para texto
            fontSize: 16,
          )
        ),
        iconColor: const Color(0xFF7B1FA2),
        collapsedIconColor: const Color(0xFF7B1FA2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            content, 
            style: kBodyTextStyle.copyWith(
              color: kGrisOscuro,
              height: 1.5,
            )
          ),
        ],
      ),
    );
  }
}