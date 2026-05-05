-- ============================================================
-- MIGRACIÓN SUPABASE: SISTEMA DE VALORACIONES Y SELECCIÓN
-- ============================================================
-- Versión: 3.0
-- Fecha: 2025-11-25
-- Descripción: Añade sistema de valoraciones, citas técnicas,
--              selección de profesionales y detección de IA mejorada
-- ============================================================

-- ============================================================
-- PASO 1: NUEVAS TABLAS
-- ============================================================

-- Tabla de Valoraciones Profesionales
CREATE TABLE IF NOT EXISTS valoraciones_profesionales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_profesional UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  id_propietario UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  id_solicitud UUID NOT NULL REFERENCES solicitudes_revision(id) ON DELETE CASCADE,
  calificacion INTEGER NOT NULL CHECK (calificacion >= 1 AND calificacion <= 5),
  comentario TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para valoraciones
CREATE INDEX IF NOT EXISTS idx_valoraciones_profesional ON valoraciones_profesionales(id_profesional);
CREATE INDEX IF NOT EXISTS idx_valoraciones_solicitud ON valoraciones_profesionales(id_solicitud);
CREATE INDEX IF NOT EXISTS idx_valoraciones_propietario ON valoraciones_profesionales(id_propietario);

-- Tabla de Citas Técnicas
CREATE TABLE IF NOT EXISTS citas_tecnicas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_solicitud UUID NOT NULL REFERENCES solicitudes_revision(id) ON DELETE CASCADE,
  id_profesional UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  id_propietario UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fecha_programada TIMESTAMPTZ NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME,
  costo_estimado DECIMAL(10,2),
  direccion TEXT,
  notas_profesional TEXT,
  estado TEXT NOT NULL DEFAULT 'pendiente_confirmacion' CHECK (estado IN (
    'pendiente_confirmacion', 'confirmada', 'cancelada', 'completada'
  )),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para citas
CREATE INDEX IF NOT EXISTS idx_citas_solicitud ON citas_tecnicas(id_solicitud);
CREATE INDEX IF NOT EXISTS idx_citas_profesional ON citas_tecnicas(id_profesional);
CREATE INDEX IF NOT EXISTS idx_citas_propietario ON citas_tecnicas(id_propietario);
CREATE INDEX IF NOT EXISTS idx_citas_fecha ON citas_tecnicas(fecha_programada);
CREATE INDEX IF NOT EXISTS idx_citas_estado ON citas_tecnicas(estado);

-- Trigger para updated_at en citas
CREATE TRIGGER citas_tecnicas_updated_at 
BEFORE UPDATE ON citas_tecnicas
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- PASO 2: MODIFICACIONES A TABLAS EXISTENTES
-- ============================================================

-- Modificar tabla perfiles (información profesional)
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS universidad TEXT;
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS titulo_academico TEXT;
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS cip_numero TEXT;
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS certificaciones TEXT[];
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS descripcion_profesional TEXT;
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS foto_perfil_url TEXT;
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS tarifa_desde DECIMAL(10,2);
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS tarifa_hasta DECIMAL(10,2);

-- Modificar tabla sintomas_inspeccion (detección de IA)
ALTER TABLE sintomas_inspeccion ADD COLUMN IF NOT EXISTS foto_original_url TEXT;
ALTER TABLE sintomas_inspeccion ADD COLUMN IF NOT EXISTS foto_anotada_url TEXT;
ALTER TABLE sintomas_inspeccion ADD COLUMN IF NOT EXISTS detecciones_ia JSONB;

-- Comentario sobre el campo detecciones_ia
COMMENT ON COLUMN sintomas_inspeccion.detecciones_ia IS 
'JSON con predicciones de Roboflow: {model, predictions: [{class, confidence, x, y, width, height}]}';

-- Modificar tabla solicitudes_revision (tipo de servicio)
ALTER TABLE solicitudes_revision ADD COLUMN IF NOT EXISTS tipo_servicio TEXT 
  CHECK (tipo_servicio IN ('consejo_rapido', 'visita_tecnica'));
ALTER TABLE solicitudes_revision ADD COLUMN IF NOT EXISTS costo_acordado DECIMAL(10,2);

-- Modificar tabla informes_tecnicos (PDF y compartir)
ALTER TABLE informes_tecnicos ADD COLUMN IF NOT EXISTS pdf_url TEXT;
ALTER TABLE informes_tecnicos ADD COLUMN IF NOT EXISTS compartido_en TEXT[];

-- ============================================================
-- PASO 3: FUNCIONES AUXILIARES
-- ============================================================

-- Función para obtener promedio de valoraciones de un profesional
CREATE OR REPLACE FUNCTION get_promedio_valoraciones(profesional_id UUID)
RETURNS DECIMAL(3,2) AS $$
DECLARE
  promedio DECIMAL(3,2);
BEGIN
  SELECT ROUND(AVG(calificacion)::numeric, 2)
  INTO promedio
  FROM valoraciones_profesionales
  WHERE id_profesional = profesional_id;
  
  RETURN COALESCE(promedio, 0);
END;
$$ LANGUAGE plpgsql;

-- Función para contar trabajos completados de un profesional
CREATE OR REPLACE FUNCTION get_trabajos_completados(profesional_id UUID)
RETURNS INTEGER AS $$
DECLARE
  total INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO total
  FROM solicitudes_revision
  WHERE id_profesional = profesional_id 
    AND estado = 'completada';
  
  RETURN COALESCE(total, 0);
END;
$$ LANGUAGE plpgsql;

