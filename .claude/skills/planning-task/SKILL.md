---
name: planning-task
description: Planea las tareas de implementación de una spec en .kiro/specs/NOMBRE/ a partir de su requirements.md y design.md, lanzando subagentes planner - uno solo para la estimación inicial si tasks.md no tiene tareas, o uno por cada tarea si ya existen - y juntando sus propuestas en un plan de consenso hasta que tasks.md quede 100% iterado. Úsala siempre que el usuario pida crear, estimar, revisar, mejorar, completar o "cerrar" el plan de tareas (tasks.md) de una spec, cuando diga que los requisitos y el diseño ya están aprobados y quiera pasar a las tareas, o cuando pida revisar si las tareas tienen el tamaño correcto, si sobran o si faltan, aunque no diga "planning-task" ni "planner".
---

# Planning task

Toma la salida de una spec (`requirements.md` y `design.md`) y la
convierte en un `tasks.md` en el que todos están de acuerdo: cada tarea
del tamaño correcto, necesaria, alineada con la spec y con el repo, y sin
huecos. Tú no revisas las tareas: lo hacen los subagentes `planner`. Tu
trabajo es decidir cuántos lanzar, juntar lo que proponen y repetir hasta
que el plan quede **100% iterado**.

"100% iterado" significa que cada tarea de `tasks.md` está hecha (`[x]`)
o fue revisada por un planner y quedó en el comentario
`<!-- planner: revisadas ... -->`, y que un planner hizo la revisión final
y respondió `COMPLETO`. Las dos cosas hacen falta: el porcentaje dice que
nadie se saltó una tarea, y la revisión final dice que el conjunto tiene
sentido (orden, cobertura, sin duplicados).

## Antes de empezar

1. **Spec.** Busca la carpeta en `.kiro/specs/`. Si hay varias y el
   usuario no dijo cuál, pregúntale. Si faltan `requirements.md` o
   `design.md`, detente: sin los dos no hay qué planear. Sugiere el skill
   `specify` para escribirlos.
2. **Planner.** Lee `.claude/agents/planner.md` una vez, para conocer sus
   modos y el formato de su informe. Lánzalo con `subagent_type:
   "planner"`. Si ese tipo no está disponible (por ejemplo, el agente se
   creó después de abrir la sesión), usa `general-purpose` y empieza el
   prompt con: "Lee `.claude/agents/planner.md` y actúa exactamente como
   ese agente."
3. **Estado.** Mide dónde está el plan:

   ```bash
   python .claude/skills/planning-task/scripts/progreso.py .kiro/specs/<nombre>/tasks.md
   ```

   El script dice el porcentaje iterado y qué tareas de primer nivel están
   pendientes, o que no hay tareas. Úsalo en lugar de contar a mano:
   contar a mano es donde se cuelan las tareas que nadie revisó.

## Ruta A: no hay tareas → un solo planner

Si `tasks.md` no existe o no tiene tareas, lanza **un** planner:

```
spec: <nombre>
modo: estimacion
```

Uno solo, porque una estimación inicial necesita ver la spec entera para
repartir el trabajo sin solaparse; varios planners escribiendo la lista a
la vez producirían tareas duplicadas. El planner escribe la lista
completa sin marcar ninguna como revisada. Vuelve a medir con el script
(debe dar 0%) y sigue con la ruta B: la estimación es un borrador, y cada
tarea se revisa después por separado.

## Ruta B: hay tareas → un planner por tarea, en rondas

Cada ronda tiene tres pasos.

### 1. Lanzar

Por cada tarea de primer nivel pendiente que dio el script, lanza un
planner en **modo propuesta**, todos en el mismo mensaje para que corran
en paralelo:

```
spec: <nombre>
modo: propuesta
tarea: <número>
nota: <lo que el usuario dijo de esa tarea, si dijo algo>
```

La unidad es la tarea de primer nivel con sus subtareas, porque dividir y
fusionar ocurre a ese nivel; si dos planners revisaran una tarea y su
subtarea, se pisarían. Van en modo propuesta (no escriben) porque todos
leen el mismo `tasks.md`: si escribieran a la vez, el último borraría los
cambios de los demás.

### 2. Llegar al consenso

