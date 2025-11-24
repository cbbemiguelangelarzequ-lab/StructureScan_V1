-- ============================================================
-- MIGRACIÓN SUPABASE: MÓDULO DE TRIAJE ESTRUCTURAL INTELIGENTE
-- ============================================================
-- Versión: 2.1 (Orden corregido)
-- Fecha: 2024-11-20
-- Descripción: Schema completo para flujos de propietario y profesional
--              con integración de cámara IA (Roboflow)
-- ============================================================

-- ============================================================
-- PASO 1: EXTENSIONES Y CONFIGURACIÓN
-- ============================================================

-- Habilitar UUID para IDs únicos
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Función para actualizar timestamp (Debe crearse antes de los triggers)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- PASO 2: TABLA DE PERFILES (CREAR O EXTENDER)
-- ============================================================

-- Crear tabla perfiles si no existe
CREATE TABLE IF NOT EXISTS perfiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_usuario UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT,
  address TEXT,
  date_of_birth DATE,
  
  -- Campos para el sistema de triaje
  rol TEXT CHECK (rol IN ('propietario', 'profesional')) DEFAULT 'propietario',
  numero_licencia TEXT,
  especializacion TEXT,
  years_experiencia INTEGER,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Si la tabla ya existía, asegurar que tenga las columnas necesarias
-- Usamos ALTER TABLE IF NOT EXISTS que es más seguro y simple que bloques DO

ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS rol TEXT CHECK (rol IN ('propietario', 'profesional')) DEFAULT 'propietario';
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS numero_licencia TEXT;
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS especializacion TEXT;
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS years_experiencia INTEGER;

-- Índices
CREATE INDEX IF NOT EXISTS idx_perfiles_usuario ON perfiles(id_usuario);
CREATE INDEX IF NOT EXISTS idx_perfiles_rol ON perfiles(rol);

-- Trigger para actualizar updated_at
CREATE TRIGGER perfiles_updated_at 
BEFORE UPDATE ON perfiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS para perfiles
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven solo su propio perfil"
ON perfiles FOR SELECT
TO authenticated
USING (id_usuario = auth.uid());

CREATE POLICY "Usuarios crean su propio perfil"
ON perfiles FOR INSERT
TO authenticated
WITH CHECK (id_usuario = auth.uid());

CREATE POLICY "Usuarios actualizan su propio perfil"
ON perfiles FOR UPDATE
TO authenticated
USING (id_usuario = auth.uid());

-- ============================================================
-- PASO 3: TABLA EDIFICACIONES (Fase A - Perfil de Vulnerabilidad)
-- ============================================================

CREATE TABLE IF NOT EXISTS edificaciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_usuario UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre_edificacion TEXT NOT NULL,
  direccion TEXT,
  
  -- Materialidad
  tipo_material TEXT NOT NULL CHECK (tipo_material IN (
    'ladrillo_concreto', 'adobe_bahareque', 'madera', 
    'concreto_reforzado', 'mixto_otro'
  )),
  
  -- Sistema de Techo
  tipo_techo TEXT NOT NULL CHECK (tipo_techo IN (
    'liviano', 'intermedio', 'pesado'
  )),
  
  -- Configuración Geométrica
  forma_geometrica TEXT NOT NULL CHECK (forma_geometrica IN (
    'regular_simetrica', 'irregular_leve', 
    'irregular_marcada', 'muy_irregular'
  )),
  
  -- Entorno y Suelo
  tipo_suelo TEXT NOT NULL CHECK (tipo_suelo IN (
    'roca_firme', 'grava_arena', 'arcilla_compacta', 
    'arcilla_blanda', 'relleno_inestable'
  )),
  
  -- Historia Constructiva
  tipo_construccion TEXT NOT NULL CHECK (tipo_construccion IN (
    'con_ingeniero', 'maestro_experimentado', 
    'autoconstruccion_informal'
  )),
  ha_tenido_modificaciones BOOLEAN DEFAULT FALSE,
  descripcion_modificaciones TEXT,
  
  -- Cálculo Automático de Riesgo
  nivel_riesgo TEXT CHECK (nivel_riesgo IN ('BAJO', 'MEDIO', 'ALTO')),
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para rendimiento
CREATE INDEX IF NOT EXISTS idx_edificaciones_usuario ON edificaciones(id_usuario);
CREATE INDEX IF NOT EXISTS idx_edificaciones_riesgo ON edificaciones(nivel_riesgo);

