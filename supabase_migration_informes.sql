-- ============================================================
-- MIGRACIÓN INCREMENTAL: TABLA INFORMES TÉCNICOS
-- ============================================================
-- Versión: 1.0
-- Fecha: 2025-11-20
-- Descripción: Agrega solo la tabla informes_tecnicos al schema existente
-- ============================================================

-- IMPORTANTE: Este script asume que ya tienes las tablas existentes
-- (edificaciones, solicitudes_revision, hallazgos_profesionales, etc.)

-- ============================================================
-- PASO 1: CREAR TABLA INFORMES TÉCNICOS
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

-- ============================================================
-- PASO 2: CREAR ÍNDICES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_informes_solicitud ON informes_tecnicos(id_solicitud);
CREATE INDEX IF NOT EXISTS idx_informes_profesional ON informes_tecnicos(id_profesional);

-- ============================================================
-- PASO 3: CREAR TRIGGER PARA UPDATED_AT
-- ============================================================

-- El trigger usa la función update_updated_at_column() que ya debería existir
DROP TRIGGER IF EXISTS informes_tecnicos_updated_at ON informes_tecnicos;

CREATE TRIGGER informes_tecnicos_updated_at 
BEFORE UPDATE ON informes_tecnicos
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- PASO 4: ACTIVAR ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE informes_tecnicos ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PASO 5: CREAR POLÍTICAS RLS
-- ============================================================

-- Limpiar políticas existentes si las hay
DROP POLICY IF EXISTS "Profesionales crean informes" ON informes_tecnicos;
DROP POLICY IF EXISTS "Profesionales actualizan sus informes" ON informes_tecnicos;
DROP POLICY IF EXISTS "Profesionales ven sus informes" ON informes_tecnicos;
DROP POLICY IF EXISTS "Propietarios ven informes de sus solicitudes" ON informes_tecnicos;

-- Profesionales pueden crear informes (solo de sus solicitudes asignadas)
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

-- Profesionales pueden actualizar sus propios informes
CREATE POLICY "Profesionales actualizan sus informes"
ON informes_tecnicos FOR UPDATE
TO authenticated
USING (id_profesional = auth.uid());

-- Profesionales pueden ver sus propios informes
CREATE POLICY "Profesionales ven sus informes"
ON informes_tecnicos FOR SELECT
TO authenticated
USING (id_profesional = auth.uid());

-- Propietarios pueden ver informes de sus solicitudes
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
-- PASO 6: VERIFICACIÓN
-- ============================================================

-- Verificar que la tabla se creó correctamente
SELECT 
  table_name, 
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'informes_tecnicos') as num_columns
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
  AND table_name = 'informes_tecnicos';

-- Debería mostrar: informes_tecnicos | 9

-- Verificar políticas RLS
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'informes_tecnicos'
ORDER BY policyname;

-- Debería mostrar 4 políticas

-- ============================================================
-- INSTRUCCIONES POST-MIGRACIÓN
-- ============================================================

-- ✅ Si ves "informes_tecnicos | 9" en la primera consulta, la migración fue exitosa
-- ✅ Si ves 4 políticas en la segunda consulta, el RLS está configurado correctamente
-- ✅ La aplicación Flutter ya está lista para usar esta tabla

-- ============================================================
-- FIN DE LA MIGRACIÓN INCREMENTAL
-- ============================================================
