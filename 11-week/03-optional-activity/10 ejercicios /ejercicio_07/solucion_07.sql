-- =============================================================================
-- Solución Ejercicio 07 - Asientos y Equipaje
-- =============================================================================

-- 1. Consulta SQL con INNER JOIN (Estado de servicios por tiquete)
SELECT 
    t.ticket_number AS numero_tiquete,
    ts.segment_sequence_no AS secuencia,
    fs.scheduled_departure_at AS salida,
    aseat.seat_row_number || aseat.seat_column_code AS asiento,
    b.baggage_tag AS etiqueta_equipaje,
    b.weight_kg AS peso_kg,
    b.baggage_status AS estado_equipaje,
    f.flight_number AS vuelo
FROM ticket t
INNER JOIN ticket_segment ts ON t.ticket_id = ts.ticket_id
INNER JOIN seat_assignment sa ON ts.ticket_segment_id = sa.ticket_segment_id
INNER JOIN aircraft_seat aseat ON sa.aircraft_seat_id = aseat.aircraft_seat_id
INNER JOIN baggage b ON ts.ticket_segment_id = b.ticket_segment_id
INNER JOIN flight_segment fs ON ts.flight_segment_id = fs.flight_segment_id
INNER JOIN flight f ON fs.flight_id = f.flight_id
ORDER BY t.issued_at DESC;

-- 2. Trigger AFTER (Control de peso acumulado o trazabilidad de equipaje)
CREATE OR REPLACE FUNCTION fn_tr_baggage_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar el estado de registro en el segmento del ticket
    UPDATE ticket_segment 
    SET updated_at = NOW()
    WHERE ticket_segment_id = NEW.ticket_segment_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_baggage_after_insert
AFTER INSERT ON baggage
FOR EACH ROW
EXECUTE FUNCTION fn_tr_baggage_after_insert();

-- 3. Procedimiento Almacenado (Registro de Equipaje)
CREATE OR REPLACE PROCEDURE sp_register_baggage(
    p_ticket_segment_id UUID,
    p_baggage_tag VARCHAR(30),
    p_baggage_type VARCHAR(20),
    p_weight_kg NUMERIC(6, 2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO baggage (
        ticket_segment_id,
        baggage_tag,
        baggage_type,
        baggage_status,
        weight_kg,
        checked_at
    ) VALUES (
        p_ticket_segment_id,
        p_baggage_tag,
        p_baggage_type,
        'REGISTERED',
        p_weight_kg,
        NOW()
    );
END;
$$;

-- 4. Script de prueba y validación
/*
DO $$
DECLARE
    v_ts_id UUID;
BEGIN
    SELECT ticket_segment_id INTO v_ts_id FROM ticket_segment LIMIT 1;

    CALL sp_register_baggage(
        v_ts_id,
        'TAG-123456789',
        'CHECKED',
        23.50
    );
END $$;

SELECT * FROM baggage WHERE baggage_tag = 'TAG-123456789';
*/
