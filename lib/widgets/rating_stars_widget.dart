// lib/widgets/rating_stars_widget.dart
// Widget reutilizable para mostrar estrellas de valoración

import 'package:flutter/material.dart';
import '../constants.dart';

class RatingStarsWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool showNumber;

  const RatingStarsWidget({
    super.key,
    required this.rating,
    this.size = 16,
    this.color,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star, size: size, color: color ?? kNaranjaAcento);
          } else if (index < rating.ceil() && rating % 1 != 0) {
            return Icon(Icons.star_half, size: size, color: color ?? kNaranjaAcento);
          } else {
            return Icon(Icons.star_border, size: size, color: color ?? kNaranjaAcento);
          }
        }),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

// Widget interactivo para seleccionar valoración
class InteractiveRatingStars extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const InteractiveRatingStars({
    super.key,
    this.initialRating = 5,
    required this.onRatingChanged,
    this.size = 48,
  });

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: () {
            setState(() => _rating = index + 1);
            widget.onRatingChanged(_rating);
          },
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            size: widget.size,
            color: kNaranjaAcento,
          ),
        );
      }),
    );
  }
}
