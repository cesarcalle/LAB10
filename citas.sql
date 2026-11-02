-- =====================================================================
-- CITAS DE PACIENTES - ORACLE
-- =====================================================================
-- Spec: docs/specs/citas-paciente/
-- Contenido:
--   1. Secuencia seq_cita y tabla cita
--   2. Procedimiento registrar_cita
-- Requiere que la tabla paciente (id_paciente NUMBER, nombre) ya exista.
-- =====================================================================


-- =====================================================================
-- 1. SECUENCIA Y TABLA
-- =====================================================================

CREATE SEQUENCE seq_cita START WITH 1 INCREMENT BY 1;

CREATE TABLE cita (
    id_cita      NUMBER        CONSTRAINT pk_cita PRIMARY KEY,
    id_paciente  NUMBER        NOT NULL,
    fecha        DATE          NOT NULL,
    estado       VARCHAR2(20)  DEFAULT 'PROGRAMADA' NOT NULL,
    CONSTRAINT fk_cita_paciente FOREIGN KEY (id_paciente)
        REFERENCES paciente (id_paciente)
);


-- =====================================================================
-- 2. PROCEDIMIENTO REGISTRAR_CITA
-- =====================================================================
-- Registra una cita en estado 'PROGRAMADA'. Valida primero la fecha
-- (no consulta tablas) y después el paciente. No hace COMMIT: la
-- transacción la cierra quien llama.
--   ORA-20001  fecha nula, pasada o igual a SYSDATE
--   ORA-20002  el paciente no existe

CREATE OR REPLACE PROCEDURE registrar_cita (
    p_id_paciente  IN cita.id_paciente%TYPE,
    p_fecha        IN cita.fecha%TYPE
) AS
    v_existe  NUMBER;
BEGIN
    IF p_fecha IS NULL OR p_fecha <= SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'La fecha de la cita debe ser futura');
    END IF;

    SELECT COUNT(*) INTO v_existe
    FROM   paciente
    WHERE  id_paciente = p_id_paciente;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'El paciente no existe');
    END IF;

    INSERT INTO cita (id_cita, id_paciente, fecha)
    VALUES (seq_cita.NEXTVAL, p_id_paciente, p_fecha);
END registrar_cita;
/
