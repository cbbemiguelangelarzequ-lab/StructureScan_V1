// lib/models/hallazgo_profesional.dart
// Modelo de datos para hallazgos profesionales

class HallazgoProfesional {
  final String? id;
  final String idSolicitud;
  final String idProfesional;

  // Clasificación Técnica
  final ClasificacionTecnica clasificacionTecnica;
  final NivelSeveridad nivelSeveridad;

  // Hallazgos
  final String? notasTexto;
  final String? notasVozUrl; // Future: transcripción de voz

  // Mapeo Estructural (vinculado al sistema niveles/zonas existente)
  final String? idZona;
  final String? elementoEstructural; // ej: "Columna C-4", "Viga V-102"

  // Recomendaciones
  final String? recomendacionResumen;
  final bool requiereRefuerzo;
  final bool esHabitable;

  final DateTime? createdAt;

  HallazgoProfesional({
    this.id,
    required this.idSolicitud,
    required this.idProfesional,
    required this.clasificacionTecnica,
    required this.nivelSeveridad,
    this.notasTexto,
    this.notasVozUrl,
    this.idZona,
    this.elementoEstructural,
    this.recomendacionResumen,
    this.requiereRefuerzo = false,
    this.esHabitable = true,
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
      nivelSeveridad:
          NivelSeveridad.fromString(json['nivel_severidad'] as String),
      notasTexto: json['notas_texto'] as String?,
      notasVozUrl: json['notas_voz_url'] as String?,
      idZona: json['id_zona'] as String?,
      elementoEstructural: json['elemento_estructural'] as String?,
      recomendacionResumen: json['recomendacion_resumen'] as String?,
      requiereRefuerzo: json['requiere_refuerzo'] as bool? ?? false,
      esHabitable: json['es_habitable'] as bool? ?? true,
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
      'nivel_severidad': nivelSeveridad.value,
      if (notasTexto != null) 'notas_texto': notasTexto,
      if (notasVozUrl != null) 'notas_voz_url': notasVozUrl,
      if (idZona != null) 'id_zona': idZona,
      if (elementoEstructural != null)
        'elemento_estructural': elementoEstructural,
      if (recomendacionResumen != null)
        'recomendacion_resumen': recomendacionResumen,
      'requiere_refuerzo': requiereRefuerzo,
      'es_habitable': esHabitable,
    };
  }
}

// Enum para Clasificación Técnica
enum ClasificacionTecnica {
  fallaPorCorte('falla_por_corte', 'Falla por Corte',
      'Grietas diagonales por esfuerzos de corte'),
  asentamientoDiferencial('asentamiento_diferencial',
      'Asentamiento Diferencial', 'Hundimiento desigual del terreno'),
  pandeoColumna(
      'pandeo_columna', 'Pandeo de Columna', 'Deformación lateral de columna'),
  corrosionAcero('corrosion', 'Corrosión de Acero',
      'Deterioro del refuerzo por oxidación'),
  humedadFiltracion('humedad_filtracion', 'Humedad por Filtración',
      'Ingreso de agua comprometiendo estructura'),
  eflorescencia('eflorescencia', 'Eflorescencia',
      'Sales en superficie, posible problema de humedad'),
  desprendimientoTarrajeo('desprendimiento_tarrajeo',
      'Desprendimiento de Tarrajeo', 'Pérdida de recubrimiento superficial'),
  deterioroGeneral(
      'deterioro_general', 'Deterioro General', 'Envejecimiento natural');

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
  leve('leve', 'Leve', 'No compromete seguridad estructural'),
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
