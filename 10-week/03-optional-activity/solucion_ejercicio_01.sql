-- =============================================================================
-- SOLUCIÓN EJERCICIO 01 - FLUJO DE CHECK-IN Y TRAZABILIDAD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- REQUERIMIENTO 1: Consulta con INNER JOIN de al menos 5 tablas
-- PROPÓSITO: Listar la trazabilidad básica de pasajeros por vuelo.
-- -----------------------------------------------------------------------------
-- (La ejecución de esta consulta se encuentra al final del script para 
-- mostrar los datos insertados en la prueba).


-- -----------------------------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT
-- PROPÓSITO: Automatizar la creación del pase de abordar (boarding_pass)
--            cuando se registra un check_in.
-- -----------------------------------------------------------------------------

-- 1. Función auxiliar para el trigger
CREATE OR REPLACE FUNCTION fn_generate_boarding_pass()
RETURNS TRIGGER AS $$
BEGIN
    -- Se inserta automáticamente el pase de abordar asociado al check-in
    -- Los códigos se generan de forma dinámica para cumplir con la integridad
    INSERT INTO boarding_pass (
        check_in_id,
        boarding_pass_code,
        barcode_value,
        issued_at
    ) VALUES (
        NEW.check_in_id,
        'BP-' || UPPER(SUBSTRING(REPLACE(NEW.check_in_id::text, '-', ''), 1, 10)),
        'BC-' || NEW.check_in_id::text,
        now()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Definición del trigger
DROP TRIGGER IF EXISTS trg_after_check_in_insert ON check_in;
CREATE TRIGGER trg_after_check_in_insert
AFTER INSERT ON check_in
FOR EACH ROW
EXECUTE FUNCTION fn_generate_boarding_pass();


-- -----------------------------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento Almacenado
-- PROPÓSITO: Encapsular el proceso de registro de un check-in.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_register_check_in(
    p_ticket_segment_id uuid,
    p_check_in_status_id uuid,
    p_boarding_group_id uuid,
    p_checked_in_by_user_id uuid
)
AS $$
BEGIN
    -- Registro del check-in. Esto disparará el trigger trg_after_check_in_insert.
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
        p_checked_in_by_user_id,
        now()
    );
    
    RAISE NOTICE 'Check-in registrado exitosamente para el segmento %', p_ticket_segment_id;
END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- SCRIPTS DE PRUEBA Y DEMOSTRACIÓN (REQUERIMIENTOS 4, 5, 6, 7)
-- -----------------------------------------------------------------------------

-- NOTA: Para que estos scripts funcionen, se requiere que existan datos base.
-- A continuación se presenta un bloque de inserción de datos mínimos necesarios.

DO $$
DECLARE
    v_person_id uuid;
    v_person_type_id uuid;
    v_country_id uuid;
    v_continent_id uuid;
    v_airline_id uuid;
    v_currency_id uuid;
    v_status_id uuid;
    v_user_account_id uuid;
    v_airport_origin_id uuid;
    v_airport_dest_id uuid;
    v_aircraft_id uuid;
    v_aircraft_model_id uuid;
    v_manufacturer_id uuid;
    v_flight_id uuid;
    v_flight_segment_id uuid;
    v_reservation_id uuid;
    v_res_passenger_id uuid;
    v_fare_id uuid;
    v_fare_class_id uuid;
    v_cabin_class_id uuid;
    v_sale_id uuid;
    v_ticket_id uuid;
    v_ticket_segment_id uuid;
    v_check_in_status_id uuid;
    v_boarding_group_id uuid;
    v_sale_channel_id uuid;
