// lib/widgets/professional_card_widget.dart
// Widget de tarjeta de profesional reutilizable

import 'package:flutter/material.dart';
import '../constants.dart';
import 'rating_stars_widget.dart';

class ProfessionalCardWidget extends StatelessWidget {
  final Map<String, dynamic> profesional;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;

  const ProfessionalCardWidget({
    super.key,
    required this.profesional,
    this.onTap,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final String nombre = profesional['full_name'] ?? 'Sin nombre';
    final String especializacion =
        profesional['especializacion'] ?? 'No especificado';
    final double valoracion =
        (profesional['valoracion_promedio'] ?? 0.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kAzulSecundarioClaro,
                child: Text(
                  nombre.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    color: kBlanco,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      especializacion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kGrisMedio,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RatingStarsWidget(
                      rating: valoracion,
                      size: 14,
                      showNumber: true,
                    ),
                  ],
                ),
              ),
              if (onSelect != null)
                IconButton(
                  icon: const Icon(Icons.check_circle, color: kVerdeExito),
                  onPressed: onSelect,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
