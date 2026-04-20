-- =============================================================================
-- Solución Ejercicio 10 - Identidad y Contacto de Pasajeros
-- =============================================================================

-- 1. Consulta SQL con INNER JOIN (Perfil completo del pasajero)
SELECT 
    p.first_name || ' ' || p.last_name AS nombre_completo,
    pt.type_name AS tipo_persona,
    dt.type_name AS tipo_documento,
    pd.document_number AS numero_documento,
    ct.type_name AS tipo_contacto,
    pc.contact_value AS contacto,
    c.country_name AS nacionalidad
FROM person p
INNER JOIN person_type pt ON p.person_type_id = pt.person_type_id
INNER JOIN person_document pd ON p.person_id = pd.person_id
INNER JOIN document_type dt ON pd.document_type_id = dt.document_type_id
INNER JOIN person_contact pc ON p.person_id = pc.person_id
INNER JOIN contact_type ct ON pc.contact_type_id = ct.contact_type_id
LEFT JOIN country c ON p.nationality_country_id = c.country_id
ORDER BY p.last_name, p.first_name;

-- 2. Trigger AFTER (Actualización de trazabilidad de perfil)
CREATE OR REPLACE FUNCTION fn_tr_person_contact_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Al agregar un contacto, marcar la persona como actualizada
    UPDATE person 
    SET updated_at = NOW()
    WHERE person_id = NEW.person_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_person_contact_after_insert
AFTER INSERT ON person_contact
FOR EACH ROW
EXECUTE FUNCTION fn_tr_person_contact_after_insert();

-- 3. Procedimiento Almacenado (Registro de Contacto)
CREATE OR REPLACE PROCEDURE sp_register_person_contact(
    p_person_id UUID,
    p_contact_type_code VARCHAR(20),
    p_contact_value VARCHAR(180),
    p_is_primary BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ct_id UUID;
BEGIN
    SELECT contact_type_id INTO v_ct_id FROM contact_type WHERE type_code = p_contact_type_code;

    IF v_ct_id IS NOT NULL THEN
        INSERT INTO person_contact (
            person_id,
            contact_type_id,
            contact_value,
            is_primary,
            created_at,
            updated_at
        ) VALUES (
            p_person_id,
            v_ct_id,
            p_contact_value,
            p_is_primary,
            NOW(),
            NOW()
        ) ON CONFLICT (person_id, contact_type_id, contact_value) DO NOTHING;
    END IF;
END;
$$;

-- 4. Script de prueba y validación
/*
DO $$
DECLARE
    v_p_id UUID;
BEGIN
    SELECT person_id INTO v_p_id FROM person LIMIT 1;

    CALL sp_register_person_contact(
        v_p_id,
        'EMAIL_PERSONAL',
        'test@example.com',
        true
    );
END $$;

SELECT * FROM person_contact WHERE contact_value = 'test@example.com';
*/