BEGIN
    -- 1. Geografia mínima
    INSERT INTO continent (continent_code, continent_name) VALUES ('SA', 'South America') ON CONFLICT (continent_code) DO UPDATE SET continent_name = EXCLUDED.continent_name RETURNING continent_id INTO v_continent_id;
    
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name) VALUES (v_continent_id, 'CO', 'COL', 'Colombia') ON CONFLICT (iso_alpha2) DO UPDATE SET country_name = EXCLUDED.country_name RETURNING country_id INTO v_country_id;

    -- 2. Aerolínea y Moneda
    INSERT INTO currency (iso_currency_code, currency_name, currency_symbol) VALUES ('COP', 'Peso Colombiano', '$') ON CONFLICT (iso_currency_code) DO UPDATE SET currency_name = EXCLUDED.currency_name RETURNING currency_id INTO v_currency_id;
    
    INSERT INTO airline (home_country_id, airline_code, airline_name, iata_code) VALUES (v_country_id, 'AVA', 'Avianca', 'AV') ON CONFLICT (airline_code) DO UPDATE SET airline_name = EXCLUDED.airline_name RETURNING airline_id INTO v_airline_id;

    -- 3. Persona y Usuario
    INSERT INTO person_type (type_code, type_name) VALUES ('PAX', 'Pasajero') ON CONFLICT (type_code) DO UPDATE SET type_name = EXCLUDED.type_name RETURNING person_type_id INTO v_person_type_id;
    
    INSERT INTO person (person_type_id, first_name, last_name, gender_code) VALUES (v_person_type_id, 'JUAN', 'PEREZ', 'M') RETURNING person_id INTO v_person_id;
    
    INSERT INTO user_status (status_code, status_name) VALUES ('ACT', 'Activo') ON CONFLICT (status_code) DO UPDATE SET status_name = EXCLUDED.status_name RETURNING user_status_id INTO v_status_id;
    
    INSERT INTO user_account (person_id, user_status_id, username, password_hash) VALUES (v_person_id, v_status_id, 'jperez' || floor(random()*1000)::text, 'hash') RETURNING user_account_id INTO v_user_account_id;

    -- 4. Infraestructura y Vuelo
    DECLARE
        v_tz_id uuid;
        v_sp_id uuid;
        v_city_id uuid;
        v_dist_id uuid;
        v_addr_id uuid;
    BEGIN
        INSERT INTO time_zone (time_zone_name, utc_offset_minutes) VALUES ('America/Bogota', -300) ON CONFLICT (time_zone_name) DO UPDATE SET utc_offset_minutes = EXCLUDED.utc_offset_minutes RETURNING time_zone_id INTO v_tz_id;
        
        INSERT INTO state_province (country_id, state_name) VALUES (v_country_id, 'Bogota D.C.') ON CONFLICT (country_id, state_name) DO UPDATE SET state_name = EXCLUDED.state_name RETURNING state_province_id INTO v_sp_id;
        
        INSERT INTO city (state_province_id, time_zone_id, city_name) VALUES (v_sp_id, v_tz_id, 'Bogota') ON CONFLICT (state_province_id, city_name) DO UPDATE SET city_name = EXCLUDED.city_name RETURNING city_id INTO v_city_id;
        
        INSERT INTO district (city_id, district_name) VALUES (v_city_id, 'Fontibon') ON CONFLICT (city_id, district_name) DO UPDATE SET district_name = EXCLUDED.district_name RETURNING district_id INTO v_dist_id;
        
        INSERT INTO address (district_id, address_line_1) VALUES (v_dist_id, 'Aeropuerto El Dorado ' || floor(random()*1000)::text) RETURNING address_id INTO v_addr_id;
        
        INSERT INTO airport (address_id, airport_name, iata_code) VALUES (v_addr_id, 'El Dorado', 'BOG') ON CONFLICT (iata_code) DO UPDATE SET airport_name = EXCLUDED.airport_name RETURNING airport_id INTO v_airport_origin_id;
        
        INSERT INTO airport (address_id, airport_name, iata_code) VALUES (v_addr_id, 'Jose Maria Cordova', 'MDE') ON CONFLICT (iata_code) DO UPDATE SET airport_name = EXCLUDED.airport_name RETURNING airport_id INTO v_airport_dest_id;
    END;

    INSERT INTO aircraft_manufacturer (manufacturer_name) VALUES ('Airbus') ON CONFLICT (manufacturer_name) DO UPDATE SET manufacturer_name = EXCLUDED.manufacturer_name RETURNING aircraft_manufacturer_id INTO v_manufacturer_id;
    
    INSERT INTO aircraft_model (aircraft_manufacturer_id, model_code, model_name) VALUES (v_manufacturer_id, 'A320', 'Airbus A320') ON CONFLICT (aircraft_manufacturer_id, model_code) DO UPDATE SET model_name = EXCLUDED.model_name RETURNING aircraft_model_id INTO v_aircraft_model_id;
    
    INSERT INTO aircraft (airline_id, aircraft_model_id, registration_number, serial_number) VALUES (v_airline_id, v_aircraft_model_id, 'HK-' || floor(random()*9000+1000)::text, 'SN-' || floor(random()*1000000)::text) RETURNING aircraft_id INTO v_aircraft_id;

    INSERT INTO flight_status (status_code, status_name) VALUES ('SCH', 'Scheduled') ON CONFLICT (status_code) DO UPDATE SET status_name = EXCLUDED.status_name RETURNING flight_status_id INTO v_status_id;
    
    INSERT INTO flight (airline_id, aircraft_id, flight_status_id, flight_number, service_date) VALUES (v_airline_id, v_aircraft_id, v_status_id, 'AV' || floor(random()*9000+1000)::text, current_date + 1) RETURNING flight_id INTO v_flight_id;
    
    INSERT INTO flight_segment (flight_id, origin_airport_id, destination_airport_id, segment_number, scheduled_departure_at, scheduled_arrival_at) 
    VALUES (v_flight_id, v_airport_origin_id, v_airport_dest_id, 1, current_date + interval '1 day 08:00', current_date + interval '1 day 09:00') RETURNING flight_segment_id INTO v_flight_segment_id;

    -- 5. Reserva y Tiquete
    INSERT INTO reservation_status (status_code, status_name) VALUES ('CONF', 'Confirmed') ON CONFLICT (status_code) DO UPDATE SET status_name = EXCLUDED.status_name RETURNING reservation_status_id INTO v_status_id; -- Reusing v_status_id
    
    INSERT INTO sale_channel (channel_code, channel_name) VALUES ('WEB', 'Web Site') ON CONFLICT (channel_code) DO UPDATE SET channel_name = EXCLUDED.channel_name RETURNING sale_channel_id INTO v_sale_channel_id;

    INSERT INTO reservation (reservation_status_id, sale_channel_id, reservation_code, booked_at) 
    VALUES (v_status_id, v_sale_channel_id, 'RES-' || floor(random()*900000+100000)::text, now()) RETURNING reservation_id INTO v_reservation_id;
    
    INSERT INTO reservation_passenger (reservation_id, person_id, passenger_sequence_no, passenger_type) 
    VALUES (v_reservation_id, v_person_id, 1, 'ADULT') RETURNING reservation_passenger_id INTO v_res_passenger_id;

    INSERT INTO cabin_class (class_code, class_name) VALUES ('Y', 'Economy') ON CONFLICT (class_code) DO UPDATE SET class_name = EXCLUDED.class_name RETURNING cabin_class_id INTO v_cabin_class_id;
    
    INSERT INTO fare_class (cabin_class_id, fare_class_code, fare_class_name) VALUES (v_cabin_class_id, 'PROMO', 'Promo Fare') ON CONFLICT (fare_class_code) DO UPDATE SET fare_class_name = EXCLUDED.fare_class_name RETURNING fare_class_id INTO v_fare_class_id;
    
    INSERT INTO fare (airline_id, origin_airport_id, destination_airport_id, fare_class_id, currency_id, fare_code, base_amount, valid_from) 
    VALUES (v_airline_id, v_airport_origin_id, v_airport_dest_id, v_fare_class_id, v_currency_id, 'F-' || floor(random()*9000+1000)::text, 100000, current_date) RETURNING fare_id INTO v_fare_id;

    INSERT INTO sale (reservation_id, currency_id, sale_code, sold_at) VALUES (v_reservation_id, v_currency_id, 'S-' || floor(random()*900000+100000)::text, now()) RETURNING sale_id INTO v_sale_id;
    
    INSERT INTO ticket_status (status_code, status_name) VALUES ('OK', 'Valid') ON CONFLICT (status_code) DO UPDATE SET status_name = EXCLUDED.status_name RETURNING ticket_status_id INTO v_status_id; -- Reusing v_status_id
    
    INSERT INTO ticket (sale_id, reservation_passenger_id, fare_id, ticket_status_id, ticket_number, issued_at) 
    VALUES (v_sale_id, v_res_passenger_id, v_fare_id, v_status_id, floor(random()*10000000000000)::text, now()) RETURNING ticket_id INTO v_ticket_id;
    
    INSERT INTO ticket_segment (ticket_id, flight_segment_id, segment_sequence_no) 
    VALUES (v_ticket_id, v_flight_segment_id, 1) RETURNING ticket_segment_id INTO v_ticket_segment_id;

    -- 6. Preparación para Check-in
    INSERT INTO check_in_status (status_code, status_name) VALUES ('DONE', 'Checked In') ON CONFLICT (status_code) DO UPDATE SET status_name = EXCLUDED.status_name RETURNING check_in_status_id INTO v_check_in_status_id;
    
    INSERT INTO boarding_group (group_code, group_name, sequence_no) VALUES ('A', 'Group A', 1) ON CONFLICT (group_code) DO UPDATE SET group_name = EXCLUDED.group_name RETURNING boarding_group_id INTO v_boarding_group_id;

    -- INVOCACIÓN DEL PROCEDIMIENTO ALMACENADO (REQUERIMIENTO 7 y 8)
    -- Se corrigió el error de subconsulta en el argumento del CALL
    CALL sp_register_check_in(
        v_ticket_segment_id,
        v_check_in_status_id,
        v_boarding_group_id,
        v_user_account_id
    );

    RAISE NOTICE '--- PRUEBA FINALIZADA ---';
