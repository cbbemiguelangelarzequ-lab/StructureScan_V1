// lib/screens/owner/calificar_profesional_screen.dart
// Pantalla para calificar a un profesional con estrellas y comentario

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants.dart';
import '../../services/database_service.dart';

class CalificarProfesionalScreen extends StatefulWidget {
  final String idSolicitud;
  final String idProfesional;
  final String nombreProfesional;

  const CalificarProfesionalScreen({
    super.key,
    required this.idSolicitud,
    required this.idProfesional,
    required this.nombreProfesional,
  });

  @override
  State<CalificarProfesionalScreen> createState() =>
      _CalificarProfesionalScreenState();
}

class _CalificarProfesionalScreenState
    extends State<CalificarProfesionalScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _comentarioController = TextEditingController();
  
  int _calificacion = 0;
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarCalificacion() async {
    if (_calificacion == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una calificación'),
          backgroundColor: kRojoAdvertencia,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await _db.crearValoracion(
        idProfesional: widget.idProfesional,
        idPropietario: userId,
        idSolicitud: widget.idSolicitud,
        calificacion: _calificacion,
        comentario: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true); // Retornar true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Calificación enviada exitosamente'),
            backgroundColor: kVerdeExito,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificar Profesional'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ícono y título
            const Icon(
              Icons.star_rate,
              size: 80,
              color: kNaranjaAcento,
            ),
            const SizedBox(height: 16),
            Text(
              '¿Cómo fue tu experiencia con ${widget.nombreProfesional}?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Estrellas interactivas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final estrella = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _calificacion = estrella;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      _calificacion >= estrella
                          ? Icons.star
                          : Icons.star_border,
                      size: 48,
                      color: kNaranjaAcento,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Texto de calificación
            if (_calificacion > 0)
              Text(
                _getTextoCalificacion(_calificacion),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: kAzulPrincipalOscuro,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),

            // Campo de comentario
            const Text(
              'Comentario (opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Cuéntanos más sobre tu experiencia con el profesional...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: kGrisClaro.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 32),

            // Botón enviar
            ElevatedButton(
              onPressed: _enviando ? null : _enviarCalificacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: kVerdeExito,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _enviando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kBlanco),
                      ),
                    )
                  : const Text(
                      'Enviar Calificación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBlanco,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTextoCalificacion(int calificacion) {
    switch (calificacion) {
      case 1:
        return 'Muy insatisfecho';
      case 2:
        return 'Insatisfecho';
      case 3:
        return 'Aceptable';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}
