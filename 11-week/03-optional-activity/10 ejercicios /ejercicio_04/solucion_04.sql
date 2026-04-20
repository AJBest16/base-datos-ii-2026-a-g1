-- =============================================================================
-- Solución Ejercicio 04 - Fidelización y Gestión de Millas
-- =============================================================================

-- 1. Consulta SQL con INNER JOIN (Estado de fidelización del cliente)
SELECT 
    p.first_name || ' ' || p.last_name AS cliente,
    la.account_number AS numero_cuenta,
    lp.program_name AS programa,
    lt.tier_name AS nivel_actual,
    mt.transaction_type AS tipo_movimiento,
    mt.miles_delta AS millas,
    mt.occurred_at AS fecha_actividad,
    c.iso_currency_code AS moneda_programa
FROM customer cu
INNER JOIN person p ON cu.person_id = p.person_id
INNER JOIN loyalty_account la ON cu.customer_id = la.customer_id
INNER JOIN loyalty_program lp ON la.loyalty_program_id = lp.loyalty_program_id
INNER JOIN loyalty_tier lt ON lp.loyalty_program_id = lt.loyalty_program_id
INNER JOIN miles_transaction mt ON la.loyalty_account_id = mt.loyalty_account_id
INNER JOIN currency c ON lp.default_currency_id = c.currency_id
ORDER BY mt.occurred_at DESC;

-- 2. Trigger AFTER (Actualización de nivel por acumulación)
CREATE OR REPLACE FUNCTION fn_tr_miles_transaction_after_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_total_miles INTEGER;
    v_new_tier_id UUID;
BEGIN
    -- Calcular total de millas actuales de la cuenta
    SELECT SUM(miles_delta) INTO v_total_miles 
    FROM miles_transaction 
    WHERE loyalty_account_id = NEW.loyalty_account_id;

    -- Buscar si califica para un nuevo nivel basado en millas
    SELECT loyalty_tier_id INTO v_new_tier_id
    FROM loyalty_tier lt
    INNER JOIN loyalty_account la ON lt.loyalty_program_id = la.loyalty_program_id
    WHERE la.loyalty_account_id = NEW.loyalty_account_id
      AND lt.required_miles <= v_total_miles
    ORDER BY lt.priority_level DESC
    LIMIT 1;

    -- Si califica para un nivel diferente al actual, registrar cambio
    IF v_new_tier_id IS NOT NULL THEN
        INSERT INTO loyalty_account_tier (
            loyalty_account_id,
            loyalty_tier_id,
            assigned_at
        ) VALUES (
            NEW.loyalty_account_id,
            v_new_tier_id,
            NOW()
        ) ON CONFLICT DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_miles_transaction_after_insert
AFTER INSERT ON miles_transaction
FOR EACH ROW
EXECUTE FUNCTION fn_tr_miles_transaction_after_insert();

-- 3. Procedimiento Almacenado (Acumulación de Millas)
CREATE OR REPLACE PROCEDURE sp_add_miles(
    p_loyalty_account_id UUID,
    p_miles_delta INTEGER,
    p_reference_code VARCHAR(60),
    p_notes TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO miles_transaction (
        loyalty_account_id,
        transaction_type,
        miles_delta,
        occurred_at,
        reference_code,
        notes
    ) VALUES (
        p_loyalty_account_id,
        'EARN',
        p_miles_delta,
        NOW(),
        p_reference_code,
        p_notes
    );
END;
$$;

-- 4. Script de prueba y validación
/*
DO $$
DECLARE
    v_acc_id UUID;
BEGIN
    SELECT loyalty_account_id INTO v_acc_id FROM loyalty_account LIMIT 1;
    
    CALL sp_add_miles(
        v_acc_id,
        5000,
        'FLIGHT-TEST-123',
        'Acumulación por vuelo de prueba'
    );
END $$;

SELECT * FROM miles_transaction WHERE reference_code = 'FLIGHT-TEST-123';
SELECT * FROM loyalty_account_tier ORDER BY assigned_at DESC LIMIT 1;
*/
