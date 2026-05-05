// lib/models/informe_tecnico.dart
// Modelo de datos para informes técnicos generados por profesionales

class InformeTecnico {
  final String? id;
  final String idSolicitud;
  final String idProfesional;
  
  // Contenido del informe
  final String contenidoMarkdown;
  final String conclusionFinal;
  
  // Evaluación
  final bool esHabitable;
  final bool requiereRefuerzo;
  
  // PDF y compartir
  final String? pdfUrl;
  final List<String>? compartidoEn; // ['whatsapp', 'facebook', 'email']
  
  // Firma y metadata
  final String? firmaProfesional;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InformeTecnico({
    this.id,
    required this.idSolicitud,
    required this.idProfesional,
    required this.contenidoMarkdown,
    required this.conclusionFinal,
    this.esHabitable = true,
    this.requiereRefuerzo = false,
    this.pdfUrl,
    this.compartidoEn,
    this.firmaProfesional,
    this.createdAt,
    this.updatedAt,
  });

  // Convertir desde JSON (Supabase)
  factory InformeTecnico.fromJson(Map<String, dynamic> json) {
    return InformeTecnico(
      id: json['id'] as String?,
      idSolicitud: json['id_solicitud'] as String,
      idProfesional: json['id_profesional'] as String,
      contenidoMarkdown: json['contenido_markdown'] as String,
      conclusionFinal: json['conclusion_final'] as String,
      esHabitable: json['es_habitable'] as bool? ?? true,
      requiereRefuerzo: json['requiere_refuerzo'] as bool? ?? false,
      pdfUrl: json['pdf_url'] as String?,
      compartidoEn: json['compartido_en'] != null
          ? List<String>.from(json['compartido_en'] as List)
          : null,
      firmaProfesional: json['firma_profesional'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_solicitud': idSolicitud,
      'id_profesional': idProfesional,
      'contenido_markdown': contenidoMarkdown,
      'conclusion_final': conclusionFinal,
      'es_habitable': esHabitable,
      'requiere_refuerzo': requiereRefuerzo,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      if (compartidoEn != null) 'compartido_en': compartidoEn,
      if (firmaProfesional != null) 'firma_profesional': firmaProfesional,
    };
  }

  InformeTecnico copyWith({
    String? id,
    String? idSolicitud,
    String? idProfesional,
    String? contenidoMarkdown,
    String? conclusionFinal,
    bool? esHabitable,
    bool? requiereRefuerzo,
    String? pdfUrl,
    List<String>? compartidoEn,
    String? firmaProfesional,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InformeTecnico(
      id: id ?? this.id,
      idSolicitud: idSolicitud ?? this.idSolicitud,
      idProfesional: idProfesional ?? this.idProfesional,
      contenidoMarkdown: contenidoMarkdown ?? this.contenidoMarkdown,
      conclusionFinal: conclusionFinal ?? this.conclusionFinal,
      esHabitable: esHabitable ?? this.esHabitable,
      requiereRefuerzo: requiereRefuerzo ?? this.requiereRefuerzo,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      compartidoEn: compartidoEn ?? this.compartidoEn,
      firmaProfesional: firmaProfesional ?? this.firmaProfesional,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
