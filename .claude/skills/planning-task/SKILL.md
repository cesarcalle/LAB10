---
name: planning-task
description: Planea las tareas de implementación de una spec en docs/specs/NOMBRE/ a partir de su requirements.md y design.md, lanzando subagentes planner de solo lectura - uno solo para la estimación inicial si tasks.md no tiene tareas, o uno por cada tarea si ya existen - y juntando sus propuestas en un consenso que escribe un único agente sintetizador, hasta que tasks.md quede 100% iterado. Es la fase 3 del skill specify. Úsala siempre que el usuario pida crear, estimar, revisar, mejorar, completar o "cerrar" el plan de tareas (tasks.md) de una spec, cuando diga que los requisitos y el diseño ya están aprobados y quiera pasar a las tareas, o cuando pida revisar si las tareas tienen el tamaño correcto, si sobran o si faltan, aunque no diga "planning-task" ni "planner".
---

# Planning task

Toma la salida de una spec (`requirements.md` y `design.md`) y la
convierte en un `tasks.md` en el que todos están de acuerdo: cada tarea
del tamaño correcto, necesaria, alineada con la spec y con el repo, y sin
huecos.

Hay tres papeles, y ninguno hace el trabajo de otro:

| Papel | Quién | Escribe `tasks.md` |
|---|---|---|
| Revisar y proponer | subagentes `planner` | **No.** Son de solo lectura, para que varios corran en paralelo sobre el mismo archivo |
| Decidir el consenso | tú, en la conversación principal | No |
| Escribir | subagente `sintetizador` | **Sí, y es el único.** Una vez al final de cada paso |

La meta es que el plan quede **100% iterado**: cada tarea está hecha
(`[x]`) o la revisó un planner y quedó en el comentario
`<!-- planner: revisadas ... -->`, y la revisión final respondió
`COMPLETO`. Las dos cosas hacen falta: el porcentaje dice que nadie se
saltó una tarea, y la revisión final dice que el conjunto tiene sentido
(orden, cobertura, sin duplicados).

## Antes de empezar

1. **Spec.** Busca la carpeta en `docs/specs/`. Si hay varias y el
   usuario no dijo cuál, pregúntale. Si faltan `requirements.md` o
   `design.md`, detente: sin los dos no hay qué planear. Sugiere el skill
   `specify` para escribirlos.
2. **Agentes.** Lee una vez `.claude/agents/planner.md` y
   `.claude/agents/sintetizador.md`, para conocer sus entradas y sus
   informes. Lánzalos con `subagent_type: "planner"` y
   `subagent_type: "sintetizador"`. Si un tipo no está disponible (por
   ejemplo, el agente se creó después de abrir la sesión), usa
   `general-purpose` y empieza el prompt con: "Lee
   `.claude/agents/<nombre>.md` y actúa exactamente como ese agente". A
   un planner lanzado así recuérdale además que no escriba ningún archivo.

   Ejecuta este skill en la conversación principal, no lo delegues a un
   subagente: según el entorno, un subagente puede no tener la
   herramienta para lanzar otros. Si aun así no puedes lanzar subagentes,
   haz cada papel tú mismo siguiendo su archivo al pie de la letra, una
   llamada a la vez, y avísale al usuario en el informe que la revisión
   no vino de contextos separados.
