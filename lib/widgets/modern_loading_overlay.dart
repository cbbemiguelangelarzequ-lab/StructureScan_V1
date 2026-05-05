import 'package:flutter/material.dart';
import '../constants.dart';

class ModernLoadingOverlay extends StatelessWidget {
  final String message;
  final bool isOverlay;
  final Color? customBackgroundColor;

  const ModernLoadingOverlay({
    super.key,
    required this.message,
    this.isOverlay = false,
    this.customBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Definir colores según el modo (Overlay vs Pantalla completa)
    final backgroundColor = customBackgroundColor ??
        (isOverlay ? Colors.black.withOpacity(0.7) : const Color(0xFFF5F7FA));
    
    final textColor = isOverlay ? Colors.white : kGrisOscuro;
    final spinnerColor = kNaranjaAcento;

    return Container(
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spinner animado personalizado
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
              strokeWidth: 5,
              backgroundColor: isOverlay 
                  ? Colors.white.withOpacity(0.1) 
                  : kGrisMedio.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 32),
          
          // Mensaje de texto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
