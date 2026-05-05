// lib/services/image_processing_service.dart
// Servicio para procesamiento de imágenes con detección de IA
// Complementa la funcionalidad de analisis_camara_screen.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;

class ImageProcessingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  final String _roboflowApiKey = dotenv.env['ROBOFLOW_API_KEY'] ?? '';
  final String _roboflowModelId = dotenv.env['ROBOFLOW_MODEL_ID'] ?? '';

  /// Detecta daños con Roboflow API
  /// Reutiliza la misma lógica que analisis_camara_screen.dart
  Future<Map<String, dynamic>> detectarDaniosIA(File imagenOriginal) async {
    if (_roboflowApiKey.isEmpty || _roboflowModelId.isEmpty) {
      throw Exception('API Keys de Roboflow no configuradas en .env');
    }

    final imageBytes = await imagenOriginal.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final url = Uri.parse(
      'https://detect.roboflow.com/$_roboflowModelId?api_key=$_roboflowApiKey&format=json&confidence=40',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': base64Image.length.toString(),
        },
        body: base64Image,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Error en API Roboflow: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error al detectar daños: $e');
    }
  }

  /// Crea una imagen anotada con bounding boxes estáticos
  /// (Diferente de la visualización en tiempo real de analisis_camara_screen.dart)
  Future<File> crearImagenAnotada({
    required File imagenOriginal,
    required List<dynamic> predicciones,
  }) async {
    try {
      final imageBytes = await imagenOriginal.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Dibujar bounding boxes permanentes
      for (var prediccion in predicciones) {
        final String clase = prediccion['class'] ?? 'desconocido';
        final double confidence = (prediccion['confidence'] ?? 0.0).toDouble();
        
        // Si es segmentación, usar bounding box del polígono
        if (prediccion['points'] != null) {
          final points = (prediccion['points'] as List)
              .map((p) => (p['x'] as num, p['y'] as num))
              .toList();
          
          double minX = points.map((p) => p.$1).reduce((a, b) => a < b ? a : b).toDouble();
          double minY = points.map((p) => p.$2).reduce((a, b) => a < b ? a : b).toDouble();
          double maxX = points.map((p) => p.$1).reduce((a, b) => a > b ? a : b).toDouble();
          double maxY = points.map((p) => p.$2).reduce((a, b) => a > b ? a : b).toDouble();

          final color = _getColorForClass(clase);

          // Dibujar rectángulo
          img.drawRect(
            image,
            x1: minX.toInt(),
            y1: minY.toInt(),
            x2: maxX.toInt(),
            y2: maxY.toInt(),
            color: color,
            thickness: 4,
          );

          // Etiquetar
          final label = '${_translateClass(clase)} ${(confidence * 100).toStringAsFixed(0)}%';
          _drawLabel(image, label, minX.toInt(), minY.toInt(), color);
        }
        // Si es detección (x, y, width, height)
        else if (prediccion['x'] != null) {
          final double x = (prediccion['x'] ?? 0.0).toDouble();
          final double y = (prediccion['y'] ?? 0.0).toDouble();
          final double width = (prediccion['width'] ?? 0.0).toDouble();
          final double height = (prediccion['height'] ?? 0.0).toDouble();

          final int x1 = (x - width / 2).toInt();
          final int y1 = (y - height / 2).toInt();
          final int x2 = (x + width / 2).toInt();
          final int y2 = (y + height / 2).toInt();

          final color = _getColorForClass(clase);

          img.drawRect(
            image,
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            color: color,
            thickness: 4,
          );

          final label = '${_translateClass(clase)} ${(confidence * 100).toStringAsFixed(0)}%';
          _drawLabel(image, label, x1, y1, color);
        }
      }

      // Guardar temporalmente
      final directory = imagenOriginal.parent.path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'annotated_$timestamp.png';
      final annotatedFile = File('$directory/$filename');
      
      await annotatedFile.writeAsBytes(img.encodePng(image));
      return annotatedFile;
    } catch (e) {
      throw Exception('Error al crear imagen anotada: $e');
    }
  }

  /// Dibuja una etiqueta en la imagen
  void _drawLabel(img.Image image, String label, int x, int y, img.Color color) {
    // Fondo para la etiqueta
    img.fillRect(
      image,
      x1: x,
      y1: y - 25,
      x2: x + (label.length * 8),
      y2: y,
      color: color,
    );

    // Texto
    img.drawString(
      image,
      label,
      font: img.arial14,
      x: x + 2,
      y: y - 20,
      color: img.ColorRgb8(255, 255, 255),
    );
  }

  /// Sube ambas imágenes a Supabase Storage
  Future<Map<String, String>> subirImagenesProcesadas({
    required File imagenOriginal,
    required File imagenAnotada,
    required String edificacionId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Subir imagen original
      final originalFileName = 'edificaciones/$edificacionId/original_$timestamp.jpg';
      await _supabase.storage.from('imagenes').upload(
            originalFileName,
            imagenOriginal,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final originalUrl = _supabase.storage
          .from('imagenes')
          .getPublicUrl(originalFileName);

      // Subir imagen anotada
      final anotadaFileName = 'edificaciones/$edificacionId/annotated_$timestamp.png';
      await _supabase.storage.from('imagenes').upload(
            anotadaFileName,
            imagenAnotada,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      final anotadaUrl = _supabase.storage
          .from('imagenes')
          .getPublicUrl(anotadaFileName);

      return {
        'original_url': originalUrl,
        'anotada_url': anotadaUrl,
      };
    } catch (e) {
      throw Exception('Error al subir imágenes: $e');
    }
  }

  /// Proceso completo: Crea versión anotada y sube ambas
  /// USO: Cuando el profesional quiere guardar detecciones permanentes
  Future<Map<String, dynamic>> procesarYGuardarDetecciones({
    required File imagenOriginal,
    required String edificacionId,
    required Map<String, dynamic> deteccionesExistentes,
  }) async {
    try {
      // Crear imagen con anotaciones permanentes
      final imagenAnotada = await crearImagenAnotada(
        imagenOriginal: imagenOriginal,
        predicciones: deteccionesExistentes['predictions'] ?? [],
      );

      // Subir ambas imágenes
      final urls = await subirImagenesProcesadas(
        imagenOriginal: imagenOriginal,
        imagenAnotada: imagenAnotada,
        edificacionId: edificacionId,
      );

      return {
        'foto_original_url': urls['original_url'],
        'foto_anotada_url': urls['anotada_url'],
        'detecciones_ia': deteccionesExistentes,
      };
    } catch (e) {
      throw Exception('Error en procesamiento: $e');
    }
  }

  /// Obtiene color según la clase detectada
  img.Color _getColorForClass(String clase) {
    switch (clase.toLowerCase()) {
      case 'grieta':
      case 'grieta_diagonal':
      case 'grieta_horizontal':
      case 'grieta_vertical':
        return img.ColorRgb8(231, 76, 60); // Rojo
      case 'humedad':
        return img.ColorRgb8(52, 152, 219); // Azul
      case 'deformacion':
        return img.ColorRgb8(243, 156, 18); // Naranja
      case 'desprendimiento':
      case 'acero_expuesto':
        return img.ColorRgb8(155, 89, 182); // Púrpura
      case 'eflorescencia':
        return img.ColorRgb8(241, 196, 15); // Amarillo
      default:
        return img.ColorRgb8(46, 204, 113); // Verde
    }
  }

  /// Traduce nombre de clase al español
  String _translateClass(String clase) {
    switch (clase.toLowerCase()) {
      case 'grieta':
      case 'crack':
        return 'Grieta';
      case 'grieta_diagonal':
        return 'G.Diagonal';
      case 'grieta_horizontal':
        return 'G.Horizontal';
      case 'grieta_vertical':
        return 'G.Vertical';
      case 'humedad':
        return 'Humedad';
      case 'deformacion':
        return 'Deformación';
      case 'desprendimiento':
        return 'Desprendimiento';
      case 'acero_expuesto':
        return 'Acero Exp.';
      case 'eflorescencia':
        return 'Eflorescencia';
      default:
        return clase;
    }
  }

  /// Sube foto de perfil de usuario a Supabase Storage
  Future<String> subirFotoPerfil({
    required File imagen,
    required String userId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'perfiles/$userId/profile_$timestamp.jpg';
      
      // Comprimir imagen antes de subir
      final imageBytes = await imagen.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      
      if (decodedImage == null) {
        throw Exception('No se pudo decodificar la imagen');
      }
      
      // Redimensionar a 500x500 máximo manteniendo proporción
      final resizedImage = img.copyResize(
        decodedImage,
        width: 500,
        height: 500,
        interpolation: img.Interpolation.average,
      );
      
      // Codificar como JPEG con calidad 85%
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      
      // Subir a Supabase Storage
      await _supabase.storage.from('imagenes').uploadBinary(
            fileName,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Retornar URL pública
      final publicUrl = _supabase.storage
          .from('imagenes')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir foto de perfil: $e');
    }
  }
}
