// lib/models/edificacion.dart
// Modelo de datos para el perfil de edificación (Fase A: Perfil de Vulnerabilidad)

class Edificacion {
  final String? id;
  final String idUsuario;
  final String nombreEdificacion;
  final String? direccion;
  final double? latitud;
  final double? longitud;

  // Datos de Vulnerabilidad (Fase A)
  final TipoMaterial tipoMaterial;
  final TipoTecho tipoTecho;
  final FormaGeometrica formaGeometrica;
  final TipoSuelo tipoSuelo;
  final TipoConstruccion tipoConstruccion;
  final bool haTenidoModificaciones;
  final String? descripcionModificaciones;

  // Metadata
  final NivelRiesgo? riesgoCalculado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Edificacion({
    this.id,
    required this.idUsuario,
    required this.nombreEdificacion,
    this.direccion,
    this.latitud,
    this.longitud,
    required this.tipoMaterial,
    required this.tipoTecho,
    required this.formaGeometrica,
    required this.tipoSuelo,
    required this.tipoConstruccion,
    this.haTenidoModificaciones = false,
    this.descripcionModificaciones,
    this.riesgoCalculado,
    this.createdAt,
    this.updatedAt,
  });

  // Convertir desde JSON (Supabase)
  factory Edificacion.fromJson(Map<String, dynamic> json) {
    return Edificacion(
      id: json['id'] as String?,
      idUsuario: json['id_usuario'] as String,
      nombreEdificacion: json['nombre_edificacion'] as String,
      direccion: json['direccion'] as String?,
      latitud: json['latitud'] as double?,
      longitud: json['longitud'] as double?,
      tipoMaterial: TipoMaterial.fromString(json['tipo_material'] as String),
      tipoTecho: TipoTecho.fromString(json['tipo_techo'] as String),
      formaGeometrica:
          FormaGeometrica.fromString(json['forma_geometrica'] as String),
      tipoSuelo: TipoSuelo.fromString(json['tipo_suelo'] as String),
      tipoConstruccion:
          TipoConstruccion.fromString(json['tipo_construccion'] as String),
      haTenidoModificaciones: json['ha_tenido_modificaciones'] as bool? ?? false,
      descripcionModificaciones: json['descripcion_modificaciones'] as String?,
      riesgoCalculado: json['riesgo_calculado'] != null
          ? NivelRiesgo.fromString(json['riesgo_calculado'] as String)
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
      'id_usuario': idUsuario,
      'nombre_edificacion': nombreEdificacion,
      if (direccion != null) 'direccion': direccion,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      'tipo_material': tipoMaterial.value,
      'tipo_techo': tipoTecho.value,
      'forma_geometrica': formaGeometrica.value,
      'tipo_suelo': tipoSuelo.value,
      'tipo_construccion': tipoConstruccion.value,
      'ha_tenido_modificaciones': haTenidoModificaciones,
      if (descripcionModificaciones != null)
        'descripcion_modificaciones': descripcionModificaciones,
      if (riesgoCalculado != null) 'riesgo_calculado': riesgoCalculado!.value,
    };
  }

