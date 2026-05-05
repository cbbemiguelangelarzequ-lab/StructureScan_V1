// lib/screens/owner/valorar_profesional_screen.dart
// Pantalla para calificar a un profesional

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import '../../constants.dart';

class ValorarProfesionalScreen extends StatefulWidget {
  final String idSolicitud;
  final String idProfesional;
  final String nombreProfesional;

  const ValorarProfesionalScreen({
    super.key,
    required this.idSolicitud,
    required this.idProfesional,
    required this.nombreProfesional,
  });

  @override
  State<ValorarProfesionalScreen> createState() =>
      _ValorarProfesionalScreenState();
}

class _ValorarProfesionalScreenState extends State<ValorarProfesionalScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _comentarioController = TextEditingController();
  int _calificacion = 5;
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarValoracion() async {
    if (_calificacion < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una calificación'),
          backgroundColor: kNaranjaAcento,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final idUsuario = Supabase.instance.client.auth.currentUser?.id;
      if (idUsuario == null) throw Exception('Usuario no autenticado');

      await _db.crearValoracion(
        idProfesional: widget.idProfesional,
        idPropietario: idUsuario,
        idSolicitud: widget.idSolicitud,
        calificacion: _calificacion,
        comentario: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Valoración enviada correctamente'),
            backgroundColor: kVerdeExito,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
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
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valorar Profesional'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.rate_review,
                      size: 64,
                      color: kAzulSecundarioClaro,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¿Cómo calificarías el servicio de:',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.nombreProfesional,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kAzulPrincipalOscuro,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Selección de estrellas
            const Text(
              'Calificación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _calificacion = index + 1;
                      });
                    },
                    icon: Icon(
                      index < _calificacion ? Icons.star : Icons.star_border,
                      size: 48,
                      color: kNaranjaAcento,
                    ),
                  );
                }),
              ),
            ),
            Center(
              child: Text(
                _getCalificacionTexto(_calificacion),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kAzulPrincipalOscuro,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Comentario (opcional)
            const Text(
              'Comentario (opcional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentarioController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Cuéntanos sobre tu experiencia...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: kGrisClaro,
              ),
            ),

            const SizedBox(height: 32),

            // Botón enviar
            ElevatedButton(
              onPressed: _enviando ? null : _enviarValoracion,
              style: ElevatedButton.styleFrom(
                backgroundColor: kVerdeExito,
                foregroundColor: kBlanco,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                  : const Text('Enviar Valoración'),
            ),
          ],
        ),
      ),
    );
  }

  String _getCalificacionTexto(int calificacion) {
    switch (calificacion) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}
