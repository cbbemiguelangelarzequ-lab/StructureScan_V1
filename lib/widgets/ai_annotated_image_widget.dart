// lib/widgets/ai_annotated_image_widget.dart
// Widget para mostrar imagen con detecciones de IA

import 'package:flutter/material.dart';
import '../constants.dart';

class AIAnnotatedImageWidget extends StatelessWidget {
  final String? fotoAnotadaUrl;
  final String? fotoOriginalUrl;
  final Map<String, dynamic>? deteccionesIA;
  final bool showDetectionSummary;

  const AIAnnotatedImageWidget({
    super.key,
    this.fotoAnotadaUrl,
    this.fotoOriginalUrl,
    this.deteccionesIA,
    this.showDetectionSummary = true,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = fotoAnotadaUrl ?? fotoOriginalUrl ?? '';
    
    if (imageUrl.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_not_supported, size: 48, color:kGrisMedio),
                SizedBox(height: 8),
                Text('No hay imagen disponible'),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, size: 48, color: kRojoAdvertencia),
                    SizedBox(height: 8),
                    Text('Error al cargar imagen'),
                  ],
                ),
              );
            },
          ),
        ),
        if (showDetectionSummary && deteccionesIA != null)
          _buildDetectionSummary(), 
      ],
    );
  }

  Widget _buildDetectionSummary() {
    if (deteccionesIA == null) return const SizedBox.shrink();

    final predictions = deteccionesIA!['predictions'] as List? ?? [];
    if (predictions.isEmpty) return const SizedBox.shrink();

    return Card(
      color: kAzulSecundarioClaro.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: kAzulSecundarioClaro),
                const SizedBox(width: 8),
                Text(
                  '${predictions.length} detección(es) de IA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: predictions.map((pred) {
                final String clase = pred['class'] ?? 'desconocido';
                final double conf = (pred['confidence'] ?? 0.0) * 100;
                return Chip(
                  label: Text(
                    '$clase (${conf.toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: kGrisClaro,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
