-- =====================================================================
-- CITAS DE PACIENTES - ORACLE
-- =====================================================================
-- Spec: docs/specs/citas-paciente/
-- Contenido:
--   1. Secuencia seq_cita y tabla cita
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
