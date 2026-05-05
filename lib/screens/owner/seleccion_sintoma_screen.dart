// lib/screens/owner/seleccion_sintoma_screen.dart
// Pantalla para seleccionar el tipo de síntoma principal

import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/sintoma_inspeccion.dart';

class SeleccionSintomaScreen extends StatelessWidget {
  final String edificacionId;

  const SeleccionSintomaScreen({super.key, required this.edificacionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Qué problema observas?'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el síntoma principal que deseas reportar:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: TipoSintoma.values.map((sintoma) {
                  return _buildSintomaCard(context, sintoma);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSintomaCard(BuildContext context, TipoSintoma sintoma) {
    Color cardColor;
    switch (sintoma) {
      case TipoSintoma.grieta:
        cardColor = Colors.red.shade100;
        break;
      case TipoSintoma.humedad:
        cardColor = Colors.blue.shade100;
        break;
      case TipoSintoma.deformacion:
        cardColor = Colors.orange.shade100;
        break;
      case TipoSintoma.desprendimiento:
        cardColor = Colors.brown.shade100;
        break;
    }

    return Card(
      elevation: 4,
      color: cardColor,
      child: InkWell(
        onTap: () {
          String route;
          switch (sintoma) {
            case TipoSintoma.grieta:
              route = '/inspeccion_grieta';
              break;
            case TipoSintoma.humedad:
              route = '/inspeccion_humedad';
              break;
            case TipoSintoma.deformacion:
              route = '/inspeccion_deformacion';
              break;
            case TipoSintoma.desprendimiento:
              route = '/inspeccion_desprendimiento';
              break;
          }
          Navigator.of(context).pushNamed(route, arguments: edificacionId);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sintoma.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              sintoma.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                sintoma.description,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