-- Trigger para actualizar updated_at
-- Trigger para actualizar updated_at
CREATE TRIGGER edificaciones_updated_at 
BEFORE UPDATE ON edificaciones
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- PASO 4: FUNCIÓN DE CÁLCULO DE RIESGO
-- ============================================================

CREATE OR REPLACE FUNCTION calcular_riesgo_edificacion()
RETURNS TRIGGER AS $$
DECLARE
  puntos_riesgo INTEGER := 0;
BEGIN
  -- Material (0-3 puntos)
  puntos_riesgo := puntos_riesgo + CASE NEW.tipo_material
    WHEN 'adobe_bahareque' THEN 3
    WHEN 'ladrillo_concreto' THEN 2
    WHEN 'mixto_otro' THEN 2
    WHEN 'madera' THEN 1
    WHEN 'concreto_reforzado' THEN 0
    ELSE 0
  END;
  
  -- Techo (0-2 puntos)
  puntos_riesgo := puntos_riesgo + CASE NEW.tipo_techo
    WHEN 'pesado' THEN 2
    WHEN 'intermedio' THEN 1
    WHEN 'liviano' THEN 0
    ELSE 0
  END;
  
  -- Geometría (0-3 puntos)
  puntos_riesgo := puntos_riesgo + CASE NEW.forma_geometrica
    WHEN 'muy_irregular' THEN 3
    WHEN 'irregular_marcada' THEN 2
    WHEN 'irregular_leve' THEN 1
    WHEN 'regular_simetrica' THEN 0
    ELSE 0
  END;
  
  -- Suelo (0-3 puntos)
  puntos_riesgo := puntos_riesgo + CASE NEW.tipo_suelo
    WHEN 'relleno_inestable' THEN 3
    WHEN 'arcilla_blanda' THEN 2
    WHEN 'arcilla_compacta' THEN 1
    WHEN 'grava_arena' THEN 1
    WHEN 'roca_firme' THEN 0
    ELSE 0
  END;
  
  -- Construcción (0-2 puntos)
  puntos_riesgo := puntos_riesgo + CASE NEW.tipo_construccion
    WHEN 'autoconstruccion_informal' THEN 2
    WHEN 'maestro_experimentado' THEN 1
    WHEN 'con_ingeniero' THEN 0
    ELSE 0
  END;
  
  -- Modificaciones (+1 punto)
  IF NEW.ha_tenido_modificaciones THEN
    puntos_riesgo := puntos_riesgo + 1;
  END IF;
  
  -- Asignar nivel de riesgo (0-14 puntos posibles)
  NEW.nivel_riesgo := CASE
    WHEN puntos_riesgo >= 8 THEN 'ALTO'
    WHEN puntos_riesgo >= 4 THEN 'MEDIO'
    ELSE 'BAJO'
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para calcular riesgo automáticamente
CREATE TRIGGER trigger_calcular_riesgo
BEFORE INSERT OR UPDATE ON edificaciones
FOR EACH ROW EXECUTE FUNCTION calcular_riesgo_edificacion();

-- ============================================================
-- PASO 5: TABLA SÍNTOMAS DE INSPECCIÓN (Fase B)
-- ============================================================

