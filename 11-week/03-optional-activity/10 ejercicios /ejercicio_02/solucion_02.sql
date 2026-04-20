-- =============================================================================
-- Solución Ejercicio 02 - Control de pagos y trazabilidad financiera
-- =============================================================================

-- 1. Consulta SQL con INNER JOIN (Flujo consolidado de pagos)
SELECT 
    s.sale_code AS codigo_venta,
    r.reservation_code AS codigo_reserva,
    p.payment_reference AS referencia_pago,
    ps.status_name AS estado_pago,
    pm.method_name AS metodo_pago,
    pt.transaction_reference AS ref_transaccion,
    pt.transaction_type AS tipo_transaccion,
    pt.transaction_amount AS monto_procesado,
    c.iso_currency_code AS moneda
FROM sale s
INNER JOIN reservation r ON s.reservation_id = r.reservation_id
INNER JOIN payment p ON s.sale_id = p.sale_id
INNER JOIN payment_status ps ON p.payment_status_id = ps.payment_status_id
INNER JOIN payment_method pm ON p.payment_method_id = pm.payment_method_id
INNER JOIN payment_transaction pt ON p.payment_id = pt.payment_id
INNER JOIN currency c ON p.currency_id = c.currency_id
ORDER BY s.sold_at DESC, p.created_at;

-- 2. Trigger AFTER (Gestión automática de Devoluciones)
CREATE OR REPLACE FUNCTION fn_tr_payment_transaction_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Si la transacción es de tipo REFUND, crear registro en la tabla refund
    IF NEW.transaction_type = 'REFUND' THEN
        INSERT INTO refund (
            payment_id,
            refund_reference,
            amount,
            requested_at,
            processed_at,
            refund_reason
        ) VALUES (
            NEW.payment_id,
            'REF-' || UPPER(SUBSTRING(NEW.payment_transaction_id::text, 1, 8)),
            NEW.transaction_amount,
            NOW(),
            NOW(),
            'Generado automáticamente por transacción de reembolso: ' || NEW.transaction_reference
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_payment_transaction_after_insert
AFTER INSERT ON payment_transaction
FOR EACH ROW
EXECUTE FUNCTION fn_tr_payment_transaction_after_insert();

-- 3. Procedimiento Almacenado (Registro de Transacción de Pago)
CREATE OR REPLACE PROCEDURE sp_register_payment_transaction(
    p_payment_id UUID,
    p_transaction_reference VARCHAR(60),
    p_transaction_type VARCHAR(20),
    p_transaction_amount NUMERIC(12, 2),
    p_provider_message TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO payment_transaction (
        payment_id,
        transaction_reference,
        transaction_type,
        transaction_amount,
        processed_at,
        provider_message
    ) VALUES (
        p_payment_id,
        p_transaction_reference,
        p_transaction_type,
        p_transaction_amount,
        NOW(),
        p_provider_message
    );
END;
$$;

-- 4. Script de prueba y validación
/*
DO $$
DECLARE
    v_payment_id UUID;
BEGIN
    -- Seleccionar un pago existente
    SELECT payment_id INTO v_payment_id FROM payment LIMIT 1;

    -- Registrar una transacción de tipo REFUND para disparar el trigger
    CALL sp_register_payment_transaction(
        v_payment_id,
        'TX-REF-TEST-001',
        'REFUND',
        50.00,
        'Prueba de reembolso automático'
    );
END $$;

-- Validar creación del refund
SELECT * FROM payment_transaction ORDER BY created_at DESC LIMIT 1;
SELECT * FROM refund ORDER BY created_at DESC LIMIT 1;
*/