END $$;


-- -----------------------------------------------------------------------------
-- CONSULTAS DE VALIDACIÓN (REQUERIMIENTO 7 Y PRUEBA DEL TRIGGER)
-- -----------------------------------------------------------------------------

-- 1. Verificar el registro en check_in
SELECT * FROM check_in;

-- 2. Verificar que el TRIGGER generó automáticamente el boarding_pass
SELECT * FROM boarding_pass;

-- 3. Consulta de trazabilidad completa (Requirement 1 nuevamente sobre datos reales)
SELECT 
    r.reservation_code,
    f.flight_number,
    p.first_name || ' ' || p.last_name AS passenger,
    t.ticket_number,
    ci.checked_in_at,
    bp.boarding_pass_code
FROM reservation r
JOIN reservation_passenger rp ON r.reservation_id = rp.reservation_id
JOIN person p ON rp.person_id = p.person_id
JOIN ticket t ON rp.reservation_passenger_id = t.reservation_passenger_id
JOIN ticket_segment ts ON t.ticket_id = ts.ticket_id
JOIN check_in ci ON ts.ticket_segment_id = ci.ticket_segment_id
JOIN boarding_pass bp ON ci.check_in_id = bp.check_in_id
JOIN flight_segment fs ON ts.flight_segment_id = fs.flight_segment_id
JOIN flight f ON fs.flight_id = f.flight_id;
