-- =====================================================================
-- CONSULTAS BÁSICAS EN ORACLE - ARCHIVO DE EJEMPLO
-- =====================================================================
-- Contenido:
--   1. Creación de tablas
--   2. Inserción de datos
--   3. SELECT básico
--   4. Filtros con WHERE
--   5. Ordenamiento con ORDER BY
--   6. Funciones de agregación y GROUP BY / HAVING
--   7. JOINs
--   8. Subconsultas
--   9. Funciones de texto, número y fecha
--  10. CASE, NVL y DECODE
--  11. Limitar filas (FETCH FIRST / ROWNUM)
--  12. UPDATE, DELETE y transacciones
--  13. Vistas y secuencias
-- =====================================================================


-- =====================================================================
-- 1. CREACIÓN DE TABLAS
-- =====================================================================

CREATE TABLE departamentos (
    id_departamento  NUMBER(4)     PRIMARY KEY,
    nombre           VARCHAR2(50)  NOT NULL,
    ubicacion        VARCHAR2(50)
);

CREATE TABLE empleados (
    id_empleado      NUMBER(6)     PRIMARY KEY,
    nombre           VARCHAR2(50)  NOT NULL,
    apellido         VARCHAR2(50)  NOT NULL,
    email            VARCHAR2(100) UNIQUE,
    fecha_ingreso    DATE          DEFAULT SYSDATE,
    salario          NUMBER(10,2)  CHECK (salario > 0),
    comision         NUMBER(4,2),
    id_departamento  NUMBER(4),
    id_jefe          NUMBER(6),
    CONSTRAINT fk_emp_depto FOREIGN KEY (id_departamento)
        REFERENCES departamentos (id_departamento),
    CONSTRAINT fk_emp_jefe FOREIGN KEY (id_jefe)
        REFERENCES empleados (id_empleado)
);


-- =====================================================================
-- 2. INSERCIÓN DE DATOS
-- =====================================================================

INSERT INTO departamentos VALUES (10, 'Administración', 'Lima');
INSERT INTO departamentos VALUES (20, 'Ventas',         'Arequipa');
INSERT INTO departamentos VALUES (30, 'Tecnología',     'Lima');
INSERT INTO departamentos VALUES (40, 'Recursos Humanos', 'Cusco');

INSERT INTO empleados VALUES (100, 'Ana',    'Torres',  'ana.torres@empresa.com',   DATE '2018-03-15', 9500, NULL, 10, NULL);
INSERT INTO empleados VALUES (101, 'Luis',   'Ramírez', 'luis.ramirez@empresa.com', DATE '2019-07-01', 6200, 0.10, 20, 100);
INSERT INTO empleados VALUES (102, 'María',  'López',   'maria.lopez@empresa.com',  DATE '2020-01-20', 7800, NULL, 30, 100);
INSERT INTO empleados VALUES (103, 'Carlos', 'Gómez',   'carlos.gomez@empresa.com', DATE '2021-05-10', 4500, 0.15, 20, 101);
INSERT INTO empleados VALUES (104, 'Lucía',  'Fernández','lucia.fernandez@empresa.com', DATE '2022-09-05', 5100, NULL, 30, 102);
INSERT INTO empleados VALUES (105, 'Jorge',  'Castro',  'jorge.castro@empresa.com', DATE '2023-02-14', 3900, 0.05, 20, 101);
INSERT INTO empleados VALUES (106, 'Elena',  'Vargas',  NULL,                        DATE '2024-11-30', 4200, NULL, NULL, 100);

COMMIT;


-- =====================================================================
-- 3. SELECT BÁSICO
-- =====================================================================

-- Todas las columnas
SELECT * FROM empleados;

-- Columnas específicas
SELECT nombre, apellido, salario FROM empleados;

-- Alias de columnas y concatenación
SELECT nombre || ' ' || apellido AS nombre_completo,
       salario * 12              AS salario_anual
FROM   empleados;

-- Valores distintos
SELECT DISTINCT id_departamento FROM empleados;

-- Tabla DUAL (útil para cálculos o probar funciones)
SELECT SYSDATE, USER, 2 + 3 AS suma FROM dual;


-- =====================================================================
-- 4. FILTROS CON WHERE
-- =====================================================================

-- Comparación simple
SELECT * FROM empleados WHERE salario > 5000;

-- AND / OR
SELECT * FROM empleados
WHERE  id_departamento = 20
AND    salario >= 4000;

-- BETWEEN (incluye los extremos)
SELECT * FROM empleados WHERE salario BETWEEN 4000 AND 7000;

-- IN
SELECT * FROM empleados WHERE id_departamento IN (10, 30);

-- LIKE (% = cualquier cadena, _ = un solo carácter)
SELECT * FROM empleados WHERE apellido LIKE 'G%';
SELECT * FROM empleados WHERE nombre   LIKE '_u%';

-- Valores nulos
SELECT * FROM empleados WHERE comision IS NULL;
SELECT * FROM empleados WHERE email    IS NOT NULL;