3. **Estado.** Mide dónde está el plan:

   ```bash
   python .claude/skills/planning-task/scripts/progreso.py docs/specs/<nombre>/tasks.md
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
repartir el trabajo sin solaparse; varios planners proponiendo la lista a
la vez producirían tareas duplicadas. Pasa su propuesta tal cual al
sintetizador:

```
spec: <nombre>
paso: estimacion
propuestas: [<la propuesta del planner>]
```

El sintetizador escribe la lista sin marcar ninguna tarea como revisada.
Sigue con la ruta B: la estimación es un borrador, y cada tarea se
revisa después por separado.

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
subtarea, sus propuestas se pisarían.

### 2. Llegar al consenso

Junta los informes y decide qué entra al plan. Aquí todavía no se escribe
nada:

| Lo que llega | Qué haces |
|---|---|
| Acción `sin cambios` | Entra tal cual: el sintetizador la marca revisada. |
| Un cambio que solo toca su propia tarea (corregida, dividida, marcada opcional) | Entra su bloque. |
| `ELIMINAR` | Entra, salvo que otra propuesta dependa de esa tarea (entonces es un conflicto). |
| Conflicto: dos propuestas tocan lo mismo (su `Afecta a` nombra otra tarea revisada en esta ronda, o una elimina algo que otra usa) | No elijas tú. Lanza un planner en modo `revision` con `tarea: <a>, <b>` y las dos propuestas en la `nota`. Sus bloques reemplazan a las dos propuestas. |
| Tareas faltantes | Junta las de todos los informes y quita duplicados: dos que cubren el mismo criterio o pieza son una. Compáralas también con las que agregaste en rondas anteriores, o volverán a aparecer. |
| `BLOQUEADO` o un problema de la spec que impide cubrir un criterio | Detente y pregunta al usuario. Sin esa decisión no hay consenso posible; seguir solo esconde el problema. |
| Problemas de la spec que no bloquean | Anótalos para el informe final. |

### 3. Sintetizar

Lanza **un** sintetizador con el consenso de la ronda:

```
spec: <nombre>
paso: ronda
propuestas: [{ tarea, titulo, accion, bloque }, ...]
faltantes: [{ titulo, cubre, detalle }, ...]
```

Aplica todo en un solo paso, renumera, actualiza el comentario de
revisadas y mide con el script. Revisa su informe: si algo quedó en "No
aplicado", resuélvelo antes de la próxima ronda.

Mientras el script muestre tareas pendientes, haz otra ronda solo con
esas. Lo normal es que cada ronda tenga menos tareas que la anterior
(solo las nuevas y las que cambiaron por un conflicto).

## Cierre: la revisión final

Cuando el script dé 100%, lanza **un** planner:

```
spec: <nombre>
modo: revision
```

Revisa el plan completo, que es lo único que una revisión aislada no
puede ver.

- Si responde `COMPLETO`, terminaste. Su informe trae la evaluación del
  alcance de cada tarea.
- Si responde `CONTINUAR`, encontró algo del conjunto (un orden, una
  dependencia incompatible entre dos tareas). Pasa sus bloques al
  sintetizador con `paso: revision`, mide, y vuelve a lanzar el cierre
  (o una ronda, si el script muestra tareas pendientes). Es normal que el
  primer cierre encuentre algo.

**Límite:** 5 rondas en total. Si se alcanzan sin `COMPLETO`, para y dile
al usuario qué tareas siguen cambiando de una ronda a otra y por qué. Si
dos planners se contradicen ronda tras ronda, casi siempre la spec es
ambigua en ese punto, y eso lo decide el usuario.

## Informe al usuario

Al terminar, escribe:

```markdown
**Spec:** <nombre> — tasks.md iterado al <N>% (<iteradas>/<total>), revisión final: COMPLETO

| Paso | Planners | Resultado |
|---|---|---|
| Estimación | 1 | <N> tareas iniciales |
| Ronda 1 | <N> | <divididas, fusionadas, eliminadas, agregadas, conflictos> |
| Cierre 1 | 1 | <COMPLETO o lo que corrigió> |

**Alcance evaluado:** <criterios y piezas cubiertos, y una línea por tarea con lo que cubre, del informe de la revisión final>

**Cambios principales:** <3–6 líneas con lo más importante y su porqué>

**Problemas en la spec:** <lo que el usuario debe decidir, o "ninguno">
```

Copia el porcentaje del informe del sintetizador o del script, no lo
calcules. Luego pregunta si aprueba el plan: `COMPLETO` significa que el
plan es coherente, no que el usuario lo haya aceptado. No empieces a
implementar tareas en el mismo turno.

## Señales de alerta

| Pensamiento | Realidad |
|---|---|
| "Hay tareas, pero las reviso yo para ir más rápido" | La revisión es del planner, que mira el repo con su propio contexto. Tú decides el consenso. |
| "Le paso todo el skill a un subagente para no llenar mi contexto" | Puede quedarse sin forma de lanzar planners. El skill corre en la conversación principal. |
| "Le pido a un planner que aplique su propia propuesta" | Los planners no escriben: si varios escribieran, se borrarían los cambios entre sí. Escribe solo el sintetizador. |
| "Edito tasks.md yo mismo, es un cambio chico" | Entonces el comentario de revisadas y la numeración dependen de que no te equivoques. Pásalo al sintetizador. |
| "Dos propuestas chocan; me quedo con la que me gusta" | Un conflicto lo resuelve un planner en modo revision que lee las dos y la spec. |
| "El script da 100%, ya está" | Falta la revisión final: el porcentaje no ve el orden ni los duplicados. |
| "La ronda 6 seguro lo arregla" | Si 5 rondas no convergen, el problema está en la spec, no en las tareas. |
