// lib/models/hallazgo_profesional.dart
// Modelo de datos para hallazgos profesionales

class HallazgoProfesional {
  final String? id;
  final String idSolicitud;
  final String idProfesional;

  // Clasificación Técnica
  final ClasificacionTecnica clasificacionTecnica;
  final NivelSeveridad severidad;

  // Hallazgos
  final String? notasTecnicas;
  final List<String>? fotosProfesionales;

  // Recomendaciones
  final String? recomendaciones;
  final bool requiereEvacuacion;

  final DateTime? createdAt;

  HallazgoProfesional({
    this.id,
    required this.idSolicitud,
    required this.idProfesional,
    required this.clasificacionTecnica,
    required this.severidad,
    this.notasTecnicas,
    this.fotosProfesionales,
    this.recomendaciones,
    this.requiereEvacuacion = false,
    this.createdAt,
  });

  // Convertir desde JSON (Supabase)
  factory HallazgoProfesional.fromJson(Map<String, dynamic> json) {
    return HallazgoProfesional(
      id: json['id'] as String?,
      idSolicitud: json['id_solicitud'] as String,
      idProfesional: json['id_profesional'] as String,
      clasificacionTecnica: ClasificacionTecnica.fromString(
          json['clasificacion_tecnica'] as String),
      severidad:
          NivelSeveridad.fromString(json['severidad'] as String),
      notasTecnicas: json['notas_tecnicas'] as String?,
      fotosProfesionales: json['fotos_profesionales'] != null
          ? List<String>.from(json['fotos_profesionales'])
          : null,
      recomendaciones: json['recomendaciones'] as String?,
      requiereEvacuacion: json['requiere_evacuacion'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_solicitud': idSolicitud,
      'id_profesional': idProfesional,
      'clasificacion_tecnica': clasificacionTecnica.value,
      'severidad': severidad.value,
      if (notasTecnicas != null) 'notas_tecnicas': notasTecnicas,
      if (fotosProfesionales != null) 'fotos_profesionales': fotosProfesionales,
      if (recomendaciones != null) 'recomendaciones': recomendaciones,
      'requiere_evacuacion': requiereEvacuacion,
    };
  }
}

// Enum para Clasificación Técnica (DEBE coincidir con BD)
enum ClasificacionTecnica {
  fallaPorCorte('falla_por_corte', 'Falla por Corte',
      'Grietas diagonales por esfuerzos de corte'),
  asentamientoDiferencial('asentamiento_diferencial',
      'Asentamiento Diferencial', 'Hundimiento desigual del terreno'),
  patologiaHumedad('patologia_humedad', 'Patología por Humedad',
      'Daños estructurales causados por humedad'),
  deterioroMateriales('deterioro_materiales', 'Deterioro de Materiales',
      'Degradación de elementos constructivos'),
  deficienciaEstructural('deficiencia_estructural', 'Deficiencia Estructural',
      'Problemas en el diseño o construcción estructural'),
  sobrecarga('sobrecarga', 'Sobrecarga',
      'Exceso de carga sobre elementos estructurales'),
  fallaCimentacion('falla_cimentacion', 'Falla en Cimentación',
      'Problemas en la base de la estructura'),
  otros('otros', 'Otros', 'Otros hallazgos técnicos');

  final String value;
  final String displayName;
  final String description;

  const ClasificacionTecnica(this.value, this.displayName, this.description);

  static ClasificacionTecnica fromString(String value) {
    return ClasificacionTecnica.values.firstWhere((e) => e.value == value);
  }
}

// Enum para Nivel de Severidad
enum NivelSeveridad {
  superficial('superficial', 'Superficial', 'No compromete seguridad estructural'),
  moderado('moderado', 'Moderado', 'Requiere monitoreo y reparación programada'),
  severo('severo', 'Severo', 'Requiere intervención inmediata'),
  critico('critico', 'Crítico', '🔴 PELIGRO: Riesgo de colapso inminente');

  final String value;
  final String displayName;
  final String description;

  const NivelSeveridad(this.value, this.displayName, this.description);

  static NivelSeveridad fromString(String value) {
    return NivelSeveridad.values.firstWhere((e) => e.value == value);
  }
}
