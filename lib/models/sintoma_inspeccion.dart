// lib/models/sintoma_inspeccion.dart
// Modelo de datos para síntomas de inspección (Fase B: Inspección Guiada)

class SintomaInspeccion {
  final String? id;
  final String idEdificacion;

  // Tipo de Síntoma
  final TipoSintoma tipoSintoma;

  // Campos comunes
  final UbicacionElemento ubicacion;

  // Campos específicos para grietas
  final DireccionGrieta? direccionGrieta;
  final EspesorGrieta? espesorGrieta;
  final CantidadGrietas? cantidadGrietas;

  // Campos específicos para humedad
  final List<AparienciaHumedad>? aparienciaHumedad;

  // Campos específicos para deformación
  final List<SintomaFuncional>? sintomasFuncionales;

  // Referencias a fotos
  final List<String>? fotosUrls;
  
  // IA: Fotos con detección automática
  final String? fotoOriginalUrl;  // Imagen sin anotaciones
  final String? fotoAnotadaUrl;    // Imagen con bounding boxes dibujados
  final Map<String, dynamic>? deteccionesIA; // JSON con predicciones de Roboflow

  final DateTime? createdAt;

  SintomaInspeccion({
    this.id,
    required this.idEdificacion,
    required this.tipoSintoma,
    required this.ubicacion,
    this.direccionGrieta,
    this.espesorGrieta,
    this.cantidadGrietas,
    this.aparienciaHumedad,
    this.sintomasFuncionales,
    this.fotosUrls,
    this.fotoOriginalUrl,
    this.fotoAnotadaUrl,
    this.deteccionesIA,
    this.createdAt,
  });

  // Convertir desde JSON (Supabase)
  factory SintomaInspeccion.fromJson(Map<String, dynamic> json) {
    return SintomaInspeccion(
      id: json['id'] as String?,
      idEdificacion: json['id_edificacion'] as String,
      tipoSintoma: TipoSintoma.fromString(json['tipo_sintoma'] as String),
      ubicacion: UbicacionElemento.fromString(json['ubicacion'] as String),
      direccionGrieta: json['direccion_grieta'] != null
          ? DireccionGrieta.fromString(json['direccion_grieta'] as String)
          : null,
      espesorGrieta: json['espesor_grieta'] != null
          ? EspesorGrieta.fromString(json['espesor_grieta'] as String)
          : null,
      cantidadGrietas: json['cantidad_grietas'] != null
          ? CantidadGrietas.fromString(json['cantidad_grietas'] as String)
          : null,
      aparienciaHumedad: json['apariencia_humedad'] != null
          ? (json['apariencia_humedad'] as List)
              .map((e) => AparienciaHumedad.fromString(e as String))
              .toList()
          : null,
      sintomasFuncionales: json['sintomas_funcionales'] != null
          ? (json['sintomas_funcionales'] as List)
              .map((e) => SintomaFuncional.fromString(e as String))
              .toList()
          : null,
      fotosUrls: json['fotos_urls'] != null
          ? List<String>.from(json['fotos_urls'] as List)
          : null,
      fotoOriginalUrl: json['foto_original_url'] as String?,
      fotoAnotadaUrl: json['foto_anotada_url'] as String?,
      deteccionesIA: json['detecciones_ia'] as Map<String, dynamic>?,
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
      'tipo_sintoma': tipoSintoma.value,
      'ubicacion': ubicacion.value,
      if (direccionGrieta != null) 'direccion_grieta': direccionGrieta!.value,
      if (espesorGrieta != null) 'espesor_grieta': espesorGrieta!.value,
      if (cantidadGrietas != null) 'cantidad_grietas': cantidadGrietas!.value,
      if (aparienciaHumedad != null)
        'apariencia_humedad':
            aparienciaHumedad!.map((e) => e.value).toList(),
      if (sintomasFuncionales != null)
        'sintomas_funcionales':
            sintomasFuncionales!.map((e) => e.value).toList(),
      if (fotosUrls != null) 'fotos_urls': fotosUrls,
      if (fotoOriginalUrl != null) 'foto_original_url': fotoOriginalUrl,
      if (fotoAnotadaUrl != null) 'foto_anotada_url': fotoAnotadaUrl,
      if (deteccionesIA != null) 'detecciones_ia': deteccionesIA,
    };
  }
}

