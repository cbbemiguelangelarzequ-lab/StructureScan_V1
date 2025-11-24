// lib/models/solicitud_revision.dart
// Modelo de datos para solicitudes de revisión profesional

import 'edificacion.dart'; // Para NivelRiesgo

class SolicitudRevision {
  final String? id;
  final String idEdificacion;
  final String idPropietario;
  final String? idProfesional;

  // Resumen de la Solicitud
  final String sintomaPrincipal;
  final String descripcionBreve;
  final NivelRiesgo nivelRiesgo;

  // Estado de Seguimiento
  final EstadoSolicitud estado;

  // Respuesta del Profesional
  final String? respuestaPreliminar;
  final DateTime? fechaVisitaProgramada;

  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SolicitudRevision({
    this.id,
    required this.idEdificacion,
    required this.idPropietario,
    this.idProfesional,
    required this.sintomaPrincipal,
    required this.descripcionBreve,
    required this.nivelRiesgo,
    this.estado = EstadoSolicitud.pendiente,
    this.respuestaPreliminar,
    this.fechaVisitaProgramada,
    this.createdAt,
    this.updatedAt,
  });

  // Convertir desde JSON (Supabase)
  factory SolicitudRevision.fromJson(Map<String, dynamic> json) {
    return SolicitudRevision(
      id: json['id'] as String?,
      idEdificacion: json['id_edificacion'] as String,
      idPropietario: json['id_propietario'] as String,
      idProfesional: json['id_profesional'] as String?,
      sintomaPrincipal: json['sintoma_principal'] as String,
      descripcionBreve: json['descripcion_breve'] as String,
      nivelRiesgo: NivelRiesgo.fromString(json['nivel_riesgo'] as String),
      estado: EstadoSolicitud.fromString(json['estado'] as String),
      respuestaPreliminar: json['respuesta_preliminar'] as String?,
      fechaVisitaProgramada: json['fecha_visita_programada'] != null
          ? DateTime.parse(json['fecha_visita_programada'] as String)
          : null,
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
      'id_edificacion': idEdificacion,
      'id_propietario': idPropietario,
      if (idProfesional != null) 'id_profesional': idProfesional,
      'sintoma_principal': sintomaPrincipal,
      'descripcion_breve': descripcionBreve,
      'nivel_riesgo': nivelRiesgo.value,
      'estado': estado.value,
      if (respuestaPreliminar != null)
        'respuesta_preliminar': respuestaPreliminar,
      if (fechaVisitaProgramada != null)
        'fecha_visita_programada': fechaVisitaProgramada!.toIso8601String(),
    };
  }

  SolicitudRevision copyWith({
    String? id,
    String? idEdificacion,
    String? idPropietario,
    String? idProfesional,
    String? sintomaPrincipal,
    String? descripcionBreve,
    NivelRiesgo? nivelRiesgo,
    EstadoSolicitud? estado,
    String? respuestaPreliminar,
    DateTime? fechaVisitaProgramada,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SolicitudRevision(
      id: id ?? this.id,
      idEdificacion: idEdificacion ?? this.idEdificacion,
      idPropietario: idPropietario ?? this.idPropietario,
      idProfesional: idProfesional ?? this.idProfesional,
      sintomaPrincipal: sintomaPrincipal ?? this.sintomaPrincipal,
      descripcionBreve: descripcionBreve ?? this.descripcionBreve,
      nivelRiesgo: nivelRiesgo ?? this.nivelRiesgo,
      estado: estado ?? this.estado,
      respuestaPreliminar: respuestaPreliminar ?? this.respuestaPreliminar,
      fechaVisitaProgramada:
          fechaVisitaProgramada ?? this.fechaVisitaProgramada,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Enum para Estado de Solicitud
enum EstadoSolicitud {
  pendiente('pendiente', 'Pendiente', 'Esperando revisión del profesional'),
  enRevision(
      'en_revision', 'En Revisión', 'El profesional está evaluando la solicitud'),
  programada('programada', 'Visita Programada', 'Visita técnica agendada'),
  completada('completada', 'Completada', 'Informe técnico generado'),
  rechazada('rechazada', 'Rechazada', 'No requiere intervención estructural');

  final String value;
  final String displayName;
  final String description;

  const EstadoSolicitud(this.value, this.displayName, this.description);

  static EstadoSolicitud fromString(String value) {
    return EstadoSolicitud.values.firstWhere((e) => e.value == value);
  }
}
