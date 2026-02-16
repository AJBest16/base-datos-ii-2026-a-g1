-- =========================================
-- BASE DE DATOS: REPASO FUTBOL
-- =========================================
DROP DATABASE IF EXISTS repaso_futbol;
CREATE DATABASE repaso_futbol;
USE repaso_futbol;

-- =========================================
-- TABLA JUGADOR
-- =========================================
CREATE TABLE jugador (
  id_jugador INT AUTO_INCREMENT PRIMARY KEY,
  nombre     VARCHAR(80) NOT NULL,
  posicion   VARCHAR(50),
  correo     VARCHAR(120) UNIQUE
);

-- =========================================
-- TABLA EQUIPO
-- =========================================
CREATE TABLE equipo (
  id_equipo INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  pais   VARCHAR(60)
);

-- =========================================
-- TABLA CONTRATO
-- =========================================
CREATE TABLE contrato (
  id_contrato INT AUTO_INCREMENT PRIMARY KEY,
  id_jugador  INT NOT NULL,
  id_equipo   INT NOT NULL,
  temporada   VARCHAR(10) NOT NULL,
  salario     DECIMAL(10,2),
  fecha_firma DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_jugador) REFERENCES jugador(id_jugador),
  FOREIGN KEY (id_equipo)  REFERENCES equipo(id_equipo)
);

-- =========================================
-- INSERTAR JUGADORES
-- =========================================
INSERT INTO jugador (nombre, posicion, correo) VALUES
('Lionel Messi', 'Delantero', 'messi@futbol.com'),
('Cristiano Ronaldo', 'Delantero', 'cristiano@futbol.com'),
('Kylian Mbappé', 'Delantero', 'mbappe@futbol.com'),
('Kevin De Bruyne', 'Mediocampista', 'debruyne@futbol.com'),
('Erling Haaland', 'Delantero', 'haaland@futbol.com'),
('Neymar Jr', 'Delantero', 'neymar@futbol.com'); -- 👈 SIN CONTRATO

-- =========================================
-- INSERTAR EQUIPOS
-- =========================================
INSERT INTO equipo (nombre, pais) VALUES
('Inter Miami', 'Estados Unidos'),
('Al Nassr', 'Arabia Saudita'),
('Paris Saint-Germain', 'Francia'),
('Manchester City', 'Inglaterra');

-- =========================================
-- INSERTAR CONTRATOS
-- (Neymar NO tiene contrato)
-- =========================================
INSERT INTO contrato (id_jugador, id_equipo, temporada, salario, fecha_firma) VALUES
(1, 1, '2024', 50000000, '2024-01-15'),
(2, 2, '2024', 45000000, '2024-01-20'),
(3, 3, '2024', 48000000, '2024-02-01'),
(4, 4, '2024', 42000000, '2024-02-10'),
(5, 4, '2024', 52000000, '2024-02-12');

-- =========================================
-- CONSULTA A: INNER JOIN
-- Detalle de contratos de jugadores
-- =========================================
SELECT
  j.nombre   AS jugador,
  j.posicion,
  e.nombre   AS equipo,
  e.pais,
  c.temporada,
  c.salario
FROM contrato c
INNER JOIN jugador j ON j.id_jugador = c.id_jugador
INNER JOIN equipo  e ON e.id_equipo  = c.id_equipo
ORDER BY c.salario DESC;

-- =========================================
-- CONSULTA B: LEFT JOIN
-- Jugadores SIN contrato
-- =========================================
SELECT
  j.id_jugador,
  j.nombre
FROM jugador j
LEFT JOIN contrato c ON c.id_jugador = j.id_jugador
WHERE c.id_contrato IS NULL;

-- =========================================
-- CONSULTA C: GROUP BY + HAVING
-- Equipos con más de un contrato
-- =========================================
SELECT
  e.nombre AS equipo,
  COUNT(*) AS total_contratos
FROM contrato c
INNER JOIN equipo e ON e.id_equipo = c.id_equipo
GROUP BY e.nombre
HAVING COUNT(*) > 1;
