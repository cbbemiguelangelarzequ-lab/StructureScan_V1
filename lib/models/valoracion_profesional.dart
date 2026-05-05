// lib/models/valoracion_profesional.dart
// Modelo de datos para valoraciones de profesionales

class ValoracionProfesional {
  final String? id;
  final String idProfesional;
  final String idPropietario;
  final String idSolicitud;
  final int calificacion; // 1-5
  final String? comentario;
  final DateTime? createdAt;

  ValoracionProfesional({
    this.id,
    required this.idProfesional,
    required this.idPropietario,
    required this.idSolicitud,
    required this.calificacion,
    this.comentario,
    this.createdAt,
  });

  // Convertir desde JSON (Supabase)
  factory ValoracionProfesional.fromJson(Map<String, dynamic> json) {
    return ValoracionProfesional(
      id: json['id'] as String?,
      idProfesional: json['id_profesional'] as String,
      idPropietario: json['id_propietario'] as String,
      idSolicitud: json['id_solicitud'] as String,
      calificacion: json['calificacion'] as int,
      comentario: json['comentario'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_profesional': idProfesional,
      'id_propietario': idPropietario,
      'id_solicitud': idSolicitud,
      'calificacion': calificacion,
      if (comentario != null) 'comentario': comentario,
    };
  }

  // Para facilitar comparaciones y debugging
  @override
  String toString() {
    return 'ValoracionProfesional{id: $id, profesional: $idProfesional, calificacion: $calificacion}';
  }
}
