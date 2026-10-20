---
name: specify
description: Convierte una idea de funcionalidad en una spec al estilo Kiro con el enfoque Requirements-First, en tres documentos aprobados uno a uno por el usuario dentro de .kiro/specs/NOMBRE/ - requirements.md (historias de usuario y criterios EARS), design.md y tasks.md - y luego ejecuta las tareas. Úsala siempre que el usuario pida una spec, especificación, requisitos, historias de usuario, criterios de aceptación, EARS o un plan de implementación antes de programar una funcionalidad nueva (tablas, consultas, procedimientos, pantallas, APIs), aunque no diga "spec" ni "Kiro"; y también cuando pida continuar, modificar o ejecutar las tareas de una spec que ya existe en .kiro/specs/.
---

# Specify (Requirements-First)

Una spec lleva una idea hasta el código en tres fases, cada una con su
documento: **requisitos → diseño → tareas**. Se avanza de una fase a la
siguiente solo cuando el usuario aprueba el documento actual. Así los
errores de entendimiento salen en un párrafo, no en cien líneas de código.

Todo se escribe en español, pero las palabras clave EARS (`WHEN`, `IF`,
`THEN`, `WHILE`, `WHERE`, `SHALL`) quedan en inglés, como en Kiro.

## Antes de empezar

1. **¿Ya existe la spec?** Mira `.kiro/specs/`. Si el usuario habla de una
   spec existente, lee sus documentos y continúa desde la primera fase que
   no esté aprobada (o ejecuta tareas, si las tres lo están). No empieces
   de cero.
2. **Nombre:** elige un nombre corto en kebab-case a partir de la idea
   (ej. `historial-citas-paciente`) y dilo en una línea. La carpeta es
   `.kiro/specs/<nombre>/`.
3. **Lee el repo:** lenguaje, motor de base de datos, convenciones,
   tablas o archivos relacionados. La spec debe encajar en lo que ya
   existe, no en un proyecto imaginario.

## Fase 0: entender la idea (brainstorming)

Usa el skill `brainstorming` para entender qué quiere el usuario y por
qué. Dos ajustes cuando lo usas desde aquí:

- **No escribas su documento de diseño** en `docs/disenos/`: los
  documentos de la spec lo sustituyen.
- **Termina en cuanto el usuario confirme tu resumen** de la idea. Ese
  resumen es la materia prima de `requirements.md`.

Si el usuario pide saltarse las preguntas, o la petición ya trae todo lo
necesario, pasa directo a la fase 1 y anota tus suposiciones en la
introducción de los requisitos. Si `brainstorming` no está disponible,
haz tú las preguntas, una por mensaje.

## Fase 1: requirements.md

Describe **qué** debe hacer el sistema, no cómo. Formato:

```markdown
# Documento de requisitos

## Introducción

<Qué es la funcionalidad, para quién y por qué. Qué queda fuera del
alcance. Suposiciones marcadas como "decisión mía".>

## Requisitos

### Requisito 1: <título corto>

**Historia de usuario:** Como <rol>, quiero <capacidad>, para <beneficio>.

#### Criterios de aceptación

1. WHEN <evento> THEN THE SYSTEM SHALL <respuesta>
2. IF <condición de error> THEN THE SYSTEM SHALL <respuesta>
```

Patrones EARS (elige el que encaje; una sola respuesta por criterio):

| Patrón | Plantilla | Uso |
|---|---|---|
| Evento | `WHEN <evento> THEN THE SYSTEM SHALL <respuesta>` | flujo normal |
| Error | `IF <condición no deseada> THEN THE SYSTEM SHALL <respuesta>` | errores y datos inválidos |
| Estado | `WHILE <estado> THE SYSTEM SHALL <respuesta>` | mientras algo se cumple |
| Opcional | `WHERE <característica presente> THE SYSTEM SHALL <respuesta>` | según configuración |
| Siempre | `THE SYSTEM SHALL <respuesta>` | reglas sin condición |

Un buen criterio se puede probar: tiene valores concretos (límites,
formatos, mensajes), no usa palabras vagas ("rápido", "fácil",
"adecuado") y no contradice a otro. Cubre el caso normal, los casos
límite (vacío, duplicado, nulo, máximo) y los errores.

Antes de pedir aprobación, relee los requisitos buscando ambigüedades,
contradicciones y huecos. Lo que puedas decidir tú, decídelo y márcalo;
lo que solo el usuario sabe, pregúntalo.

