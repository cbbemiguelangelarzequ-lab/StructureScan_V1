// lib/services/ai_service.dart
// Servicio para integración con Google AI Studio (Gemini)

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/edificacion.dart';
import '../models/hallazgo_profesional.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
    final apiKey = dotenv.env['GOOGLE_AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'GOOGLE_AI_API_KEY no configurada en .env. '
        'Obtén tu clave en: https://makersuite.google.com/app/apikey',
      );
    }

    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  /// Genera un informe técnico completo en formato Markdown
  Future<String> generateTechnicalReport({
    required Map<String, dynamic> edificacionData,
    required List<Map<String, dynamic>> sintomasData,
    required List<Map<String, dynamic>> hallazgosData,
    String? notasAdicionales,
  }) async {
    try {
      final edificacion = Edificacion.fromJson(edificacionData);

      // Construir el prompt para Gemini
      final prompt = _buildReportPrompt(
        edificacion: edificacion,
        sintomasData: sintomasData,
        hallazgosData: hallazgosData,
        notasAdicionales: notasAdicionales,
      );

      // Generar el informe con Gemini
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('La IA no generó respuesta');
      }

      return response.text!;
    } catch (e) {
      throw Exception('Error al generar informe con IA: $e');
    }
  }

  String _buildReportPrompt({
    required Edificacion edificacion,
    required List<Map<String, dynamic>> sintomasData,
    required List<Map<String, dynamic>> hallazgosData,
    String? notasAdicionales,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('''
Eres un ingeniero estructural experto. Genera un informe técnico detallado y profesional en formato Markdown basado en los siguientes datos:

## DATOS DE LA EDIFICACIÓN (Perfil de Vulnerabilidad)

**Nombre:** ${edificacion.nombreEdificacion}
${edificacion.direccion != null ? '**Dirección:** ${edificacion.direccion}' : ''}
**Material Estructural:** ${edificacion.tipoMaterial.displayName} - ${edificacion.tipoMaterial.description}
**Tipo de Techo:** ${edificacion.tipoTecho.displayName}
**Forma Geométrica:** ${edificacion.formaGeometrica.displayName} - ${edificacion.formaGeometrica.description}
**Tipo de Suelo:** ${edificacion.tipoSuelo.displayName} - ${edificacion.tipoSuelo.description}
**Tipo de Construcción:** ${edificacion.tipoConstruccion.displayName}
**Modificaciones:** ${edificacion.haTenidoModificaciones ? 'Sí - ${edificacion.descripcionModificaciones}' : 'No'}
${edificacion.riesgoCalculado != null ? '**Nivel de Riesgo Calculado:** ${edificacion.riesgoCalculado!.emoji} ${edificacion.riesgoCalculado!.displayName}' : ''}

## SÍNTOMAS REPORTADOS POR EL PROPIETARIO

''');

    if (sintomasData.isEmpty) {
      buffer.writeln('No se reportaron síntomas específicos.\n');
    } else {
      for (var i = 0; i < sintomasData.length; i++) {
        final sintoma = sintomasData[i];
        buffer.writeln('''
### Síntoma ${i + 1}: ${sintoma['tipo_sintoma'] ?? 'No especificado'}
- **Descripción:** ${sintoma['descripcion'] ?? 'Sin descripción'}
- **Ubicación:** ${sintoma['ubicacion'] ?? 'No especificada'}
''');
        
        // Incluir URLs de fotos si existen
        final fotosUrls = sintoma['fotos_urls'];
        if (fotosUrls != null && fotosUrls is List && fotosUrls.isNotEmpty) {
          buffer.writeln('- **Evidencia fotográfica:**');
          for (var j = 0; j < fotosUrls.length; j++) {
            buffer.writeln('  - Foto ${j + 1}: ${fotosUrls[j]}');
          }
        }
        
        buffer.writeln();
      }
    }

    buffer.writeln('## HALLAZGOS TÉCNICOS DEL PROFESIONAL\n');

    if (hallazgosData.isEmpty) {
      buffer.writeln(
        'No se registraron hallazgos técnicos durante la inspección.\n',
      );
    } else {
      for (var i = 0; i < hallazgosData.length; i++) {
        final hallazgo = hallazgosData[i];
        final clasificacion = ClasificacionTecnica.fromString(
          hallazgo['clasificacion_tecnica'] as String,
        );
        final severidad = NivelSeveridad.fromString(
          hallazgo['severidad'] as String,
        );

        buffer.writeln('''
### Hallazgo ${i + 1}: ${clasificacion.displayName}
- **Severidad:** ${severidad.displayName} - ${severidad.description}
- **Descripción Técnica:** ${clasificacion.description}
${hallazgo['notas_tecnicas'] != null ? '- **Observaciones:** ${hallazgo['notas_tecnicas']}' : ''}
${hallazgo['recomendaciones'] != null ? '- **Recomendación:** ${hallazgo['recomendaciones']}' : ''}
- **Requiere Evacuación:** ${hallazgo['requiere_evacuacion'] == true ? 'Sí' : 'No'}

''');
      }
    }

    if (notasAdicionales != null && notasAdicionales.isNotEmpty) {
      buffer.writeln('## NOTAS ADICIONALES DEL PROFESIONAL\n');
      buffer.writeln('$notasAdicionales\n');
    }

    buffer.writeln('''

## INSTRUCCIONES PARA EL INFORME

Genera un informe técnico estructural profesional en formato Markdown con las siguientes secciones:

1. **RESUMEN EJECUTIVO**: Breve descripción de la edificación, motivo de inspección y conclusión general.

2. **ANTECEDENTES**: Contexto histórico basado en el tipo de construcción, edad estimada según modificaciones, y ubicación del terreno.

3. **VULNERABILIDAD SÍSMICA**: Análisis técnico basado en:
   - Material estructural y sistema constructivo
   - Tipo de suelo y sus implicaciones
   - Geometría en planta (riesgo de torsión)
   - Calidad de la construcción original

4. **ANÁLISIS DE PATOLOGÍAS DETECTADAS**: Para cada hallazgo, explica:
   - Causa probable de la falla
   - Implicaciones para la seguridad estructural
   - Urgencia de intervención

5. **RECOMENDACIONES TÉCNICAS**: En orden de prioridad:
   - Intervenciones de emergencia (si aplica)
   - Reparaciones estructurales necesarias
   - Mejoras preventivas
   - Monitoreo sugerido

6. **CONCLUSIONES FINALES**: 
   - ¿La estructura es HABITABLE actualmente?
   - ¿Requiere REFUERZO estructural?
   - Nivel de urgencia de la intervención

Usa terminología técnica pero también explica conceptos para que el propietario pueda comprender. Sé preciso, profesional y basado en evidencia.
''');

    return buffer.toString();
  }
}
