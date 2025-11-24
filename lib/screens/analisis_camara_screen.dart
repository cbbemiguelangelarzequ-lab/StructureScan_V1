// lib/screens/analisis_camara_screen.dart
// Pantalla de análisis de cámara con IA integrada al flujo de síntomas

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';

// Función de ayuda para los colores de las clases detectadas
Color getClassColor(String clase) {
  switch (clase) {
    case 'acero_expuesto':
      return Colors.cyan;
    case 'desprendimiento':
      return Colors.pink;
    case 'eflorescencia':
      return Colors.orange;
    case 'grieta':
      return Colors.lime;
    case 'humedad':
      return Colors.purple;
    default:
      return Colors.red;
  }
}

class AnalisisCamaraScreen extends StatefulWidget {
  final String edificacionId; // Vinculamos al edificio
  final String? sintomaId; // Opcional: si ya existe un síntoma específico

  const AnalisisCamaraScreen({
    super.key,
    required this.edificacionId,
    this.sintomaId,
  });

  @override
  State<AnalisisCamaraScreen> createState() => _AnalisisCamaraScreenState();
}

class _AnalisisCamaraScreenState extends State<AnalisisCamaraScreen> {
  bool _estaCargando = false;
  File? _imagenCapturada;
  List<dynamic> _detections = [];
  String _error = "";
  Size _imageSize = Size.zero;
  String? _urlImagenGuardada; // URL de la imagen guardada en Supabase

  Future<void> _capturarYAnalizar() async {
    final picker = ImagePicker();

    // 1. Captura de imagen (optimizada para Roboflow 640x640)
    final XFile? foto = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 90,
    );

    if (foto == null) return;
    final archivoImagen = File(foto.path);

    // 2. Obtener tamaño real para escalar correctamente los polígonos
    final decodedImage = await decodeImageFromList(
      archivoImagen.readAsBytesSync(),
    );
    _imageSize = Size(
      decodedImage.width.toDouble(),
      decodedImage.height.toDouble(),
    );

    setState(() {
      _estaCargando = true;
      _imagenCapturada = archivoImagen;
      _detections = [];
      _error = "";
    });

    try {
      // 3. Análisis con Roboflow (Segmentación)
      final jsonRoboflow = await _getRoboflowSegmentation(archivoImagen);

      // 4. Guardado en Supabase (solo la imagen, detections se muestran pero no se guardan aún)
      final urlImagen = await _subirImagenASupabase(archivoImagen);

      setState(() {
        _estaCargando = false;
        _detections = jsonRoboflow['predictions'] ?? [];
        _urlImagenGuardada = urlImagen;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Foto capturada. ${_detections.length} patología(s) detectada(s)',
            ),
            backgroundColor: kVerdeExito,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
      setState(() {
        _estaCargando = false;
        _error = e.toString();
      });
    }
  }

  Future<Map<String, dynamic>> _getRoboflowSegmentation(File imageFile) async {
    final String? kApiKey = dotenv.env['ROBOFLOW_API_KEY'];
    final String? kModelId = dotenv.env['ROBOFLOW_MODEL_ID'];

    if (kApiKey == null || kModelId == null) {
      throw Exception(
        'Falta configurar ROBOFLOW_API_KEY o ROBOFLOW_MODEL_ID en .env',
      );
    }

    final baseUrl = "https://detect.roboflow.com/$kModelId";
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final url = Uri.parse(
      "$baseUrl?api_key=$kApiKey&format=json&confidence=40",
    );

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Content-Length": base64Image.length.toString(),
      },
      body: base64Image,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error Roboflow (${res.statusCode}): ${res.body}");
    }
  }

  Future<String> _subirImagenASupabase(File imagen) async {
    try {
      final fileExt = imagen.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = 'edificaciones/${widget.edificacionId}/$fileName';

      await Supabase.instance.client.storage.from('imagenes').upload(storagePath, imagen);
      final urlPublica = Supabase.instance.client.storage.from('imagenes').getPublicUrl(
            storagePath,
          );

      return urlPublica;
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      throw Exception("Error al subir imagen: $e");
    }
  }

  Future<void> _guardarYContinuar() async {
    if (_urlImagenGuardada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes capturar una foto'),
          backgroundColor: kNaranjaAcento,
        ),
      );
      return;
    }

    // Volver a la pantalla anterior con la URL de la imagen
    if (mounted) {
      Navigator.of(context).pop(_urlImagenGuardada);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escáner Estructural IA"),
        backgroundColor: kAzulPrincipalOscuro,
        actions: [
          if (_urlImagenGuardada != null)
            IconButton(
              icon: const Icon(Icons.check, color: kVerdeExito),
              onPressed: _guardarYContinuar,
              tooltip: 'Guardar y continuar',
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _buildContenido(),
      floatingActionButton: FloatingActionButton(
        onPressed: _capturarYAnalizar,
        backgroundColor: kNaranjaAcento,
        child: _estaCargando
            ? const CircularProgressIndicator(color: kBlanco)
            : const Icon(Icons.camera_alt, color: kBlanco),
      ),
    );
  }

  Widget _buildContenido() {
    if (_imagenCapturada == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 100,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              "Presiona el botón de cámara\npara capturar y analizar",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: kRojoAdvertencia, size: 64),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Error: $_error",
                style: const TextStyle(color: kRojoAdvertencia),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                _error = "";
                _imagenCapturada = null;
              }),
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Banner de información
        if (_detections.isNotEmpty)
          Container(
            color: kVerdeExito.withOpacity(0.2),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: kVerdeExito),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_detections.length} patología(s) detectada(s) por la IA',
                    style: const TextStyle(
                      color: kVerdeExito,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Imagen con detecciones
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _imageSize.width,
                      height: _imageSize.height,
                      child: Stack(
                        children: [
                          Image.file(_imagenCapturada!, fit: BoxFit.fill),
                          if (_detections.isNotEmpty)
                            ..._buildInteractiveMasks(_detections, _imageSize),
                        ],
                      ),
                    ),
                  ),
                  if (_estaCargando)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: kNaranjaAcento),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Botón de guardar
        if (_urlImagenGuardada != null)
          Container(
            color: kAzulPrincipalOscuro,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardarYContinuar,
                icon: const Icon(Icons.check),
                label: const Text('Guardar Foto y Continuar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kVerdeExito,
                  foregroundColor: kBlanco,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildInteractiveMasks(
    List<dynamic> detections,
    Size originalSize,
  ) {
    return detections.map((det) {
      final List<Offset> points = (det['points'] as List).map((p) {
        return Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble());
      }).toList();

      final String clase = det['class'];
      final double conf = det['confidence'] * 100;
      final color = getClassColor(clase);

      Offset topPoint = points.reduce(
        (curr, next) => curr.dy < next.dy ? curr : next,
      );

      return Stack(
        children: [
          CustomPaint(
            size: originalSize,
            painter: SegmentationPainter(points: points, color: color),
          ),
          Positioned(
            left: topPoint.dx - 20,
            top: topPoint.dy - 20,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(
                      clase.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Confianza: ${conf.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          "La IA detectó esta patología basándose en el patrón visual de la imagen.",
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Entendido"),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(
                  Icons.touch_app,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}

// --- PINTOR DE POLÍGONOS ---
class SegmentationPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  SegmentationPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 3) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    final fillPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant SegmentationPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
