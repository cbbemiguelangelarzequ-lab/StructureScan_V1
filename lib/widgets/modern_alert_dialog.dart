// lib/widgets/modern_alert_dialog.dart
import 'package:flutter/material.dart';
import '../constants.dart';

enum AlertType {
  success,
  error,
  warning,
  info,
}

class ModernAlertDialog {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required AlertType type,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    Color primaryColor;
    IconData icon;
    
    switch (type) {
      case AlertType.success:
        primaryColor = kVerdeExito;
        icon = Icons.check_circle_rounded;
        break;
      case AlertType.error:
        primaryColor = kRojoAdvertencia;
        icon = Icons.error_rounded;
        break;
      case AlertType.warning:
        primaryColor = kNaranjaAcento;
        icon = Icons.warning_rounded;
        break;
      case AlertType.info:
        primaryColor = kAzulSecundarioClaro;
        icon = Icons.info_rounded;
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kBlanco,
                  primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con ícono
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: primaryColor,
                      size: 48,
                    ),
                  ),
                ),

                // Título
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kAzulPrincipalOscuro,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 12),

                // Mensaje
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      color: kGrisOscuro,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // Botón
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onPressed != null) {
                          onPressed();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: kBlanco,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        buttonText ?? 'Entendido',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    show(
      context,
      title: title,
      message: message,
      type: AlertType.success,
      buttonText: 'Aceptar',
      onPressed: onConfirm,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    show(
      context,
      title: title,
      message: message,
      type: AlertType.error,
      buttonText: 'Entendido',
      onPressed: onConfirm,
    );
  }

  // Toast moderno flotante
  static void showToast(
    BuildContext context, {
    required String message,
    required AlertType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case AlertType.success:
        backgroundColor = kVerdeExito;
        icon = Icons.check_circle_rounded;
        break;
      case AlertType.error:
        backgroundColor = kRojoAdvertencia;
        icon = Icons.error_rounded;
        break;
      case AlertType.warning:
        backgroundColor = kNaranjaAcento;
        icon = Icons.warning_rounded;
        break;
      case AlertType.info:
        backgroundColor = kAzulSecundarioClaro;
        icon = Icons.info_rounded;
        break;
    }

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kBlanco.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: kBlanco,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: kBlanco,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}