  Edificacion copyWith({
    String? id,
    String? idUsuario,
    String? nombreEdificacion,
    String? direccion,
    double? latitud,
    double? longitud,
    TipoMaterial? tipoMaterial,
    TipoTecho? tipoTecho,
    FormaGeometrica? formaGeometrica,
    TipoSuelo? tipoSuelo,
    TipoConstruccion? tipoConstruccion,
    bool? haTenidoModificaciones,
    String? descripcionModificaciones,
    NivelRiesgo? riesgoCalculado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Edificacion(
      id: id ?? this.id,
      idUsuario: idUsuario ?? this.idUsuario,
      nombreEdificacion: nombreEdificacion ?? this.nombreEdificacion,
      direccion: direccion ?? this.direccion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      tipoMaterial: tipoMaterial ?? this.tipoMaterial,
      tipoTecho: tipoTecho ?? this.tipoTecho,
      formaGeometrica: formaGeometrica ?? this.formaGeometrica,
      tipoSuelo: tipoSuelo ?? this.tipoSuelo,
      tipoConstruccion: tipoConstruccion ?? this.tipoConstruccion,
      haTenidoModificaciones:
          haTenidoModificaciones ?? this.haTenidoModificaciones,
      descripcionModificaciones:
          descripcionModificaciones ?? this.descripcionModificaciones,
      riesgoCalculado: riesgoCalculado ?? this.riesgoCalculado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Enums para Tipo de Material
enum TipoMaterial {
  ladrilloConcreto('ladrillo_concreto', 'Ladrillo y Concreto',
      'Albañilería confinada o armada'),
  adobeBahareque('adobe_bahareque', 'Adobe / Bahareque', 'Material tradicional de tierra'),
  madera('madera', 'Madera', 'Estructura de madera'),
  concretoReforzado('concreto_reforzado', 'Concreto Reforzado',
      'Columnas y vigas de concreto'),
  mixtoOtro('mixto_otro', 'Mixto / Otro', 'Combinación de materiales');

  final String value;
  final String displayName;
  final String description;

  const TipoMaterial(this.value, this.displayName, this.description);

  static TipoMaterial fromString(String value) {
    return TipoMaterial.values.firstWhere((e) => e.value == value);
  }
}

// Enums para Tipo de Techo
enum TipoTecho {
  liviano('liviano', 'Techo Liviano', 'Calamina, zinc, madera'),
  intermedio('intermedio', 'Techo Intermedio', 'Teja, mixto'),
  pesado('pesado', 'Techo Pesado', 'Losa de concreto');

  final String value;
  final String displayName;
  final String description;

  const TipoTecho(this.value, this.displayName, this.description);

  static TipoTecho fromString(String value) {
    return TipoTecho.values.firstWhere((e) => e.value == value);
  }
}

// Enums para Forma Geométrica
enum FormaGeometrica {
  regularSimetrica('regular_simetrica', 'Cuadrada / Rectangular', 'Regular y simétrica - Bajo riesgo'),
  irregularLeve('irregular_leve', 'Forma de "L"', 'Irregular leve - Riesgo bajo'),
  irregularMarcada('irregular_marcada', 'Forma de "U" o "T"', 'Irregular marcada - Riesgo medio'),
  muyIrregular('muy_irregular', 'Muy Irregular', 'Muy irregular - Alto riesgo');

  final String value;
  final String displayName;
  final String description;

  const FormaGeometrica(this.value, this.displayName, this.description);

  static FormaGeometrica fromString(String value) {
    return FormaGeometrica.values.firstWhere((e) => e.value == value);
  }
}

// Enums para Tipo de Suelo
enum TipoSuelo {
  rocaFirme('roca_firme', 'Roca Firme', 'Óptimo - muy estable'),
  gravaArena('grava_arena', 'Grava / Arena', 'Bueno - estable'),
  arcillaCompacta('arcilla_compacta', 'Arcilla Compacta', 'Regular'),
  arcillaBlanda('arcilla_blanda', 'Arcilla Blanda', 'Riesgo medio'),
  rellenoInestable('relleno_inestable', 'Relleno Inestable', 'Alto riesgo');

  final String value;
  final String displayName;
  final String description;

  const TipoSuelo(this.value, this.displayName, this.description);

  static TipoSuelo fromString(String value) {
    return TipoSuelo.values.firstWhere((e) => e.value == value);
  }
}

// Enums para Tipo de Construcción
enum TipoConstruccion {
  conIngeniero('con_ingeniero', 'Con Ingeniero', 'Profesional con planos'),
  maestroExperimentado('maestro_experimentado', 'Maestro Experimentado', 'Maestro de obra con experiencia'),
  autoconstruccionInformal(
      'autoconstruccion_informal', 'Autoconstrucción', 'Construcción informal');

  final String value;
  final String displayName;
  final String description;

  const TipoConstruccion(this.value, this.displayName, this.description);

  static TipoConstruccion fromString(String value) {
    return TipoConstruccion.values.firstWhere((e) => e.value == value);
  }
}

// Enum para Nivel de Riesgo
enum NivelRiesgo {
  alto('ALTO', 'Alto', '🔴'),
  medio('MEDIO', 'Medio', '🟡'),
  bajo('BAJO', 'Bajo', '🟢');

  final String value;
  final String displayName;
  final String emoji;

  const NivelRiesgo(this.value, this.displayName, this.emoji);

  static NivelRiesgo fromString(String value) {
    return NivelRiesgo.values.firstWhere((e) => e.value == value);
  }
}
