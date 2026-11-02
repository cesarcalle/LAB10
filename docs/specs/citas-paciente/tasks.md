# Plan de implementación

- [ ] 1. Crear los objetos de citas en citas.sql
  - [ ] 1.1 Crear la secuencia seq_cita y la tabla cita
    - Crear `citas.sql` en la raíz del repo (junto a `consulta_paciente.sql`) con `CREATE SEQUENCE seq_cita START WITH 1 INCREMENT BY 1;`
    - `CREATE TABLE cita (id_cita NUMBER CONSTRAINT pk_cita PRIMARY KEY, id_paciente NUMBER NOT NULL, fecha DATE NOT NULL, estado VARCHAR2(20) DEFAULT 'PROGRAMADA' NOT NULL, CONSTRAINT fk_cita_paciente FOREIGN KEY (id_paciente) REFERENCES paciente (id_paciente));` (la tabla `paciente` ya existe; no se crea)
    - Comprobar: ejecutar el script, luego `INSERT INTO cita (id_cita, id_paciente, fecha) VALUES (seq_cita.NEXTVAL, <id existente>, SYSDATE + 1);` y `SELECT estado FROM cita;` devuelve `PROGRAMADA`; terminar con `ROLLBACK`
    - _Requisitos: 1.1_
  - [ ] 1.2 Crear el procedimiento registrar_cita
    - En `citas.sql`, después de la tabla: `CREATE OR REPLACE PROCEDURE registrar_cita(p_id_paciente IN cita.id_paciente%TYPE, p_fecha IN cita.fecha%TYPE)`
    - Primero validar la fecha: `IF p_fecha IS NULL OR p_fecha <= SYSDATE THEN RAISE_APPLICATION_ERROR(-20001, 'La fecha de la cita debe ser futura'); END IF;`
    - Después validar el paciente con `SELECT COUNT(*) INTO v_existe FROM paciente WHERE id_paciente = p_id_paciente;` y, si es 0, `RAISE_APPLICATION_ERROR(-20002, 'El paciente no existe');`
    - Insertar con `seq_cita.NEXTVAL` sin indicar `estado`, para que tome el DEFAULT `'PROGRAMADA'`; sin `COMMIT` dentro del procedimiento (lo decide quien llama)
    - Comprobar: compila sin errores (`SHOW ERRORS` / `USER_ERRORS` vacío) y `EXEC registrar_cita(<id existente>, SYSDATE + 1);` deja una fila nueva en `cita`; terminar con `ROLLBACK`
    - _Requisitos: 1.1, 1.2, 1.3_
  - [ ] 1.3 Crear la vista v_citas_paciente
    - En `citas.sql`, al final: `CREATE OR REPLACE VIEW v_citas_paciente AS SELECT c.id_cita, c.id_paciente, p.nombre AS nombre_paciente, c.fecha, c.estado FROM cita c JOIN paciente p ON p.id_paciente = c.id_paciente ORDER BY c.fecha;`
    - Antes de escribirla, confirmar con `DESC paciente` el nombre real de la columna del nombre (se asume `nombre`)
    - Comprobar: con dos citas del mismo paciente insertadas en orden inverso, `SELECT * FROM v_citas_paciente WHERE id_paciente = <id> ORDER BY fecha;` las lista de la más próxima a la más lejana
    - _Requisitos: 2.1_
- [ ] 2. Crear el script de pruebas pruebas_citas.sql
  - Crear `pruebas_citas.sql` en la raíz del repo, junto a `citas.sql`, con `SET SERVEROUTPUT ON`; tomar un paciente existente con `SELECT MIN(id_paciente)` y uno inexistente con `SELECT NVL(MAX(id_paciente), 0) + 1` desde `paciente`, sin insertar pacientes porque solo se conoce su columna `id_paciente`
  - Caso normal: bloque anónimo que llama `registrar_cita(<existente>, SYSDATE + 1)` y comprueba que la nueva fila de `cita` tiene `estado = 'PROGRAMADA'`; imprime `OK normal` o `FALLA normal` con `DBMS_OUTPUT.PUT_LINE`
  - Caso fecha pasada: `registrar_cita(<existente>, SYSDATE - 1)` dentro de `BEGIN ... EXCEPTION WHEN OTHERS`; imprime `OK fecha pasada` solo si `SQLCODE = -20001` (si no lanza error, imprime `FALLA`)
  - Caso paciente inexistente: `registrar_cita(<inexistente>, SYSDATE + 1)` con el mismo patrón; imprime `OK paciente inexistente` solo si `SQLCODE = -20002`
  - Terminar con `ROLLBACK` para no dejar datos. Comprobar: después de `citas.sql`, ejecutar `@pruebas_citas.sql` muestra las tres líneas `OK` y ninguna `FALLA`
  - _Requisitos: 1.1, 1.2, 1.3_

<!-- planner: revisadas 1, 1.1, 1.2, 1.3, 2 -->
