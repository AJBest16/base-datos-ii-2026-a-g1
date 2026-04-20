-- =============================================================================
-- Solución Ejercicio 01 - Flujo de check-in y trazabilidad comercial
-- =============================================================================

-- 1. Consulta SQL con INNER JOIN (Trazabilidad de pasajeros)
SELECT 
    r.reservation_code AS codigo_reserva,
    f.flight_number AS numero_vuelo,
    f.service_date AS fecha_servicio,
    t.ticket_number AS numero_tiquete,
    rp.passenger_sequence_no AS secuencia_pasajero,
    p.first_name || ' ' || p.last_name AS nombre_pasajero,
    fs.segment_number AS segmento,
    fs.scheduled_departure_at AS salida_programada
FROM reservation r
INNER JOIN reservation_passenger rp ON r.reservation_id = rp.reservation_id
INNER JOIN person p ON rp.person_id = p.person_id
INNER JOIN ticket t ON rp.reservation_passenger_id = t.reservation_passenger_id
INNER JOIN ticket_segment ts ON t.ticket_id = ts.ticket_id
INNER JOIN flight_segment fs ON ts.flight_segment_id = fs.flight_segment_id
INNER JOIN flight f ON fs.flight_id = f.flight_id
ORDER BY f.service_date DESC, f.flight_number, rp.passenger_sequence_no;

-- 2. Trigger AFTER (Automatización de Boarding Pass)
CREATE OR REPLACE FUNCTION fn_tr_check_in_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Generar pase de abordar automáticamente al registrar el check-in
    INSERT INTO boarding_pass (
        check_in_id,
        boarding_pass_code,
        barcode_value,
        issued_at
    ) VALUES (
        NEW.check_in_id,
        'BP-' || UPPER(SUBSTRING(NEW.check_in_id::text, 1, 8)) || TO_CHAR(NOW(), 'YYYYMMDD'),
        'BC-' || NEW.check_in_id::text,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_check_in_after_insert
AFTER INSERT ON check_in
FOR EACH ROW
EXECUTE FUNCTION fn_tr_check_in_after_insert();

-- 3. Procedimiento Almacenado (Registro de Check-in)
CREATE OR REPLACE PROCEDURE sp_register_check_in(
    p_ticket_segment_id UUID,
    p_check_in_status_id UUID,
    p_boarding_group_id UUID,
    p_user_id UUID,
    p_checked_in_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO check_in (
        ticket_segment_id,
        check_in_status_id,
        boarding_group_id,
        checked_in_by_user_id,
        checked_in_at
    ) VALUES (
        p_ticket_segment_id,
        p_check_in_status_id,
        p_boarding_group_id,
        p_user_id,
        p_checked_in_at
    );
END;
$$;

-- 4. Script de prueba y validación
/*
DO $$
DECLARE
    v_ts_id UUID;
    v_status_id UUID;
    v_user_id UUID;
BEGIN
    -- Seleccionar datos existentes para la prueba
    SELECT ticket_segment_id INTO v_ts_id FROM ticket_segment LIMIT 1;
    SELECT check_in_status_id INTO v_status_id FROM check_in_status WHERE status_code = 'COMPLETED' LIMIT 1;
    SELECT user_account_id INTO v_user_id FROM user_account LIMIT 1;

    -- Invocar procedimiento
    CALL sp_register_check_in(
        v_ts_id,
        v_status_id,
        NULL,
        v_user_id,
        NOW()
    );
END $$;

-- Consultas de validación
SELECT * FROM check_in ORDER BY created_at DESC LIMIT 1;
SELECT * FROM boarding_pass ORDER BY created_at DESC LIMIT 1;
*/