CREATE TABLE IF NOT EXISTS sintomas_inspeccion (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_edificacion UUID NOT NULL REFERENCES edificaciones(id) ON DELETE CASCADE,
  
  -- Tipo de Síntoma
  tipo_sintoma TEXT NOT NULL CHECK (tipo_sintoma IN (
    'grieta', 'humedad', 'deformacion', 'desprendimiento'
  )),
  
  -- Ubicación (común a todos)
  ubicacion TEXT NOT NULL CHECK (ubicacion IN (
    'muro', 'columna', 'viga', 'techo', 'piso', 'escalera', 'otro'
  )),
  
  -- Específico para GRIETAS
  direccion_grieta TEXT CHECK (direccion_grieta IN (
    'vertical', 'horizontal', 'diagonal', 'x_pattern', 'mapeado'
  )),
  espesor_grieta TEXT CHECK (espesor_grieta IN (
    'fisura', 'grieta', 'fractura'
  )),
  cantidad_grietas TEXT CHECK (cantidad_grietas IN (
    'una_sola', 'varias_2_5', 'muchas_mas_5'
  )),
  
  -- Específico para HUMEDAD
  apariencia_humedad TEXT[], -- Array de: 'mancha', 'descascaramiento', 'moho', 'salitre'
  
  -- Específico para DEFORMACIÓN
  sintomas_funcionales TEXT[], -- Array de: 'puertas_traban', 'piso_inclinado', etc.
  
  -- Fotos con IA
  fotos_urls TEXT[], -- Array de URLs de Supabase Storage
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_sintomas_edificacion ON sintomas_inspeccion(id_edificacion);
CREATE INDEX IF NOT EXISTS idx_sintomas_tipo ON sintomas_inspeccion(tipo_sintoma);

-- ============================================================
-- PASO 6: TABLA ANAMNESIS (Fase C - Historia)
-- ============================================================

CREATE TABLE IF NOT EXISTS anamnesis (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_edificacion UUID NOT NULL REFERENCES edificaciones(id) ON DELETE CASCADE,
  
  -- Timeline de Descubrimiento
  cuando_descubrio TEXT NOT NULL CHECK (cuando_descubrio IN (
    'ayer_hace_dias', 'hace_semanas', 'hace_meses', 
    'hace_1_anio', 'hace_varios_anios', 'desde_siempre'
  )),
  
  -- Comportamiento del Daño
  comportamiento TEXT NOT NULL CHECK (comportamiento IN (
    'estatico', 'crecimiento_lento', 'crecimiento_rapido', 
    'ciclico_estacional'
  )),
  
  -- Factores Detonantes
  factores_detonantes TEXT[], -- Array de: 'sismo', 'lluvia_intensa', etc.
  
  -- Observaciones Sensoriales
  tiene_ruidos BOOLEAN DEFAULT FALSE,
  descripcion_ruidos TEXT,
  tiene_vibraciones BOOLEAN DEFAULT FALSE,
  descripcion_vibraciones TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice
CREATE INDEX IF NOT EXISTS idx_anamnesis_edificacion ON anamnesis(id_edificacion);

-- ============================================================
-- PASO 7: TABLA SOLICITUDES DE REVISIÓN
-- ============================================================

CREATE TABLE IF NOT EXISTS solicitudes_revision (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_edificacion UUID NOT NULL REFERENCES edificaciones(id) ON DELETE CASCADE,
  id_propietario UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  id_profesional UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Resumen Generado Automáticamente
  sintoma_principal TEXT NOT NULL,
  descripcion_breve TEXT NOT NULL,
  nivel_riesgo TEXT NOT NULL CHECK (nivel_riesgo IN ('BAJO', 'MEDIO', 'ALTO')),
  
  -- Estado del Flujo
  estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN (
    'pendiente', 'en_revision', 'programada', 
    'en_campo', 'completada', 'descartada'
  )),
  
  -- Notas
  nota_profesional TEXT,
  fecha_programada TIMESTAMPTZ,
   
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_solicitudes_edificacion ON solicitudes_revision(id_edificacion);
CREATE INDEX IF NOT EXISTS idx_solicitudes_propietario ON solicitudes_revision(id_propietario);
CREATE INDEX IF NOT EXISTS idx_solicitudes_profesional ON solicitudes_revision(id_profesional);
CREATE INDEX IF NOT EXISTS idx_solicitudes_estado ON solicitudes_revision(estado);
CREATE INDEX IF NOT EXISTS idx_solicitudes_riesgo ON solicitudes_revision(nivel_riesgo);

-- Trigger updated_at
CREATE TRIGGER solicitudes_updated_at 
BEFORE UPDATE ON solicitudes_revision
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- PASO 8: TABLA HALLAZGOS PROFESIONALES
-- ============================================================

CREATE TABLE IF NOT EXISTS hallazgos_profesionales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_solicitud UUID NOT NULL REFERENCES solicitudes_revision(id) ON DELETE CASCADE,
  
  -- Clasificación Técnica
  clasificacion_tecnica TEXT NOT NULL CHECK (clasificacion_tecnica IN (
    'falla_por_corte', 'asentamiento_diferencial', 
    'patologia_humedad', 'deterioro_materiales',
    'deficiencia_estructural', 'sobrecarga',
    'falla_cimentacion', 'otros'
  )),
  
  -- Evaluación de Severidad
  severidad TEXT NOT NULL CHECK (severidad IN (
    'superficial', 'moderado', 'severo', 'critico'
  )),
  
  -- Notas Técnicas
  notas_tecnicas TEXT,
  fotos_profesionales TEXT[], -- URLs de fotos del profesional
  
  -- Recomendaciones
  recomendaciones TEXT,
  requiere_evacuacion BOOLEAN DEFAULT FALSE,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice
CREATE INDEX IF NOT EXISTS idx_hallazgos_solicitud ON hallazgos_profesionales(id_solicitud);
CREATE INDEX IF NOT EXISTS idx_hallazgos_severidad ON hallazgos_profesionales(severidad);

-- ============================================================
-- PASO 8.5: TABLA INFORMES TÉCNICOS
-- ============================================================

CREATE TABLE IF NOT EXISTS informes_tecnicos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_solicitud UUID NOT NULL REFERENCES solicitudes_revision(id) ON DELETE CASCADE,
  id_profesional UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Contenido del Informe
  contenido_markdown TEXT NOT NULL,
  conclusion_final TEXT NOT NULL,
  
  -- Evaluación Estructural
  es_habitable BOOLEAN DEFAULT true,
  requiere_refuerzo BOOLEAN DEFAULT false,
  
  -- Firma Profesional
  firma_profesional TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_informes_solicitud ON informes_tecnicos(id_solicitud);
CREATE INDEX IF NOT EXISTS idx_informes_profesional ON informes_tecnicos(id_profesional);

-- Trigger para actualizar updated_at
CREATE TRIGGER informes_tecnicos_updated_at 
BEFORE UPDATE ON informes_tecnicos
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- PASO 9: ROW LEVEL SECURITY (RLS) - TABLAS
-- ============================================================

-- Activar RLS en todas las tablas
ALTER TABLE edificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE sintomas_inspeccion ENABLE ROW LEVEL SECURITY;
ALTER TABLE anamnesis ENABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_revision ENABLE ROW LEVEL SECURITY;
ALTER TABLE hallazgos_profesionales ENABLE ROW LEVEL SECURITY;
ALTER TABLE informes_tecnicos ENABLE ROW LEVEL SECURITY;

-- ========== POLÍTICAS: EDIFICACIONES ==========

CREATE POLICY "Propietarios ven solo sus edificaciones"
ON edificaciones FOR SELECT
TO authenticated
USING (id_usuario = auth.uid());

CREATE POLICY "Propietarios crean sus edificaciones"
ON edificaciones FOR INSERT
TO authenticated
WITH CHECK (id_usuario = auth.uid());

CREATE POLICY "Propietarios actualizan sus edificaciones"
ON edificaciones FOR UPDATE
TO authenticated
USING (id_usuario = auth.uid());

-- Profesionales ven edificaciones de solicitudes asignadas
CREATE POLICY "Profesionales ven edificaciones de sus solicitudes"
ON edificaciones FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT id_edificacion FROM solicitudes_revision 
    WHERE id_profesional = auth.uid()
  )
);

