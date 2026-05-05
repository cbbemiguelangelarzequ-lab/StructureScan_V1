// lib/services/share_service.dart
// Servicio para compartir informes en redes sociales

import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// Comparte por WhatsApp
  Future<void> compartirWhatsApp(String mensaje, String? pdfPath) async {
    if (pdfPath != null) {
      await Share.shareXFiles(
        [XFile(pdfPath)],
        text: mensaje,
        subject: 'Informe Técnico - StructureScan',
      );
    } else {
      await Share.share(
        mensaje,
        subject: 'Informe Técnico - StructureScan',
      );
    }
  }

  /// Comparte por Email
  Future<void> compartirEmail(String asunto, String cuerpo, String? pdfPath) async {
    if (pdfPath != null) {
      await Share.shareXFiles(
        [XFile(pdfPath)],
        text: cuerpo,
        subject: asunto,
      );
    } else {
      await Share.share(
        cuerpo,
        subject: asunto,
      );
    }
  }

  /// Compartir genérico (abre el menú nativo de compartir)
  Future<void> compartirGenerico(String mensaje, String? pdfPath) async {
    if (pdfPath != null) {
      final result = await Share.shareXFiles(
        [XFile(pdfPath)],
        text: mensaje,
        subject: 'Informe Técnico Estructural',
      );

      // Opcional: manejar el resultado
      if (result.status == ShareResultStatus.success) {
        print('Compartido exitosamente');
      }
    } else {
      await Share.share(
        mensaje,
        subject: 'Informe Técnico Estructural',
      );
    }
  }

  /// Comparte solo texto (para links públicos)
  Future<void> compartirLink(String url, String mensaje) async {
    await Share.share(
      '$mensaje\n\n$url',
      subject: 'Informe Técnico - StructureScan',
    );
  }
}