## Fase 2: design.md

Describe **cómo** se cumplirán los requisitos, en el contexto real del
repo. Investiga lo que haga falta (código existente, documentación de
la tecnología) antes de escribir. Secciones:

```markdown
# Documento de diseño

## Resumen
## Arquitectura
## Componentes e interfaces
## Modelos de datos
## Manejo de errores
## Estrategia de pruebas
```

- Omite una sección solo si de verdad no aplica, y dilo en una línea.
- Usa un diagrama Mermaid cuando aclare flujos o relaciones entre tablas.
- Cada decisión importante lleva su porqué en una frase, y las
  alternativas descartadas si las hubo.
- Todo requisito debe quedar cubierto. Si al diseñar descubres que un
  requisito no se puede cumplir o falta uno, proponlo y actualiza
  `requirements.md` (con aprobación) antes de seguir.

## Fase 3: tasks.md

Un plan de implementación que alguien pueda seguir paso a paso:

```markdown
# Plan de implementación

- [ ] 1. <Tarea>
  - <detalle concreto: qué archivo, qué objeto, qué se prueba>
  - _Requisitos: 1.1, 1.2_
- [ ] 2. <Tarea con subtareas>
  - [ ] 2.1 <Subtarea>
    - <detalle>
    - _Requisitos: 2.1_
  - [ ]* 2.2 <Subtarea opcional, ej. pruebas extra>
    - _Requisitos: 2.3_
```

- Solo tareas de código o de scripts que se pueden ejecutar en el repo
  (crear, modificar, probar). Nada de "desplegar", "reunirse" o "probar
  manualmente con usuarios".
- Orden incremental: cada tarea se apoya en las anteriores y deja algo
  que funciona y se puede probar. Nada queda suelto al final.
- Cada tarea cita los criterios que cumple (`1.2` = requisito 1,
  criterio 2). Todos los criterios deben aparecer en alguna tarea.
- Marca con `*` las tareas opcionales (pruebas adicionales, mejoras no
  pedidas) para que el usuario decida si las hace.

## Aprobación entre fases

Después de escribir o cambiar cada documento:

1. Guarda el archivo y resume en 3-5 líneas lo más importante y las
   decisiones que tomaste tú.
2. Pregunta si está bien para pasar a la siguiente fase. Ej.: "¿Los
   requisitos están bien? Si es así, paso al diseño."
3. Si pide cambios, edita el documento y vuelve a preguntar. Repite
   hasta que lo apruebe de forma explícita ("sí", "ok", "aprobado",
   "adelante").

No escribas el documento de la fase siguiente ni código en el mismo
turno en que pides aprobación: el usuario solo ha aprobado lo que vio.
Si pide saltarse las aprobaciones, puedes encadenar las fases, pero
dilo en una línea.

## Fase 4: ejecutar las tareas

Solo cuando el usuario lo pida (ej. "empieza", "haz la tarea 2"):

1. Lee los tres documentos antes de cada tarea.
2. Haz **una tarea a la vez** (la que pida, o la siguiente pendiente).
   Implementa solo lo que dice esa tarea.
3. Pruébala si el entorno lo permite y di qué probaste.
4. Márcala `[x]` en `tasks.md` (y la tarea padre cuando todas sus
   subtareas estén hechas).
5. Para y resume lo hecho. No sigas con la siguiente salvo que el
   usuario pida ejecutar todas.

## Cambios después de aprobar

Si el usuario cambia un requisito con el diseño o las tareas ya hechos,
actualiza `requirements.md`, luego ajusta `design.md` y después
`tasks.md`, pidiendo aprobación en cada paso. Las tareas ya completadas
que queden afectadas se marcan de nuevo como pendientes o se añade una
tarea para adaptarlas.

## Señales de alerta

| Pensamiento | Realidad |
|---|---|
| "Los requisitos son obvios, voy directo al diseño" | Lo obvio para ti es lo que falla. Escríbelos y que los apruebe. |
| "Pongo en el requisito cómo implementarlo" | El cómo va en el diseño; si no, el diseño no tiene nada que decidir. |
| "Esta tarea la dejo general" | Una tarea que no dice qué archivo ni qué prueba no se puede ejecutar. |
| "Ya que estoy, hago la siguiente tarea" | Una a la vez: el usuario revisa entre tareas. |