-- Función para obtener estadísticas del mes de un profesional
CREATE OR REPLACE FUNCTION get_estadisticas_mes(profesional_id UUID)
RETURNS TABLE(
  solicitudes_nuevas INTEGER,
  en_proceso INTEGER,
  completadas INTEGER,
  valoracion_promedio DECIMAL(3,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) FILTER (WHERE estado = 'pendiente')::INTEGER as solicitudes_nuevas,
    COUNT(*) FILTER (WHERE estado IN ('en_revision', 'programada', 'en_campo'))::INTEGER as en_proceso,
    COUNT(*) FILTER (WHERE estado = 'completada' AND 
                     created_at >= date_trunc('month', CURRENT_DATE))::INTEGER as completadas,
    get_promedio_valoraciones(profesional_id) as valoracion_promedio
  FROM solicitudes_revision
  WHERE id_profesional = profesional_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- PASO 4: ROW LEVEL SECURITY (RLS) - NUEVAS POLÍTICAS
-- ============================================================

-- Activar RLS en nuevas tablas
ALTER TABLE valoraciones_profesionales ENABLE ROW LEVEL SECURITY;
ALTER TABLE citas_tecnicas ENABLE ROW LEVEL SECURITY;

-- ========== POLÍTICAS: VALORACIONES ==========

CREATE POLICY "Propietarios crean valoraciones de sus solicitudes"
ON valoraciones_profesionales FOR INSERT
TO authenticated
WITH CHECK (
  id_propietario = auth.uid() AND
  id_solicitud IN (
    SELECT id FROM solicitudes_revision WHERE id_propietario = auth.uid()
  )
);

CREATE POLICY "Propietarios ven sus valoraciones"
ON valoraciones_profesionales FOR SELECT
TO authenticated
USING (id_propietario = auth.uid());

CREATE POLICY "Profesionales ven valoraciones que recibieron"
ON valoraciones_profesionales FOR SELECT
TO authenticated
USING (id_profesional = auth.uid());

-- Todos pueden ver valoraciones de profesionales (para selección)
CREATE POLICY "Valoraciones de profesionales son públicas para autenticados"
ON valoraciones_profesionales FOR SELECT
TO authenticated
USING (true);

-- ========== POLÍTICAS: CITAS ==========

CREATE POLICY "Profesionales crean citas de sus solicitudes"
ON citas_tecnicas FOR INSERT
TO authenticated
WITH CHECK (
  id_profesional = auth.uid() AND
  id_solicitud IN (
    SELECT id FROM solicitudes_revision WHERE id_profesional = auth.uid()
  )
);

CREATE POLICY "Profesionales actualizan sus citas"
ON citas_tecnicas FOR UPDATE
TO authenticated
USING (id_profesional = auth.uid());

CREATE POLICY "Propietarios actualizan citas (confirmar/rechazar)"
ON citas_tecnicas FOR UPDATE
TO authenticated
USING (id_propietario = auth.uid());

CREATE POLICY "Profesionales ven sus citas"
ON citas_tecnicas FOR SELECT
TO authenticated
USING (id_profesional = auth.uid());

CREATE POLICY "Propietarios ven sus citas"
ON citas_tecnicas FOR SELECT
TO authenticated
USING (id_propietario = auth.uid());

-- ============================================================
-- PASO 5: POLÍTICAS RLS MODIFICADAS
-- ============================================================

-- Modificar política para que perfiles profesionales sean visibles
DROP POLICY IF EXISTS "Usuarios ven solo su propio perfil" ON perfiles;

CREATE POLICY "Usuarios ven su propio perfil"
ON perfiles FOR SELECT
TO authenticated
USING (id_usuario = auth.uid());

CREATE POLICY "Perfiles de profesionales son públicos"
ON perfiles FOR SELECT
TO authenticated
USING (rol = 'profesional');

-- ============================================================
-- PASO 6: DATOS DE PRUEBA (OPCIONAL)
-- ============================================================

-- Comentar o descomentar según necesidad

-- INSERT INTO valoraciones_profesionales (id_profesional, id_propietario, id_solicitud, calificacion, comentario)
-- SELECT 
--   (SELECT id_usuario FROM perfiles WHERE rol = 'profesional' LIMIT 1),
--   auth.uid(),
--   (SELECT id FROM solicitudes_revision LIMIT 1),
--   5,
--   'Excelente trabajo, muy profesional y detallado';

-- ============================================================
-- PASO 7: VERIFICACIÓN
-- ============================================================

-- Verificar nuevas tablas
SELECT 
  table_name, 
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as num_columns
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
  AND table_name IN (
    'valoraciones_profesionales',
    'citas_tecnicas'
  )
ORDER BY table_name;

-- Verificar nuevas columnas en tablas existentes
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('perfiles', 'sintomas_inspeccion', 'solicitudes_revision', 'informes_tecnicos')
  AND column_name IN (
    'universidad', 'titulo_academico', 'cip_numero', 'certificaciones',
    'descripcion_profesional', 'foto_perfil_url', 'tarifa_desde', 'tarifa_hasta',
    'foto_original_url', 'foto_anotada_url', 'detecciones_ia',
    'tipo_servicio', 'costo_acordado',
    'pdf_url', 'compartido_en'
  )
ORDER BY table_name, column_name;

-- ============================================================
-- INSTRUCCIONES POST-MIGRACIÓN
-- ============================================================

-- 1. Ejecutar este script en el SQL Editor de Supabase
-- 2. Verificar que no haya errores
-- 3. Verificar las tablas y columnas creadas con las queries del PASO 7
-- 4. Actualizar los modelos Dart correspondientes
-- 5. Actualizar DatabaseService con los nuevos métodos

-- ============================================================
-- FIN DE LA MIGRACIÓN
-- ============================================================