-- ========== POLÍTICAS: SÍNTOMAS ==========

CREATE POLICY "Propietarios ven síntomas de sus edificaciones"
ON sintomas_inspeccion FOR SELECT
TO authenticated
USING (
  id_edificacion IN (
    SELECT id FROM edificaciones WHERE id_usuario = auth.uid()
  )
);

CREATE POLICY "Propietarios crean síntomas"
ON sintomas_inspeccion FOR INSERT
TO authenticated
WITH CHECK (
  id_edificacion IN (
    SELECT id FROM edificaciones WHERE id_usuario = auth.uid()
  )
);

-- Profesionales ven síntomas de solicitudes asignadas
CREATE POLICY "Profesionales ven síntomas de solicitudes"
ON sintomas_inspeccion FOR SELECT
TO authenticated
USING (
  id_edificacion IN (
    SELECT id_edificacion FROM solicitudes_revision 
    WHERE id_profesional = auth.uid()
  )
);

-- ========== POLÍTICAS: ANAMNESIS ==========

CREATE POLICY "Propietarios ven anamnesis de sus edificaciones"
ON anamnesis FOR SELECT
TO authenticated
USING (
  id_edificacion IN (
    SELECT id FROM edificaciones WHERE id_usuario = auth.uid()
  )
);

CREATE POLICY "Propietarios crean anamnesis"
ON anamnesis FOR INSERT
TO authenticated
WITH CHECK (
  id_edificacion IN (
    SELECT id FROM edificaciones WHERE id_usuario = auth.uid()
  )
);