// Enum para Tipo de Síntoma
enum TipoSintoma {
  grieta('grieta', 'Grieta', '⚡', 'Fisuras o fracturas en elementos estructurales'),
  humedad('humedad', 'Humedad', '💧', 'Manchas, moho o eflorescencia'),
  deformacion('deformacion', 'Deformación', '↔️', 'Hundimientos o inclinaciones'),
  desprendimiento(
      'desprendimiento', 'Desprendimiento', '🧱', 'Caída de material');

  final String value;
  final String displayName;
  final String emoji;
  final String description;

  const TipoSintoma(this.value, this.displayName, this.emoji, this.description);

  static TipoSintoma fromString(String value) {
    return TipoSintoma.values.firstWhere((e) => e.value == value);
  }
}

// Enum para Ubicación del Elemento
enum UbicacionElemento {
  muro('muro', 'Muro'),
  columna('columna', 'Columna'),
  viga('viga', 'Viga'),
  techo('techo', 'Techo'),
  piso('piso', 'Piso');

  final String value;
  final String displayName;

  const UbicacionElemento(this.value, this.displayName);

  static UbicacionElemento fromString(String value) {
    return UbicacionElemento.values.firstWhere((e) => e.value == value);
  }
}

// Enum para Dirección de Grieta (CRÍTICO para ingenieros)
enum DireccionGrieta {
  vertical('vertical', 'Vertical ↕️',
      'Posible asentamiento o cambios de temperatura'),
  horizontal('horizontal', 'Horizontal ↔️',
      'Posible corrosión de refuerzo o empuje de suelo'),
  diagonal('diagonal', 'Diagonal ⚡', '🔴 ALERTA ROJA: Falla por corte/sismo'),
  xPattern('x_pattern', 'En forma de "X"', '🔴 Daño sísmico severo');

  final String value;
  final String displayName;
  final String interpretacion;

  const DireccionGrieta(this.value, this.displayName, this.interpretacion);

  static DireccionGrieta fromString(String value) {
    return DireccionGrieta.values.firstWhere((e) => e.value == value);
  }
}

// Enum para Espesor de Grieta
enum EspesorGrieta {
  fisura('fisura', 'Fisura', 'Como un cabello (< 0.5mm)'),
  grieta('grieta', 'Grieta', 'Entra una uña o moneda (0.5-3mm)'),
  fractura('fractura', 'Fractura', 'Se ve el otro lado o entra un dedo (> 3mm)');

  final String value;
  final String displayName;
  final String description;

  const EspesorGrieta(this.value, this.displayName, this.description);

  static EspesorGrieta fromString(String value) {
    return EspesorGrieta.values.firstWhere((e) => e.value == value);
  }
}

// Enum para Cantidad de Grietas
enum CantidadGrietas {
  unaSola('una_sola', 'Una sola'),
  varias2a5('varias_2_5', 'Varias (2-5)'),
  muchasMas5('muchas_mas_5', 'Muchas (más de 5)');

  final String value;
  final String displayName;

  const CantidadGrietas(this.value, this.displayName);

  static CantidadGrietas fromString(String value) {
    return CantidadGrietas.values.firstWhere((e) => e.value == value);
  }
}

// Enum para Apariencia de Humedad
enum AparienciaHumedad {
  mancha('mancha', 'Solo mancha oscura'),
  pinturaDescascarada('pintura_descascarada', 'Pintura englobada/descascarada'),
  moho('moho', 'Presencia de moho (verde/negro)'),
  eflorescencia('eflorescencia', 'Eflorescencia (polvo blanco/salitre)');

  final String value;
  final String displayName;

  const AparienciaHumedad(this.value, this.displayName);

  static AparienciaHumedad fromString(String value) {
    return AparienciaHumedad.values.firstWhere((e) => e.value == value);
  }
}

// Enum para Síntomas Funcionales (Deformación)
enum SintomaFuncional {
  puertasTraban(
      'puertas_traban', 'Las puertas o ventanas se traban al cerrar'),
  pisoInclinado('piso_inclinado',
      'Si pones una pelota en el piso, rueda sola'),
  vidriosRotos('vidrios_rotos',
      'Se han roto vidrios de ventanas sin golpearlos');

  final String value;
  final String displayName;

  const SintomaFuncional(this.value, this.displayName);

  static SintomaFuncional fromString(String value) {
    return SintomaFuncional.values.firstWhere((e) => e.value == value);
  }
}
