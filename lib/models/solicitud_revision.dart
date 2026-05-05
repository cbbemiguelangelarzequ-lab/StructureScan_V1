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

  // Tipo de Servicio
  final TipoServicio? tipoServicio;
  final double? costoAcordado;

  // Respuesta del Profesional
  final String? notaProfesional;
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
    this.tipoServicio,
    this.costoAcordado,
    this.estado = EstadoSolicitud.pendiente,
    this.notaProfesional,
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
      tipoServicio: json['tipo_servicio'] != null
          ? TipoServicio.fromString(json['tipo_servicio'] as String)
          : null,
      costoAcordado: json['costo_acordado'] != null
          ? (json['costo_acordado'] as num).toDouble()
          : null,
      estado: EstadoSolicitud.fromString(json['estado'] as String),
      notaProfesional: json['nota_profesional'] as String?,
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
      if (tipoServicio != null) 'tipo_servicio': tipoServicio!.value,
      if (costoAcordado != null) 'costo_acordado': costoAcordado,
      'estado': estado.value,
      if (notaProfesional != null)
        'nota_profesional': notaProfesional,
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
    TipoServicio? tipoServicio,
    double? costoAcordado,
    EstadoSolicitud? estado,
    String? notaProfesional,
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
      tipoServicio: tipoServicio ?? this.tipoServicio,
      costoAcordado: costoAcordado ?? this.costoAcordado,
      estado: estado ?? this.estado,
      notaProfesional: notaProfesional ?? this.notaProfesional,
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
  descartada('descartada', 'Descartada', 'No requiere intervención estructural'),
  rechazada('rechazada', 'Rechazada', 'No requiere intervención estructural'); // Mantener por compatibilidad

  final String value;
  final String displayName;
  final String description;

  const EstadoSolicitud(this.value, this.displayName, this.description);

  static EstadoSolicitud fromString(String value) {
    return EstadoSolicitud.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoSolicitud.pendiente, // Valor por defecto si no se encuentra
    );
  }
}

// Enum para Tipo de Servicio
enum TipoServicio {
  consejoRapido('consejo_rapido', 'Consejo Rápido', 'Sin visita técnica'),
  visitaTecnica('visita_tecnica', 'Visita Técnica', 'Inspección en sitio');

  final String value;
  final String displayName;
  final String description;

  const TipoServicio(this.value, this.displayName, this.description);

  static TipoServicio fromString(String value) {
    return TipoServicio.values.firstWhere((e) => e.value == value);
  }
}