CREATE POLICY "Propietarios actualizan anamnesis"
ON anamnesis FOR UPDATE
TO authenticated
USING (
  id_edificacion IN (
    SELECT id FROM edificaciones WHERE id_usuario = auth.uid()
  )
);

-- Profesionales ven anamnesis de solicitudes
CREATE POLICY "Profesionales ven anamnesis de solicitudes"
ON anamnesis FOR SELECT
TO authenticated
USING (
  id_edificacion IN (
    SELECT id_edificacion FROM solicitudes_revision 
    WHERE id_profesional = auth.uid()
  )
);

-- ========== POLÍTICAS: SOLICITUDES ==========

CREATE POLICY "Propietarios ven sus solicitudes"
ON solicitudes_revision FOR SELECT
TO authenticated
USING (id_propietario = auth.uid());

CREATE POLICY "Propietarios crean solicitudes"
ON solicitudes_revision FOR INSERT
TO authenticated
WITH CHECK (id_propietario = auth.uid());

-- Profesionales ven TODAS las solicitudes pendientes (para triaje)
CREATE POLICY "Profesionales ven solicitudes pendientes"
ON solicitudes_revision FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM perfiles 
    WHERE id_usuario = auth.uid() AND rol = 'profesional'
  )
);

-- Profesionales actualizan solicitudes (asignarse, cambiar estado)
CREATE POLICY "Profesionales actualizan solicitudes"
ON solicitudes_revision FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM perfiles 
    WHERE id_usuario = auth.uid() AND rol = 'profesional'
  )
);

-- ========== POLÍTICAS: HALLAZGOS ==========

CREATE POLICY "Profesionales crean hallazgos"
ON hallazgos_profesionales FOR INSERT
TO authenticated
WITH CHECK (
  id_solicitud IN (
    SELECT id FROM solicitudes_revision 
    WHERE id_profesional = auth.uid()
  )
);

CREATE POLICY "Propietarios ven hallazgos de sus solicitudes"
ON hallazgos_profesionales FOR SELECT TO authenticated
USING (
  id_solicitud IN (
    SELECT id FROM solicitudes_revision 
    WHERE id_propietario = auth.uid()
  )
);

