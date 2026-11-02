# Documento de requisitos

## Introducción

Registro y consulta de citas de pacientes en la base de datos Oracle del
laboratorio. La recepción registra citas para pacientes existentes y el
médico consulta las citas de un paciente para preparar la atención.

Fuera del alcance: cancelar o reprogramar citas, asignar médicos o
consultorios y controlar choques de horario.

Suposiciones:
- La tabla `paciente` ya existe y su clave primaria es `id_paciente
  NUMBER` (decisión mía).
- La columna con el nombre del paciente se llama `nombre` (decisión mía,
  por confirmar con `DESC paciente`).
- Una fecha "futura" es posterior al momento actual (`SYSDATE`), incluida
  la hora; una fecha de hoy a una hora ya pasada se rechaza (decisión
  mía).

## Requisitos

### Requisito 1: Registrar cita

**Historia de usuario:** Como recepcionista, quiero registrar una cita,
para agendar al paciente.

#### Criterios de aceptación

1. WHEN se registra una cita con un paciente existente y una fecha futura
   THEN THE SYSTEM SHALL guardarla con estado 'PROGRAMADA'
2. IF la fecha de la cita no es futura THEN THE SYSTEM SHALL rechazarla
   con el error ORA-20001 y el mensaje 'La fecha de la cita debe ser
   futura'
3. IF el paciente no existe THEN THE SYSTEM SHALL rechazarla con el error
   ORA-20002 y el mensaje 'El paciente no existe'

### Requisito 2: Consultar citas

**Historia de usuario:** Como médico, quiero ver las citas de un
paciente, para preparar la consulta.

#### Criterios de aceptación

1. WHEN se consultan las citas de un paciente THEN THE SYSTEM SHALL
   listarlas con el nombre del paciente, ordenadas por fecha ascendente
