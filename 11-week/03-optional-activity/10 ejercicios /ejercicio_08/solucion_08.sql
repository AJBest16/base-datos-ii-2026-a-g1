-- =============================================================================
-- Solución Ejercicio 08 - Seguridad y Roles de Usuario
-- =============================================================================

-- 1. Consulta SQL con INNER JOIN (Privilegios y roles por usuario)
SELECT 
    ua.username AS usuario,
    p.first_name || ' ' || p.last_name AS persona,
    sr.role_name AS rol,
    sr.role_code AS codigo_rol,
    us.status_name AS estado_cuenta,
    ur.assigned_at AS fecha_asignacion,
    ua.last_login_at AS ultimo_ingreso
FROM user_account ua
INNER JOIN person p ON ua.person_id = p.person_id
INNER JOIN user_status us ON ua.user_status_id = us.user_status_id
INNER JOIN user_role ur ON ua.user_account_id = ur.user_account_id
INNER JOIN security_role sr ON ur.security_role_id = sr.security_role_id
ORDER BY ua.username, ur.assigned_at DESC;

-- 2. Trigger AFTER (Trazabilidad de asignación de seguridad)
CREATE OR REPLACE FUNCTION fn_tr_user_role_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar la marca de tiempo de la cuenta de usuario al cambiar sus roles
    UPDATE user_account 
    SET updated_at = NOW()
    WHERE user_account_id = NEW.user_account_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_user_role_after_insert
AFTER INSERT ON user_role
FOR EACH ROW
EXECUTE FUNCTION fn_tr_user_role_after_insert();

-- 3. Procedimiento Almacenado (Asignación de Rol)
CREATE OR REPLACE PROCEDURE sp_assign_role(
    p_username VARCHAR(80),
    p_role_code VARCHAR(30),
    p_assigned_by_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_role_id UUID;
BEGIN
    SELECT user_account_id INTO v_user_id FROM user_account WHERE username = p_username;
    SELECT security_role_id INTO v_role_id FROM security_role WHERE role_code = p_role_code;

    IF v_user_id IS NOT NULL AND v_role_id IS NOT NULL THEN
        INSERT INTO user_role (
            user_account_id,
            security_role_id,
            assigned_at,
            assigned_by_user_id
        ) VALUES (
            v_user_id,
            v_role_id,
            NOW(),
            p_assigned_by_id
        ) ON CONFLICT (user_account_id, security_role_id) DO NOTHING;
    END IF;
END;
$$;

-- 4. Script de prueba y validación
/*
DO $$
DECLARE
    v_admin_id UUID;
BEGIN
    SELECT user_account_id INTO v_admin_id FROM user_account LIMIT 1;

    CALL sp_assign_role(
        'admin', -- Asumiendo que existe un usuario admin
        'SUPER_ADMIN',
        v_admin_id
    );
END $$;

SELECT * FROM user_role ORDER BY assigned_at DESC LIMIT 1;
*/
