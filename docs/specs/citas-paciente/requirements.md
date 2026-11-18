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
- La edad del paciente se calcula a partir de una columna
  `fecha_nacimiento DATE` de la tabla `paciente` (decisión mía, por
  confirmar con `DESC paciente`).
- "Mayor de 18 años" significa que el paciente ya cumplió 18 años al
  momento de la consulta (`SYSDATE`); un paciente que cumple 18 hoy sí
  entra (decisión mía).
- Un paciente sin `fecha_nacimiento` registrada no se considera mayor de
  edad (decisión mía).

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
2. THE SYSTEM SHALL incluir en la consulta solo las citas de pacientes
   mayores de 18 años
3. IF el paciente es menor de 18 años o no tiene fecha de nacimiento
   registrada THEN THE SYSTEM SHALL excluir sus citas del resultado
