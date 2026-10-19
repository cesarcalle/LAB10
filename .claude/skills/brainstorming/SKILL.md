---
name: brainstorming
description: Úsala antes de cualquier trabajo creativo (crear funcionalidades, diseñar bases de datos, agregar o cambiar comportamiento, o planificar algo nuevo) para entender qué quiere el usuario y por qué, antes de construir.
---

# Brainstorming

Antes de construir, averigua qué quiere realmente el usuario y por qué.
Lo que crees que quiere suele ser menos de lo que parece.

## Primero: ¿qué sabes?

- **La petición lo dice todo** (ej. "cambia el color a azul"): hazlo y di qué hiciste.
- **Falta algo importante:** empieza la conversación.

## Primer mensaje

Solo dos cosas:
1. Una línea: "Si prefieres saltarte las preguntas y que empiece directamente, dímelo."
   Si acepta, la skill termina: indica en una línea las decisiones técnicas
   importantes (lenguaje, herramienta, motor de base de datos) y haz el trabajo.
2. Una pregunta abierta sobre un caso concreto o real.

## La conversación

- **Una sola pregunta por mensaje**, en una frase, sin lista de ejemplos.
- Lenguaje simple, en español, con las mismas palabras que usa el usuario.
- Primero preguntas abiertas. Da opciones solo si se traba.
  Si dice "tú decide", propón algo concreto.
- Una suposición que pueda corregir ("Supongo que es porque...") suele
  servir más que una pregunta.
- Averigua pronto qué decisiones técnicas quiere tomar él y cuáles te deja
  a ti. Si existe trabajo previo en el repo, sigue lo que ya usa.
  Lo que decidas tú se marca como "decisión mía".
- Si ayuda, ofrece revisar el repo, sus archivos o la web. Él decide.

Temas a cubrir (no los leas como cuestionario): qué es y qué lo hace
especial, por qué ahora, qué es un éxito, qué está fuera del alcance,
qué haría que fracase aunque funcione, ejemplos que le gustan o no,
qué existe hoy y los detalles que le importan.

## Repetir lo entendido

Cuando entiendas una parte, descríbela en 150-250 palabras, marca tus
suposiciones como tuyas y pregunta qué falta o está mal. Alterna
resúmenes y preguntas hasta cubrir todo.

## Tamaño del trabajo

| Tamaño | Descripción completa | Después |
|---|---|---|
| Tarea rápida y clara | la propia petición | hacerla |
| Cambio pequeño | en el chat | construirlo |
| Proyecto | documento de diseño | plan de implementación |

Si crece a mitad de camino, dilo y sube de tamaño. Si en realidad son
varios proyectos, acuerda un orden y trátalos de uno en uno.

## Documento de diseño (proyectos)

Guárdalo en `docs/disenos/AAAA-MM-DD-tema.md` y súbelo al repo. Debe
permitir que otra persona lo construya sin volver a preguntar:
- propósito y el porqué
- objetivos, lo que queda fuera y lo que sería un fracaso
- restricciones
- lo que el usuario decidió, tal como lo decidió
- lo que queda a criterio de quien construya

Antes de entregarlo, reléelo como si fueras quien lo va a construir.
Lo que puedas decidir sin cambiar el resultado, decídelo y márcalo como
"decisión mía". Lo que solo el usuario puede responder, pregúntalo en un
único mensaje, empezando por lo más importante.

## Regla obligatoria

No se construye nada (código, estructura de proyecto, dependencias)
hasta que el usuario apruebe la descripción completa: en el chat si es
un cambio pequeño, o el documento si es un proyecto. Leer y explorar sí
está permitido.

Excepción: si el usuario pidió saltarse las preguntas, la regla no aplica.

## Señales de alerta

| Pensamiento | Realidad |
|---|---|
| "Le doy opciones para ahorrarle esfuerzo" | Las opciones dirigen. Primero que describa. |
| "Pongo valores por defecto razonables" | Bien, pero dilos en voz alta. |
| "Dijo 'suena bien'" | Solo aprobó lo que viste escrito. |
