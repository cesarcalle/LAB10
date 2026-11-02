---
name: planning-task
description: Fase de planeación de tareas de una spec en docs/specs/NOMBRE/. Explica cómo se planean las tareas, asegura que la entrada esté lista (spec elegida, requirements.md y design.md presentes y aprobados, estado de tasks.md) y lanza el workflow coverage-tasks, que genera o itera tasks.md con planners en paralelo hasta dejarlo 100% iterado y con el alcance evaluado. Es la fase 3 del skill specify. Úsala siempre que el usuario pida crear, estimar, revisar, completar o "cerrar" el plan de tareas (tasks.md) de una spec, diga que los requisitos y el diseño ya están aprobados y quiera pasar a las tareas, pregunte si las tareas tienen el tamaño correcto o si sobran o faltan, o pregunte cómo funciona la planeación, aunque no diga "planning-task", "planner" ni "coverage-tasks".
---

# Planning task

La planeación la hace el workflow `coverage-tasks`
(`.claude/workflows/coverage-tasks.js`). Este skill hace tres cosas:
explica el proceso, asegura que la entrada del workflow esté lista y lo
lanza. No planea tareas por su cuenta.

## Cómo funciona el proceso

Explícalo así cuando el usuario pregunte, o en una línea antes de lanzar
el workflow:

- **Tres papeles.** Los `planner` (`.claude/agents/planner.md`) revisan y
  proponen, y son de solo lectura para poder correr varios en paralelo.
  El script del workflow decide el consenso sin gastar tokens: quita
  duplicados y detecta conflictos. El `sintetizador`
  (`.claude/agents/sintetizador.md`) es el único que escribe `tasks.md`,
  una vez por paso.
- **Si no hay tareas,** un solo planner propone la lista inicial y el
  sintetizador la escribe.
- **En cada ronda,** un planner por tarea pendiente revisa en paralelo:
  si la tarea es necesaria, si cumple la spec, si tiene el tamaño correcto
  y si dice cómo hacerla en el repo tal como está. Si dos propuestas
  chocan, decide un árbitro. El sintetizador aplica todo y mide con
  `scripts/progreso.py`.
- **Cuando llega al 100%,** un planner hace la revisión final del plan
  completo. Si encuentra algo, se corrige y se vuelve a medir. Termina con
  `COMPLETO` y la evaluación del alcance de cada tarea.
- **Límites:** 5 rondas y 3 cierres. Un `BLOQUEADO` termina la corrida,
  porque un workflow no acepta respuestas a mitad de camino.

"100% iterado" significa que cada tarea está hecha (`[x]`) o la revisó un
planner y quedó en el comentario `<!-- planner: revisadas ... -->`.

## 1. Asegurar la entrada

El workflow no puede preguntar nada mientras corre, así que todo lo que
haga falta decidir se decide antes.

1. **Spec.** Lista `docs/specs/`. Si el usuario no dijo cuál y hay más de
   una, pregúntale.
2. **Requisitos y diseño.** Comprueba que existan `requirements.md` y
   `design.md`. Si falta alguno, o en esta conversación el usuario todavía
   no aprobó el diseño, detente y sigue con el skill `specify`: planear
   sobre una spec sin aprobar es planear dos veces.
3. **Estado de `tasks.md`.** Mide:

   ```bash
   python .claude/skills/planning-task/scripts/progreso.py docs/specs/<nombre>/tasks.md
   ```

   Dile al usuario de dónde parte: sin tareas (habrá estimación inicial),
   o el porcentaje iterado y qué tareas están pendientes. Si el usuario
   cambió a mano tareas que ya estaban revisadas, o si cambió un requisito
   o el diseño, quita esas tareas del comentario de revisadas: si no, el
   workflow no las vuelve a revisar. Si el script avisa de números
   huérfanos, corrige el comentario antes de lanzar.
4. **Problemas conocidos.** Si la spec tiene una ambigüedad que ya
   sabes que bloquea (por ejemplo, dos documentos que se contradicen),
   resuélvela con el usuario ahora. Si no, el workflow terminará en
   `BLOQUEADO` después de gastar una ronda.
5. **Rondas.** Por defecto, 5. Usa otro valor solo si el usuario lo pide.

## 2. Lanzar el workflow

Lanza `coverage-tasks` con la herramienta de workflows, pasando como
argumento:

```json
{ "spec": "<nombre>", "maxRondas": 5 }
```

El usuario aprueba el lanzamiento en la tarjeta que muestra el plan de
fases. Lánzalo desde la conversación principal: los subagentes no tienen
la herramienta de workflows.

Si en esta sesión no tienes esa herramienta (Claude Code anterior a
v2.1.154, o los workflows desactivados en `/config`), pídele al usuario
que lo lance él escribiendo:

```
/coverage-tasks <nombre>
```

No reproduzcas la planeación a mano: perderías la revisión en paralelo
de cada tarea con su propio contexto, que es lo que el proceso asegura.

## 3. Al terminar

El workflow devuelve un informe con la tabla de pasos, el porcentaje
iterado, el alcance evaluado y los problemas de la spec.

- **`COMPLETO`:** muéstrale el informe al usuario tal cual. Confirma con
  `progreso.py` que dé 100% y pregunta si aprueba el plan. `COMPLETO`
  significa que el plan es coherente, no que el usuario lo haya
  aceptado. No empieces a implementar en el mismo turno.
- **`BLOQUEADO`:** explícale al usuario qué tiene que decidir. Con su
  respuesta, actualiza `requirements.md` o `design.md` (con su
  aprobación, siguiendo `specify`) y vuelve a lanzar el workflow: retoma
  desde lo que ya quedó revisado.
- **Sin converger:** casi siempre la spec es ambigua en las tareas que
  cambian en cada ronda. Muéstralas, resuelve la ambigüedad con el
  usuario y vuelve a lanzar.