-- Filtro por fecha
SELECT * FROM empleados WHERE fecha_ingreso >= DATE '2021-01-01';


-- =====================================================================
-- 5. ORDENAMIENTO CON ORDER BY
-- =====================================================================

SELECT nombre, salario FROM empleados ORDER BY salario DESC;

-- Varias columnas
SELECT id_departamento, apellido, salario
FROM   empleados
ORDER  BY id_departamento ASC, salario DESC;

-- Controlar dónde quedan los nulos
SELECT nombre, comision FROM empleados ORDER BY comision DESC NULLS LAST;


-- =====================================================================
-- 6. FUNCIONES DE AGREGACIÓN, GROUP BY Y HAVING
-- =====================================================================

SELECT COUNT(*)      AS total_empleados,
       SUM(salario)  AS total_salarios,
       AVG(salario)  AS salario_promedio,
       MIN(salario)  AS salario_minimo,
       MAX(salario)  AS salario_maximo
FROM   empleados;

-- Agrupar por departamento
SELECT id_departamento,
       COUNT(*)              AS cantidad,
       ROUND(AVG(salario),2) AS promedio
FROM   empleados
GROUP  BY id_departamento
ORDER  BY id_departamento;

-- HAVING: filtra grupos (WHERE filtra filas)
SELECT id_departamento, COUNT(*) AS cantidad
FROM   empleados
GROUP  BY id_departamento
HAVING COUNT(*) > 1;


-- =====================================================================
-- 7. JOINS
-- =====================================================================

-- INNER JOIN: solo filas con coincidencia
SELECT e.nombre, e.apellido, d.nombre AS departamento
FROM   empleados e
JOIN   departamentos d ON e.id_departamento = d.id_departamento;

-- LEFT JOIN: todos los empleados, aunque no tengan departamento
SELECT e.nombre, d.nombre AS departamento
FROM   empleados e
LEFT   JOIN departamentos d ON e.id_departamento = d.id_departamento;

-- RIGHT JOIN: todos los departamentos, aunque no tengan empleados
SELECT d.nombre AS departamento, e.nombre
FROM   empleados e
RIGHT  JOIN departamentos d ON e.id_departamento = d.id_departamento;

-- FULL OUTER JOIN
SELECT e.nombre, d.nombre AS departamento
FROM   empleados e
FULL   OUTER JOIN departamentos d ON e.id_departamento = d.id_departamento;

-- SELF JOIN: empleado y su jefe
SELECT e.nombre || ' ' || e.apellido AS empleado,
       j.nombre || ' ' || j.apellido AS jefe
FROM   empleados e
LEFT   JOIN empleados j ON e.id_jefe = j.id_empleado;

-- Sintaxis antigua de Oracle (+) equivalente a LEFT JOIN
SELECT e.nombre, d.nombre
FROM   empleados e, departamentos d
WHERE  e.id_departamento = d.id_departamento (+);


-- =====================================================================
-- 8. SUBCONSULTAS
-- =====================================================================

-- Empleados que ganan más que el promedio
SELECT nombre, salario
FROM   empleados
WHERE  salario > (SELECT AVG(salario) FROM empleados);

-- Subconsulta con IN
SELECT nombre, apellido
FROM   empleados
WHERE  id_departamento IN (SELECT id_departamento
                           FROM   departamentos
                           WHERE  ubicacion = 'Lima');

-- Subconsulta correlacionada: el mejor pagado de cada departamento
SELECT e.nombre, e.salario, e.id_departamento
FROM   empleados e
WHERE  e.salario = (SELECT MAX(e2.salario)
                    FROM   empleados e2
                    WHERE  e2.id_departamento = e.id_departamento);

-- EXISTS: departamentos que tienen al menos un empleado
SELECT d.nombre
FROM   departamentos d
WHERE  EXISTS (SELECT 1 FROM empleados e
               WHERE  e.id_departamento = d.id_departamento);

-- Subconsulta en FROM (vista en línea)
SELECT *
FROM  (SELECT id_departamento, AVG(salario) AS promedio
       FROM   empleados
       GROUP  BY id_departamento)
WHERE  promedio > 5000;

-- WITH (Common Table Expression)
WITH resumen AS (
    SELECT id_departamento, COUNT(*) AS cantidad
    FROM   empleados
    GROUP  BY id_departamento
)
SELECT d.nombre, r.cantidad
FROM   resumen r
JOIN   departamentos d ON d.id_departamento = r.id_departamento;


-- =====================================================================
-- 9. FUNCIONES DE TEXTO, NÚMERO Y FECHA
-- =====================================================================

-- Texto
SELECT UPPER(nombre)            AS mayusculas,
       LOWER(apellido)          AS minusculas,
       INITCAP('hola mundo')    AS capitalizado,
       LENGTH(nombre)           AS longitud,
       SUBSTR(apellido, 1, 3)   AS primeras_letras,
       INSTR(email, '@')        AS posicion_arroba,
       REPLACE(email, 'empresa', 'company') AS email_nuevo,
       TRIM('  texto  ')        AS sin_espacios,
       LPAD(id_empleado, 8, '0') AS codigo
