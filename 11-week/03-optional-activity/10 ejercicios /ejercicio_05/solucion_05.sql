-- =============================================================================
-- Solución Ejercicio 05 - Mantenimiento de Aeronaves
-- =============================================================================

-- 1. Consulta SQL con INNER JOIN (Historial de mantenimiento por aeronave)
SELECT 
    a.registration_number AS matricula,
    am.model_name AS modelo,
    man.manufacturer_name AS fabricante,
    mt.type_name AS tipo_mantenimiento,
    mp.provider_name AS taller_proveedor,
    me.status_code AS estado,
    me.started_at AS fecha_inicio,
    me.completed_at AS fecha_fin
FROM aircraft a
INNER JOIN aircraft_model am ON a.aircraft_model_id = am.aircraft_model_id
INNER JOIN aircraft_manufacturer man ON am.aircraft_manufacturer_id = man.aircraft_manufacturer_id
INNER JOIN maintenance_event me ON a.aircraft_id = me.aircraft_id
INNER JOIN maintenance_type mt ON me.maintenance_type_id = mt.maintenance_type_id
INNER JOIN maintenance_provider mp ON me.maintenance_provider_id = mp.maintenance_provider_id
ORDER BY me.started_at DESC;

-- 2. Trigger AFTER (Actualización de estado operativo de aeronave)
CREATE OR REPLACE FUNCTION fn_tr_maintenance_event_after_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Al completar un mantenimiento, actualizar la fecha de retiro o estado en aeronave (simulado vía updated_at)
    IF NEW.status_code = 'COMPLETED' AND OLD.status_code <> 'COMPLETED' THEN
        UPDATE aircraft 
        SET updated_at = NOW()
        WHERE aircraft_id = NEW.aircraft_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_maintenance_event_after_update
AFTER UPDATE ON maintenance_event
FOR EACH ROW
EXECUTE FUNCTION fn_tr_maintenance_event_after_update();

-- 3. Procedimiento Almacenado (Registro de Evento de Mantenimiento)
CREATE OR REPLACE PROCEDURE sp_register_maintenance_event(
    p_aircraft_id UUID,
    p_maintenance_type_id UUID,
    p_maintenance_provider_id UUID,
    p_status_code VARCHAR(20),
    p_notes TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO maintenance_event (
        aircraft_id,
        maintenance_type_id,
        maintenance_provider_id,
        status_code,
        started_at,
        notes
    ) VALUES (
        p_aircraft_id,
        p_maintenance_type_id,
        p_maintenance_provider_id,
        p_status_code,
        NOW(),
        p_notes
    );
END;
$$;

-- 4. Script de prueba y validación
/*
DO $$
DECLARE
    v_a_id UUID;
    v_mt_id UUID;
    v_mp_id UUID;
BEGIN
    SELECT aircraft_id INTO v_a_id FROM aircraft LIMIT 1;
    SELECT maintenance_type_id INTO v_mt_id FROM maintenance_type LIMIT 1;
    SELECT maintenance_provider_id INTO v_mp_id FROM maintenance_provider LIMIT 1;

    CALL sp_register_maintenance_event(
        v_a_id,
        v_mt_id,
        v_mp_id,
        'PLANNED',
        'Mantenimiento preventivo anual'
    );
END $$;

-- Simular actualización para disparar trigger
-- UPDATE maintenance_event SET status_code = 'COMPLETED', completed_at = NOW() WHERE notes = 'Mantenimiento preventivo anual';
*/
