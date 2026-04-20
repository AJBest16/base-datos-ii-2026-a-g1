-- =============================================================================
-- Solución Ejercicio 09 - Tarifas y Reservas
-- =============================================================================

-- 1. Consulta SQL con INNER JOIN (Relación tarifa-vuelo-reserva)
SELECT 
    f.fare_code AS codigo_tarifa,
    fc.fare_class_name AS clase,
    cc.class_name AS cabina,
    al.airline_name AS aerolinea,
    r.reservation_code AS codigo_reserva,
    t.ticket_number AS numero_tiquete,
    f.base_amount AS monto_base,
    cur.iso_currency_code AS moneda
FROM fare f
INNER JOIN fare_class fc ON f.fare_class_id = fc.fare_class_id
INNER JOIN cabin_class cc ON fc.cabin_class_id = cc.cabin_class_id
INNER JOIN airline al ON f.airline_id = al.airline_id
INNER JOIN ticket t ON f.fare_id = t.fare_id
INNER JOIN sale s ON t.sale_id = s.sale_id
INNER JOIN reservation r ON s.reservation_id = r.reservation_id
INNER JOIN currency cur ON f.currency_id = cur.currency_id
ORDER BY f.valid_from DESC;

-- 2. Trigger AFTER (Control de cambios en tarifas)
CREATE OR REPLACE FUNCTION fn_tr_fare_after_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Si el precio base cambia, registrar la auditoría (simulado en updated_at)
    IF NEW.base_amount <> OLD.base_amount THEN
        NEW.updated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Nota: Como es AFTER, no podemos modificar NEW. Usaremos un trigger para actualizar updated_at explícitamente si se desea, 
-- pero el requerimiento pide un trigger AFTER. Usaremos el trigger para actualizar una tabla relacionada o dejar evidencia.
-- En este caso, actualizaremos la aerolínea asociada (updated_at) para indicar cambio en sus tarifas.
CREATE OR REPLACE FUNCTION fn_tr_fare_after_update_evidence()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE airline 
    SET updated_at = NOW()
    WHERE airline_id = NEW.airline_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_fare_after_update
AFTER UPDATE ON fare
FOR EACH ROW
EXECUTE FUNCTION fn_tr_fare_after_update_evidence();

-- 3. Procedimiento Almacenado (Actualización de Tarifa)
CREATE OR REPLACE PROCEDURE sp_update_fare_amount(
    p_fare_code VARCHAR(30),
    p_new_amount NUMERIC(12, 2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE fare 
    SET base_amount = p_new_amount,
        updated_at = NOW()
    WHERE fare_code = p_fare_code;
END;
$$;

-- 4. Script de prueba y validación
/*
DO $$
DECLARE
    v_f_code VARCHAR(30);
BEGIN
    SELECT fare_code INTO v_f_code FROM fare LIMIT 1;

    CALL sp_update_fare_amount(
        v_f_code,
        299.99
    );
END $$;

SELECT * FROM fare WHERE base_amount = 299.99;
*/