CREATE POLICY "Profesionales ven hallazgos de sus solicitudes"
ON hallazgos_profesionales FOR SELECT
TO authenticated
USING (
  id_solicitud IN (
    SELECT id FROM solicitudes_revision 
    WHERE id_profesional = auth.uid()
  )
);

-- ========== POLÍTICAS: INFORMES TÉCNICOS ==========

CREATE POLICY "Profesionales crean informes"
ON informes_tecnicos FOR INSERT
TO authenticated
WITH CHECK (
  id_profesional = auth.uid() AND
  id_solicitud IN (
    SELECT id FROM solicitudes_revision 
    WHERE id_profesional = auth.uid()
  )
);

CREATE POLICY "Profesionales actualizan sus informes"
ON informes_tecnicos FOR UPDATE
TO authenticated
USING (id_profesional = auth.uid());

CREATE POLICY "Profesionales ven sus informes"
ON informes_tecnicos FOR SELECT
TO authenticated
USING (id_profesional = auth.uid());

CREATE POLICY "Propietarios ven informes de sus solicitudes"
ON informes_tecnicos FOR SELECT
TO authenticated
USING (
  id_solicitud IN (
    SELECT id FROM solicitudes_revision 
    WHERE id_propietario = auth.uid()
  )
);

-- ============================================================
-- PASO 10: POLÍTICAS RLS PARA STORAGE (DESPUÉS DE CREAR TABLAS)
-- ============================================================

-- IMPORTANTE: El bucket 'imagenes' debe ser creado manualmente en Supabase Dashboard → Storage
-- Nombre: imagenes
-- Público: Yes

-- Políticas para subir fotos
CREATE POLICY "Usuarios pueden subir imágenes a sus edificaciones"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'imagenes' AND
  (storage.foldername(name))[1] = 'edificaciones' AND
  auth.uid()::text = (
    SELECT id_usuario::text FROM edificaciones 
    WHERE id::text = (storage.foldername(name))[2]
  )
);

-- Política para ver fotos
CREATE POLICY "Imágenes públicas son visibles para todos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'imagenes');

-- Política para eliminar fotos
CREATE POLICY "Usuarios pueden eliminar sus propias imágenes"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'imagenes' AND
  (storage.foldername(name))[1] = 'edificaciones' AND
  auth.uid()::text = (
    SELECT id_usuario::text FROM edificaciones 
    WHERE id::text = (storage.foldername(name))[2]
  )
);

-- ============================================================
-- PASO 11: VERIFICACIÓN
-- ============================================================

-- Verificación rápida de tablas creadas
SELECT 
  table_name, 
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as num_columns
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
  AND table_name IN (
    'edificaciones', 
    'sintomas_inspeccion', 
    'anamnesis', 
    'solicitudes_revision', 
    'hallazgos_profesionales',
    'informes_tecnicos'
  )
ORDER BY table_name;

-- ============================================================
-- INSTRUCCIONES POST-MIGRACIÓN
-- ============================================================

-- 1. Crear bucket de Storage manualmente:
--    - Ve a Supabase Dashboard → Storage
--    - Click "New bucket"
--    - Nombre: imagenes
--    - Público: Yes (✓)
--    - Click "Create bucket"

-- 2. Verificar que las tablas se crearon:
--    Deberías ver 6 tablas con estas columnas:
--    - edificaciones: 14 columns
--    - sintomas_inspeccion: 11 columns
--    - anamnesis: 9 columns
--    - solicitudes_revision: 11 columns
--    - hallazgos_profesionales: 8 columns
--    - informes_tecnicos: 9 columns

-- 3. Verificar políticas RLS:
--    SELECT * FROM pg_policies WHERE tablename LIKE '%edificaciones%';

-- ============================================================
-- FIN DE LA MIGRACIÓN
-- ============================================================
