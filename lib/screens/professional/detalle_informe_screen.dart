// lib/screens/professional/detalle_informe_screen.dart
// Pantalla de detalle de informe con opciones de compartir

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';
import '../../constants.dart';

class DetalleInformeScreen extends StatefulWidget {
  final String idInforme;

  const DetalleInformeScreen({super.key, required this.idInforme});

  @override
  State<DetalleInformeScreen> createState() => _DetalleInformeScreenState();
}

class _DetalleInformeScreenState extends State<DetalleInformeScreen> {
  final DatabaseService _db = DatabaseService();
  final PdfService _pdfService = PdfService();
  final ShareService _shareService = ShareService();

  Map<String, dynamic>? _informe;
  bool _cargando = true;
  bool _generandoPdf = false;

  @override
  void initState() {
    super.initState();
    _cargarInforme();
  }

  Future<void> _cargarInforme() async {
    try {
      // widget.idInforme es el ID del informe, no de la solicitud
      final informe = await _db.getInformePorId(widget.idInforme);
      setState(() {
        _informe = informe;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _generarYCompartirPdf() async {
    if (_informe == null) return;

    setState(() => _generandoPdf = true);

    try {
      final pdfFile = await _pdfService.generarPdfInforme(
        contenidoMarkdown: _informe!['contenido_markdown'],
        nombreEdificacion: 'Informe Técnico',
        nombreProfesional: 'Profesional',
        conclusionFinal: _informe!['conclusion_final'],
        esHabitable: _informe!['es_habitable'],
        requiereRefuerzo: _informe!['requiere_refuerzo'],
      );

      await _shareService.compartirGenerico(
        'Informe Técnico Estructural',
        pdfFile.path,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _generandoPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Informe'),
        backgroundColor: kAzulPrincipalOscuro,
        actions: [
          if (_informe != null)
            IconButton(
              icon: _generandoPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kBlanco),
                      ),
                    )
                  : const Icon(Icons.share, color: kBlanco),
              onPressed: _generandoPdf ? null : _generarYCompartirPdf,
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _informe == null
              ? const Center(child: Text('Informe no encontrado'))
              : _buildContenido(),
    );
  }

  Widget _buildContenido() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Resumen
          Card(
            color: _informe!['es_habitable']
                ? kVerdeExito.withOpacity(0.1)
                : kRojoAdvertencia.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _informe!['es_habitable']
                        ? '✅ EDIFICACIÓN HABITABLE'
                        : '⚠️ EDIFICACIÓN NO HABITABLE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _informe!['es_habitable']
                          ? kVerdeExito
                          : kRojoAdvertencia,
                    ),
                  ),
                  if (_informe!['requiere_refuerzo']) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '🔧 Requiere refuerzo estructural',
                      style: TextStyle(
                        fontSize: 14,
                        color: kNaranjaAcento,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Conclusión
          if (_informe!['conclusion_final'] != null) ...[
            const Text(
              'Conclusión Final',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_informe!['conclusion_final']),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Contenido Markdown
          const Text(
            'Informe Completo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(
                data: _informe!['contenido_markdown'] ?? '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
