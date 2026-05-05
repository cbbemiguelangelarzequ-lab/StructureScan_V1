-- Migración: Agregar columnas de ubicación a edificaciones
-- Fecha: 2025-12-01
-- Descripción: Agrega campos latitud y longitud para almacenar coordenadas del mapa

-- Agregar columnas de ubicación
ALTER TABLE edificaciones 
ADD COLUMN IF NOT EXISTS latitud DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitud DOUBLE PRECISION;

-- Agregar comentarios para documentación
COMMENT ON COLUMN edificaciones.latitud IS 'Latitud de la ubicación (coordenada Y del mapa OSM)';
COMMENT ON COLUMN edificaciones.longitud IS 'Longitud de la ubicación (coordenada X del mapa OSM)';

-- Verificar que se agregaron correctamente
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'edificaciones' 
  AND column_name IN ('latitud', 'longitud');
