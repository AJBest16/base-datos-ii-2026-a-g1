-- TABLA
CREATE TABLE IF NOT EXISTS matricula (
    id SERIAL PRIMARY KEY,
    estu_id INT,
    asig_id INT,
    nota NUMERIC,
    estado TEXT,
    fecha TIMESTAMP
);

-- PROCEDIMIENTO
CREATE OR REPLACE PROCEDURE sp_registrar_nota_final(id_recibido INT, nota_nueva NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar si existe
    IF NOT EXISTS (SELECT 1 FROM matricula WHERE id = id_recibido) THEN
        RAISE EXCEPTION 'ID no existe';
    END IF;

    -- Validar nota (0 a 5)
    IF nota_nueva < 0 OR nota_nueva > 5 THEN
        RAISE EXCEPTION 'Nota invalida';
    END IF;

    -- Guardar cambios
    UPDATE matricula 
    SET nota = nota_nueva, estado = 'FINALIZADA', fecha = NOW()
    WHERE id = id_recibido;
END;
$$;

-- PRUEBAS
INSERT INTO matricula (estu_id, asig_id) VALUES (1, 10);

-- 1. Exito
CALL sp_registrar_nota_final(1, 4.0);

-- 2. Error ID
-- CALL sp_registrar_nota_final(99, 3.0);

-- 3. Error Nota
-- CALL sp_registrar_nota_final(1, 6.0);