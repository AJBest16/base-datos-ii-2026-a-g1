-- =============================================================================
-- Solución Ejercicio 06 - Retrasos Operativos
-- =============================================================================

-- 1. Consulta SQL con INNER JOIN (Impacto de retrasos por segmento)
SELECT 
    f.flight_number AS numero_vuelo,
    fs.segment_number AS segmento,
    ao.iata_code AS origen,
    ad.iata_code AS destino,
    drt.reason_name AS motivo_retraso,
    fd.delay_minutes AS minutos,
    fd.reported_at AS fecha_reporte,
    fs.scheduled_departure_at AS salida_programada
FROM flight f
INNER JOIN flight_segment fs ON f.flight_id = fs.flight_id
INNER JOIN airport ao ON fs.origin_airport_id = ao.airport_id
INNER JOIN airport ad ON fs.destination_airport_id = ad.airport_id
INNER JOIN flight_delay fd ON fs.flight_segment_id = fd.flight_segment_id
INNER JOIN delay_reason_type drt ON fd.delay_reason_type_id = drt.delay_reason_type_id
ORDER BY fd.reported_at DESC;

-- 2. Trigger AFTER (Registro de impacto en el segmento de vuelo)
CREATE OR REPLACE FUNCTION fn_tr_flight_delay_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar notas del segmento para dejar constancia del retraso acumulado
    UPDATE flight_segment 
    SET updated_at = NOW()
    WHERE flight_segment_id = NEW.flight_segment_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_flight_delay_after_insert
AFTER INSERT ON flight_delay
FOR EACH ROW
EXECUTE FUNCTION fn_tr_flight_delay_after_insert();

-- 3. Procedimiento Almacenado (Reporte de Retraso)
CREATE OR REPLACE PROCEDURE sp_report_delay(
    p_flight_segment_id UUID,
    p_delay_reason_type_id UUID,
    p_delay_minutes INTEGER,
    p_notes TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO flight_delay (
        flight_segment_id,
        delay_reason_type_id,
        reported_at,
        delay_minutes,
        notes
    ) VALUES (
        p_flight_segment_id,
        p_delay_reason_type_id,
        NOW(),
        p_delay_minutes,
        p_notes
    );
END;
$$;

-- 4. Script de prueba y validación
/*
DO $$
DECLARE
    v_fs_id UUID;
    v_drt_id UUID;
BEGIN
    SELECT flight_segment_id INTO v_fs_id FROM flight_segment LIMIT 1;
    SELECT delay_reason_type_id INTO v_drt_id FROM delay_reason_type LIMIT 1;

    CALL sp_report_delay(
        v_fs_id,
        v_drt_id,
        45,
        'Espera de tripulación por retraso de vuelo previo'
    );
END $$;

SELECT * FROM flight_delay ORDER BY created_at DESC LIMIT 1;
*/
