// lib/models/anamnesis.dart
// Modelo de datos para anamnesis (Fase C: Historia y Evolución)

class Anamnesis {
  final String? id;
  final String idEdificacion;

  // Timeline
  final CuandoDescubrio cuandoDescubrio;

  // Comportamiento
  final ComportamientoDanio comportamiento;

  // Factores Detonantes
  final List<FactorDetonante> factoresDetonantes;

  // Observaciones Sensoriales
  final bool tieneRuidos;
  final String? descripcionRuidos;
  final bool tieneVibraciones;
  final String? descripcionVibraciones;

  final DateTime? createdAt;

  Anamnesis({
    this.id,
    required this.idEdificacion,
    required this.cuandoDescubrio,
    required this.comportamiento,
    required this.factoresDetonantes,
    this.tieneRuidos = false,
    this.descripcionRuidos,
    this.tieneVibraciones = false,
    this.descripcionVibraciones,
    this.createdAt,
  });

  // Convertir desde JSON (Supabase)
  factory Anamnesis.fromJson(Map<String, dynamic> json) {
    return Anamnesis(
      id: json['id'] as String?,
      idEdificacion: json['id_edificacion'] as String,
      cuandoDescubrio:
          CuandoDescubrio.fromString(json['cuando_descubrio'] as String),
      comportamiento:
          ComportamientoDanio.fromString(json['comportamiento'] as String),
      factoresDetonantes: json['factores_detonantes'] != null
          ? (json['factores_detonantes'] as List)
              .map((e) => FactorDetonante.fromString(e as String))
              .toList()
          : [],
      tieneRuidos: json['tiene_ruidos'] as bool? ?? false,
      descripcionRuidos: json['descripcion_ruidos'] as String?,
      tieneVibraciones: json['tiene_vibraciones'] as bool? ?? false,
      descripcionVibraciones: json['descripcion_vibraciones'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_edificacion': idEdificacion,
      'cuando_descubrio': cuandoDescubrio.value,
      'comportamiento': comportamiento.value,
      'factores_detonantes': factoresDetonantes.map((e) => e.value).toList(),
      'tiene_ruidos': tieneRuidos,
      if (descripcionRuidos != null) 'descripcion_ruidos': descripcionRuidos,
      'tiene_vibraciones': tieneVibraciones,
      if (descripcionVibraciones != null)
        'descripcion_vibraciones': descripcionVibraciones,
    };
  }
}

// Enum para Cuándo Descubrió el Daño
enum CuandoDescubrio {
  ayerHaceDias('ayer_hace_dias', 'Ayer / Hoy'),
  haceSemanas('hace_semanas', 'Hace menos de 1 semana'),
  haceMeses('hace_meses', 'Hace menos de 1 mes'),
  hace1Anio('hace_1_anio', 'Hace 6 meses'),
  haceVariosAnios('hace_varios_anios', 'Hace varios años'),
  desdeSiempre('desde_siempre', 'Siempre ha estado ahí (años)');

  final String value;
  final String displayName;

  const CuandoDescubrio(this.value, this.displayName);

  static CuandoDescubrio fromString(String value) {
    return CuandoDescubrio.values.firstWhere((e) => e.value == value);
  }
}

// Enum para Comportamiento del Daño
enum ComportamientoDanio {
  estatico('estatico', 'Está estático (igual)', '🟢 Baja urgencia'),
  crecimientoLento('crecimiento_lento', 'Crece lentamente', '🟡 Monitorear'),
  crecimientoRapido(
      'crecimiento_rapido', 'Crece RÁPIDO (día a día)', '🔴 URGENTE'),
  ciclicoEstacional('ciclico_estacional', 'Aparece y desaparece (cíclico)',
      'Usualmente humedad estacional');

  final String value;
  final String displayName;
  final String interpretacion;

  const ComportamientoDanio(this.value, this.displayName, this.interpretacion);

  static ComportamientoDanio fromString(String value) {
    return ComportamientoDanio.values.firstWhere((e) => e.value == value);
  }
}

// Enum para Factores Detonantes
enum FactorDetonante {
  sismo('sismo', 'Sismo / Temblor', '🔴 Alerta prioritaria'),
  lluvias('lluvias', 'Lluvias intensas', 'Verificar impermeabilización'),
  construccionVecino('construccion_vecino', 'Construcción u excavación en el vecino',
      'Posible asentamiento'),
  camiones('camiones', 'Paso de camiones pesados', 'Vibración constante'),
  fugaAgua('fuga_agua', 'Fuga de agua / Reparación sanitaria',
      'Posible erosión de cimiento'),
  ninguno('ninguno', 'No pasó nada en particular', 'Deterioro gradual');

  final String value;
  final String displayName;
  final String interpretacion;

  const FactorDetonante(this.value, this.displayName, this.interpretacion);

  static FactorDetonante fromString(String value) {
    return FactorDetonante.values.firstWhere((e) => e.value == value);
  }
}
