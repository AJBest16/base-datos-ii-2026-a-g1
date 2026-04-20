-- =============================================================================
-- Solución Ejercicio 03 - Facturación e integración de impuestos
-- =============================================================================

-- 1. Consulta SQL con INNER JOIN (Trazabilidad de facturación)
SELECT 
    s.sale_code AS codigo_venta,
    i.invoice_number AS numero_factura,
    ist.status_name AS estado_factura,
    il.line_number AS linea,
    il.line_description AS descripcion,
    il.quantity AS cantidad,
    il.unit_price AS precio_unitario,
    t.tax_name AS impuesto_aplicado,
    c.iso_currency_code AS moneda
FROM sale s
INNER JOIN invoice i ON s.sale_id = i.sale_id
INNER JOIN invoice_status ist ON i.invoice_status_id = ist.invoice_status_id
INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
INNER JOIN tax t ON il.tax_id = t.tax_id
INNER JOIN currency c ON i.currency_id = c.currency_id
ORDER BY i.issued_at DESC, il.line_number;

-- 2. Trigger AFTER (Actualización de trazabilidad en cabecera de factura)
CREATE OR REPLACE FUNCTION fn_tr_invoice_line_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar las notas de la factura para dejar trazabilidad de la última línea
    UPDATE invoice 
    SET notes = COALESCE(notes, '') || CHR(10) || 'Línea registrada: ' || NEW.line_description || ' (Cant: ' || NEW.quantity || ')',
        updated_at = NOW()
    WHERE invoice_id = NEW.invoice_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_invoice_line_after_insert
AFTER INSERT ON invoice_line
FOR EACH ROW
EXECUTE FUNCTION fn_tr_invoice_line_after_insert();

-- 3. Procedimiento Almacenado (Registro de Línea Facturable)
CREATE OR REPLACE PROCEDURE sp_register_invoice_line(
    p_invoice_id UUID,
    p_tax_id UUID,
    p_line_number INTEGER,
    p_description VARCHAR(200),
    p_quantity NUMERIC(12, 2),
    p_unit_price NUMERIC(12, 2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO invoice_line (
        invoice_id,
        tax_id,
        line_number,
        line_description,
        quantity,
        unit_price
    ) VALUES (
        p_invoice_id,
        p_tax_id,
        p_line_number,
        p_description,
        p_quantity,
        p_unit_price
    );
END;
$$;

-- 4. Script de prueba y validación
/*
DO $$
DECLARE
    v_invoice_id UUID;
    v_tax_id UUID;
BEGIN
    -- Seleccionar datos base
    SELECT invoice_id INTO v_invoice_id FROM invoice LIMIT 1;
    SELECT tax_id INTO v_tax_id FROM tax WHERE tax_code = 'IVA' LIMIT 1;

    -- Registrar nueva línea vía procedimiento
    CALL sp_register_invoice_line(
        v_invoice_id,
        v_tax_id,
        10,
        'Servicios complementarios de equipaje',
        1.00,
        25.50
    );
END $$;

-- Validar resultado
SELECT * FROM invoice_line ORDER BY created_at DESC LIMIT 1;
SELECT notes FROM invoice WHERE invoice_id = (SELECT invoice_id FROM invoice_line ORDER BY created_at DESC LIMIT 1);
*/
