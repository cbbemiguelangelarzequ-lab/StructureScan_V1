// lib/services/pdf_service.dart
// Servicio para generar PDFs de informes técnicos

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Genera un PDF del informe técnico
  Future<File> generarPdfInforme({
    required String contenidoMarkdown,
    required String nombreEdificacion,
    required String nombreProfesional,
    String? conclusionFinal,
    bool? esHabitable,
    bool? requiereRefuerzo,
  }) async {
    final pdf = pw.Document();

    // Crear el PDF con el contenido
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INFORME TÉCNICO ESTRUCTURAL',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Edificación: $nombreEdificacion',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    'Profesional: $nombreProfesional',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Fecha: ${DateTime.now().toString().split(' ')[0]}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),

            // Resumen ejecutivo
            if (conclusionFinal != null) ...[
              pw.Text(
                'RESUMEN EJECUTIVO',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                conclusionFinal,
                style: const pw.TextStyle(fontSize: 12),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 20),
            ],

            // Evaluación
            if (esHabitable != null || requiereRefuerzo != null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EVALUACIÓN',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (esHabitable != null)
                      pw.Text(
                        '• Habitabilidad: ${esHabitable ? "APTA PARA HABITAR" : "NO APTA - REQUIERE INTERVENCIÓN"}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    if (requiereRefuerzo != null)
                      pw.Text(
                        '• Refuerzo estructural: ${requiereRefuerzo ? "REQUERIDO" : "NO REQUERIDO"}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            // Contenido del informe (simplificado del Markdown)
            pw.Text(
              'INFORME DETALLADO',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            // Dividir el contenido en párrafos para que MultiPage pueda distribuirlos
            ..._dividirEnParrafos(_simplificarMarkdown(contenidoMarkdown)).map(
              (parrafo) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  parrafo,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ),

            // Footer
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.Text(
              'Generado por StructureScan - Sistema de Triaje Estructural',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    // Guardar el archivo temporalmente
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'informe_${nombreEdificacion.replaceAll(' ', '_')}_$timestamp.pdf';
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Sube el PDF al storage de Supabase
  Future<String> subirPdfAStorage(File pdfFile, String nombreArchivo) async {
    final fileName = 'informes/$nombreArchivo';
    
    await _supabase.storage.from('imagenes').upload(
          fileName,
          pdfFile,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    final url = _supabase.storage.from('imagenes').getPublicUrl(fileName);
    
    return url;
  }

  /// Simplifica el Markdown para el PDF (elimina caracteres especiales)
  String _simplificarMarkdown(String markdown) {
    // Eliminar # (headers)
    String simplified = markdown.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    
    // Eliminar ** (bold) y * (italic)
    simplified = simplified.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    simplified = simplified.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    
    // Eliminar > (blockquote)
    simplified = simplified.replaceAll(RegExp(r'^>\s+', multiLine: true), '');
    
    // Eliminar - (listas)
    simplified = simplified.replaceAll(RegExp(r'^-\s+', multiLine: true), '• ');
    
    return simplified;
  }

  /// Divide el contenido en párrafos para permitir paginación automática
  List<String> _dividirEnParrafos(String contenido) {
    // Dividir por saltos de línea dobles (párrafos)
    List<String> parrafos = contenido.split('\n\n');
    
    // Filtrar párrafos vacíos
    parrafos = parrafos.where((p) => p.trim().isNotEmpty).toList();
    
    return parrafos;
  }
}