Junta los informes y decide qué entra al plan:

| Lo que llega | Qué haces |
|---|---|
| Acción `sin cambios` | La tarea queda como está y se marca revisada. |
| Un cambio que solo toca su propia tarea (corregida, dividida, marcada opcional) | Aplica el bloque de la propuesta y marca revisados la tarea y sus subtareas. |
| `ELIMINAR` | Bórrala, salvo que otra propuesta dependa de ella (entonces es un conflicto). |
| Conflicto: dos propuestas tocan lo mismo (una quiere fusionar la tarea 3 con la 4 y la de la 4 la reescribe; o una elimina algo que otra usa) | No elijas tú. Lanza un planner en modo `aplicar` sobre la tarea en disputa, con las dos propuestas en la `nota`, y aplica lo que decida. Tú coordinas; el criterio técnico es del planner, que vuelve a leer la spec y el repo. |
| Tareas faltantes | Junta las de todos los informes, quita duplicados (dos que cubren el mismo criterio o pieza son una) y agrégalas en la posición que respeta las dependencias, **sin** marcarlas revisadas: se revisan en la próxima ronda. |
| `BLOQUEADO` o un problema de la spec que impide cubrir un criterio | Detente y pregunta al usuario. Sin esa decisión no hay consenso posible; seguir solo esconde el problema. |
| Problemas de la spec que no bloquean | Anótalos para el informe final. |

Después de aplicar todo, renumera, actualiza el comentario
`<!-- planner: revisadas ... -->` con los números nuevos y mide con el
script. Si avisa de "revisadas que no existen", olvidaste actualizar un
número: corrígelo antes de seguir.

### 3. Repetir

Mientras el script muestre tareas pendientes, haz otra ronda solo con
esas. Lo normal es que cada ronda tenga menos tareas que la anterior
(solo las nuevas y las que cambiaron por un conflicto).

## Cierre: la revisión final

Cuando el script dé 100%, lanza **un** planner:

```
spec: <nombre>
modo: aplicar
tarea: siguiente
```

Como todas están revisadas, hace la revisión final del plan completo.

- Si responde `COMPLETO`, terminaste.
- Si responde `CONTINUAR`, cambió algo (por ejemplo, reordenó): lo que
  tocó vuelve a pendiente; haz otra ronda y vuelve al cierre.

**Límite:** 5 rondas en total. Si se alcanzan sin `COMPLETO`, para y dile
al usuario qué tareas siguen cambiando de una ronda a otra y por qué. Si
dos planners se contradicen ronda tras ronda, casi siempre la spec es
ambigua en ese punto, y eso lo decide el usuario.

## Informe al usuario

Al terminar, escribe:

```markdown
**Spec:** <nombre> — tasks.md iterado al <N>% (<iteradas>/<total>), revisión final: COMPLETO

| Ronda | Planners | Resultado |
|---|---|---|
| 0 | 1 (estimación) | <N> tareas iniciales |
| 1 | <N> | <cambios: divididas, fusionadas, eliminadas, agregadas, conflictos> |

**Cambios principales:** <3–6 líneas con lo más importante y su porqué>

**Problemas en la spec:** <lo que el usuario debe decidir, o "ninguno">
```

Copia el porcentaje de la salida del script, no lo calcules. Luego
pregunta si aprueba el plan: `COMPLETO` significa que el plan es
coherente, no que el usuario lo haya aceptado. No empieces a implementar
tareas en el mismo turno.

## Señales de alerta

| Pensamiento | Realidad |
|---|---|
| "Hay tareas, pero las reviso yo para ir más rápido" | La revisión es del planner, que mira el repo con su propio contexto. Tú juntas. |
| "Lanzo los planners en modo aplicar, es más simple" | Escriben a la vez en el mismo archivo y se borran los cambios unos a otros. |
| "Dos propuestas chocan; me quedo con la que me gusta" | Un conflicto lo resuelve un planner que lee las dos y la spec. |
| "El script da 100%, ya está" | Falta la revisión final: el porcentaje no ve el orden ni los duplicados. |
| "La ronda 6 seguro lo arregla" | Si 5 rondas no convergen, el problema está en la spec, no en las tareas. |