FROM   empleados;

-- Números
SELECT ROUND(1234.567, 2) AS redondeo,
       TRUNC(1234.567, 1) AS truncado,
       CEIL(4.1)          AS techo,
       FLOOR(4.9)         AS piso,
       MOD(10, 3)         AS modulo,
       ABS(-15)           AS absoluto,
       POWER(2, 8)        AS potencia
FROM   dual;

-- Fechas
SELECT nombre,
       fecha_ingreso,
       TO_CHAR(fecha_ingreso, 'DD/MM/YYYY')               AS fecha_formateada,
       TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_ingreso) / 12) AS anios_antiguedad,
       ADD_MONTHS(fecha_ingreso, 6)                       AS seis_meses_despues,
       EXTRACT(YEAR FROM fecha_ingreso)                   AS anio,
       LAST_DAY(fecha_ingreso)                            AS ultimo_dia_mes
FROM   empleados;

-- Conversiones
SELECT TO_DATE('25/12/2025', 'DD/MM/YYYY')  AS a_fecha,
       TO_NUMBER('1500.50')                 AS a_numero,
       TO_CHAR(9500, 'L99,999.00')          AS a_texto_moneda
FROM   dual;


-- =====================================================================
-- 10. CASE, NVL Y DECODE
-- =====================================================================

-- CASE
SELECT nombre, salario,
       CASE
           WHEN salario >= 8000 THEN 'Alto'
           WHEN salario >= 5000 THEN 'Medio'
           ELSE 'Bajo'
       END AS nivel_salarial
FROM   empleados;

-- NVL: reemplaza nulos
SELECT nombre, NVL(comision, 0) AS comision FROM empleados;

-- NVL2(expr, si_no_es_nulo, si_es_nulo)
SELECT nombre, NVL2(comision, 'Con comisión', 'Sin comisión') AS estado
FROM   empleados;

-- COALESCE: primer valor no nulo
SELECT nombre, COALESCE(email, 'sin correo') AS email FROM empleados;

-- DECODE (propio de Oracle)
SELECT nombre,
       DECODE(id_departamento, 10, 'Admin',
                               20, 'Ventas',
                               30, 'TI',
                                   'Otro') AS area
FROM   empleados;


-- =====================================================================
-- 11. LIMITAR FILAS
-- =====================================================================

-- Oracle 12c o superior
SELECT nombre, salario
FROM   empleados
ORDER  BY salario DESC
FETCH  FIRST 3 ROWS ONLY;

-- Paginación (saltar 2, traer 3)
SELECT nombre, salario
FROM   empleados
ORDER  BY salario DESC
OFFSET 2 ROWS FETCH NEXT 3 ROWS ONLY;

-- Versiones anteriores: ROWNUM
SELECT *
FROM  (SELECT nombre, salario FROM empleados ORDER BY salario DESC)
WHERE  ROWNUM <= 3;


-- =====================================================================
-- 12. UPDATE, DELETE Y TRANSACCIONES
-- =====================================================================

-- Aumentar 10% al departamento de Ventas
UPDATE empleados
SET    salario = salario * 1.10
WHERE  id_departamento = 20;

-- Asignar departamento a quien no tiene
UPDATE empleados
SET    id_departamento = 40
WHERE  id_departamento IS NULL;

-- Puntos de guardado
SAVEPOINT antes_de_borrar;

DELETE FROM empleados WHERE id_empleado = 105;

-- Deshacer solo hasta el savepoint
ROLLBACK TO antes_de_borrar;

-- Confirmar cambios
COMMIT;


-- =====================================================================
-- 13. VISTAS Y SECUENCIAS
-- =====================================================================

-- Vista
CREATE OR REPLACE VIEW v_empleados_depto AS
SELECT e.id_empleado,
       e.nombre || ' ' || e.apellido AS empleado,
       d.nombre                      AS departamento,
       e.salario
FROM   empleados e
LEFT   JOIN departamentos d ON e.id_departamento = d.id_departamento;

SELECT * FROM v_empleados_depto WHERE salario > 5000;

-- Secuencia para generar IDs
CREATE SEQUENCE seq_empleados START WITH 200 INCREMENT BY 1;

INSERT INTO empleados (id_empleado, nombre, apellido, salario, id_departamento)
VALUES (seq_empleados.NEXTVAL, 'Pedro', 'Silva', 4800, 30);

SELECT seq_empleados.CURRVAL FROM dual;

COMMIT;


-- =====================================================================
-- LIMPIEZA (descomentar para eliminar los objetos de ejemplo)
-- =====================================================================
-- DROP VIEW v_empleados_depto;
-- DROP SEQUENCE seq_empleados;
-- DROP TABLE empleados PURGE;
-- DROP TABLE departamentos PURGE;
