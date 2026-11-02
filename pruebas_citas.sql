-- =====================================================================
-- PRUEBAS DE CITAS DE PACIENTES - ORACLE
-- =====================================================================
-- Spec: docs/specs/citas-paciente/ (criterios 1.1, 1.2 y 1.3)
-- Ejecutar después de citas.sql. Toma los pacientes de la tabla
-- paciente sin insertar ninguno y termina con ROLLBACK, así que no
-- deja datos. Cada caso imprime una línea OK o FALLA.
-- =====================================================================

SET SERVEROUTPUT ON

DECLARE
    v_existente    paciente.id_paciente%TYPE;
    v_inexistente  paciente.id_paciente%TYPE;
    v_id_cita      cita.id_cita%TYPE;
    v_estado       cita.estado%TYPE;

    -- Llama a registrar_cita y comprueba que falle con el código y el mensaje esperados.
    PROCEDURE esperar_error (
        p_caso         IN VARCHAR2,
        p_id_paciente  IN NUMBER,
        p_fecha        IN DATE,
        p_codigo       IN NUMBER,
        p_mensaje      IN VARCHAR2
    ) IS
    BEGIN
        registrar_cita(p_id_paciente, p_fecha);
        DBMS_OUTPUT.PUT_LINE('FALLA ' || p_caso || ': no lanzó ningún error');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = p_codigo AND SQLERRM = 'ORA' || p_codigo || ': ' || p_mensaje THEN
                DBMS_OUTPUT.PUT_LINE('OK ' || p_caso);
            ELSE
                DBMS_OUTPUT.PUT_LINE('FALLA ' || p_caso || ': ' || SQLERRM);
            END IF;
    END esperar_error;
BEGIN
    SELECT MIN(id_paciente), NVL(MAX(id_paciente), 0) + 1
    INTO   v_existente, v_inexistente
    FROM   paciente;

    IF v_existente IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('FALLA: la tabla paciente está vacía; no se pueden ejecutar los casos');
        RETURN;
    END IF;

    -- 1.1 Caso normal: se guarda con estado 'PROGRAMADA'.
    BEGIN
        registrar_cita(v_existente, SYSDATE + 1);
        v_id_cita := seq_cita.CURRVAL;
        SELECT estado INTO v_estado FROM cita WHERE id_cita = v_id_cita;
        IF v_estado = 'PROGRAMADA' THEN
            DBMS_OUTPUT.PUT_LINE('OK normal');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FALLA normal: estado ' || v_estado);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('FALLA normal: ' || SQLERRM);
    END;

    -- 1.2 La fecha tiene que ser futura: pasada, igual a SYSDATE o nula.
    esperar_error('fecha pasada',      v_existente, SYSDATE - 1, -20001, 'La fecha de la cita debe ser futura');
    esperar_error('fecha igual a hoy', v_existente, SYSDATE,     -20001, 'La fecha de la cita debe ser futura');
    esperar_error('fecha nula',        v_existente, NULL,        -20001, 'La fecha de la cita debe ser futura');

    -- 1.3 El paciente tiene que existir.
    esperar_error('paciente inexistente', v_inexistente, SYSDATE + 1, -20002, 'El paciente no existe');
END;
/

ROLLBACK;
