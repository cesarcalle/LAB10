export const meta = {
  name: 'plan-tasks',
  description: 'Genera o itera el tasks.md de cualquier spec en docs/specs/<nombre>/ con planners de solo lectura en paralelo (fan-out), junta sus propuestas en un consenso que escribe un único sintetizador, y repite hasta dejarlo 100% iterado, con el alcance de cada tarea evaluado contra la spec.',
}

// Versión en workflow del skill planning-task (.claude/skills/planning-task/SKILL.md).
// Fan-out-and-synthesize por rondas:
//   reconocer la spec -> (sin tareas) 1 planner en modo estimacion -> sintetizador
//   -> ronda: 1 planner en modo propuesta por cada tarea pendiente (en paralelo)
//   -> consenso en JS: quitar duplicados, detectar conflictos; árbitros en paralelo
//   -> 1 sintetizador escribe todo el consenso de la ronda
//   -> repetir hasta 100% -> cierre: revisión final + evaluación del alcance.
//
// Los planners (.claude/agents/planner.md) son de solo lectura: nunca escriben tasks.md.
// El único que escribe es el sintetizador (.claude/agents/sintetizador.md), una vez por paso.
//
// Uso:  /plan-tasks citas-paciente
//       /plan-tasks {"spec": "citas-paciente", "maxRondas": 5}

// args a veces llega como texto JSON en lugar de objeto: aceptar las dos formas.
const entrada = typeof args === 'string'
  ? (args.trim().startsWith('{') ? JSON.parse(args) : { spec: args.trim() })
  : (args ?? {})

const MAX_RONDAS = entrada.maxRondas ?? 5
const MAX_CIERRES = 3
const PROGRESO = 'python .claude/skills/planning-task/scripts/progreso.py'

// ---------------------------------------------------------------- esquemas

const LISTA = { type: 'array', items: { type: 'string' } }

const SPEC = {
  type: 'object',
  required: ['nombre', 'candidatos', 'faltan', 'criterios', 'piezasDiseno', 'hayTareas'],
  properties: {
    nombre: { type: 'string' },          // vacío si no se pudo elegir una sola spec
    candidatos: LISTA,                   // specs que existen en docs/specs/
    faltan: LISTA,                       // documentos que faltan: requirements.md, design.md
    criterios: LISTA,                    // "1.1 WHEN ... THEN ..."
    piezasDiseno: LISTA,                 // tablas, procedimientos, archivos, errores, pruebas
    hayTareas: { type: 'boolean' },
  },
}

const PROGRESO_SCHEMA = {
  type: 'object',
  required: ['total', 'iteradas', 'porcentaje', 'pendientes', 'huerfanas'],
  properties: {
    total: { type: 'integer' },
    iteradas: { type: 'integer' },
    porcentaje: { type: 'number' },
    pendientes: {
      type: 'array',
      items: {
        type: 'object', required: ['id', 'titulo'],
        properties: { id: { type: 'string' }, titulo: { type: 'string' } },
      },
    },
    huerfanas: LISTA,
  },
}

// Lo que el sintetizador necesita para reemplazar una tarea.
const BLOQUE = {
  type: 'object', required: ['tarea', 'titulo', 'accion', 'bloque'],
  properties: {
    tarea: { type: 'string' },
    titulo: { type: 'string' },
    accion: { type: 'string' },          // sin cambios | corregida | dividida en ... | eliminada | ...
    bloque: { type: 'string' },          // markdown que reemplaza la tarea, o ELIMINAR
  },
}

const FALTANTES = {
  type: 'array',
  items: {
    type: 'object', required: ['titulo', 'cubre', 'detalle'],
    properties: {
      titulo: { type: 'string' },
      cubre: LISTA,                      // criterios ("1.2") o piezas del diseño que cubre
      detalle: { type: 'string' },
    },
  },
}

const ESTIMACION = {
  type: 'object',
  required: ['estado', 'totalTareas', 'bloque', 'porQue', 'problemasSpec'],
  properties: {
    estado: { enum: ['PROPUESTA', 'BLOQUEADO'] },
    totalTareas: { type: 'integer' },
    bloque: { type: 'string' },          // la lista completa, desde "# Plan de implementación"
    porQue: { type: 'string' },
    problemasSpec: LISTA,
  },
}

const PROPUESTA = {
  type: 'object',
  required: ['estado', 'accion', 'porQue', 'bloque', 'afectaA', 'tareasFaltantes', 'problemasSpec'],
  properties: {
    estado: { enum: ['PROPUESTA', 'BLOQUEADO'] },
    accion: { type: 'string' },
    porQue: { type: 'string' },
    bloque: { type: 'string' },
    afectaA: LISTA,                      // OTRAS tareas que la propuesta cambia o de las que depende
    tareasFaltantes: FALTANTES,
    problemasSpec: LISTA,
  },
}

const ARBITRAJE = {
  type: 'object',
  required: ['estado', 'porQue', 'bloques', 'tareasFaltantes', 'problemasSpec'],
  properties: {
    estado: { enum: ['PROPUESTA', 'BLOQUEADO'] },
    porQue: { type: 'string' },
    bloques: { type: 'array', items: BLOQUE },   // uno por cada tarea en disputa
    tareasFaltantes: FALTANTES,
    problemasSpec: LISTA,
  },
}

const SINTESIS = {
  type: 'object',
  required: ['cambios', 'noAplicado', 'porcentaje', 'huerfanas'],
  properties: { cambios: LISTA, noAplicado: LISTA, porcentaje: { type: 'number' }, huerfanas: LISTA },
}

const CIERRE = {
  type: 'object',
  required: ['estado', 'accion', 'porQue', 'correcciones', 'criterios', 'piezas', 'sinCubrir', 'fueraDeAlcance', 'alcance', 'problemasSpec'],
  properties: {
    estado: { enum: ['COMPLETO', 'CONTINUAR', 'BLOQUEADO'] },
    accion: { type: 'string' },
    porQue: { type: 'string' },
    correcciones: { type: 'array', items: BLOQUE },  // vacío si COMPLETO
    criterios: {
      type: 'object', required: ['cubiertos', 'total'],
      properties: { cubiertos: { type: 'integer' }, total: { type: 'integer' } },
    },
    piezas: {
      type: 'object', required: ['cubiertas', 'total'],
      properties: { cubiertas: { type: 'integer' }, total: { type: 'integer' } },
    },
    sinCubrir: LISTA,
    fueraDeAlcance: LISTA,               // tareas que hacen algo que la spec no pide
    alcance: {                           // una fila por tarea de primer nivel
      type: 'array',
      items: {
        type: 'object', required: ['tarea', 'criterios', 'piezas', 'tamano'],
        properties: {
          tarea: { type: 'string' },
          criterios: LISTA,
          piezas: LISTA,
          tamano: { type: 'string' },    // por qué el tamaño es el correcto, en una frase
        },
      },
    },
    problemasSpec: LISTA,
  },
}

// ---------------------------------------------------------------- ayudas

const FORMATO = 'Devuelve tu informe con los campos del formato estructurado pedido: son los mismos de tu informe. ' +
  'Eres de solo lectura: no escribas ningún archivo.'

const planner = (nombre, modo, tarea, nota) =>
  [`spec: ${nombre}`, `modo: ${modo}`, tarea && `tarea: ${tarea}`, nota && `nota: ${nota}`, '', FORMATO]
    .filter(l => l !== undefined && l !== null && l !== false).join('\n')

const sintetizar = (nombre, paso, propuestas, faltantes, fase) => agent(
  [`spec: ${nombre}`, `paso: ${paso}`,
    `propuestas: ${JSON.stringify(propuestas)}`, `faltantes: ${JSON.stringify(faltantes)}`, '',
    'Devuelve tu informe con los campos del formato estructurado pedido: "cambios", "noAplicado", ' +
    'y de progreso.py --json el porcentaje y revisadas_huerfanas.'].join('\n'),
  { agentType: 'sintetizador', phase: fase, label: `sintetizar ${paso}`, schema: SINTESIS },
)

const medir = (nombre, etiqueta) => agent(
  `Ejecuta \`${PROGRESO} docs/specs/${nombre}/tasks.md --json\` y devuelve su salida tal cual en el formato pedido ` +
  `(pendientes = la lista "pendientes", huerfanas = "revisadas_huerfanas"). No cambies ningún archivo.`,
  { label: etiqueta, model: 'haiku', effort: 'low', schema: PROGRESO_SCHEMA },
)

const clave = f => (f.cubre.length ? [...f.cubre].sort().join('|') : f.titulo).toLowerCase().trim()

const problemas = new Set()
const anotar = lista => (lista || []).forEach(p => problemas.add(p))
const historial = []
const avisarNoAplicado = s => { if (s?.noAplicado?.length) log(`El sintetizador no pudo aplicar: ${s.noAplicado.join('; ')}`) }

const terminar = (estado, extra) => {
  const filas = historial.map(h => `| ${h.paso} | ${h.planners} | ${h.resultado} |`).join('\n')
  return [
    `**Spec:** ${spec.nombre} — ${estado}`,
    '',
    '| Paso | Planners | Resultado |',
    '|---|---|---|',
    filas,
    '',
    extra,
    '',
    `**Problemas en la spec:** ${problemas.size ? '\n' + [...problemas].map(p => `- ${p}`).join('\n') : 'ninguno'}`,
  ].join('\n')
}

// ---------------------------------------------------------------- 1. reconocer la spec

phase('Reconocimiento')
const spec = await agent(
  `Prepara la planeación de tareas de una spec.\n` +
  `Spec pedida: ${entrada.spec ? `"${entrada.spec}"` : '(ninguna)'}\n\n` +
  `1. Lista las carpetas de docs/specs/ en "candidatos". Si se pidió una spec que existe, úsala en "nombre". ` +
  `Si no se pidió ninguna y hay una sola, usa esa. En cualquier otro caso deja "nombre" vacío.\n` +
  `2. Si hay nombre: anota en "faltan" cuál de requirements.md y design.md no existe.\n` +
  `3. Lee requirements.md y copia cada criterio de aceptación con su número ("1.2 WHEN ... THEN ...") en "criterios".\n` +
  `4. Lee design.md y anota cada pieza que dice que existirá (archivo, tabla, secuencia, procedimiento, vista, ` +
  `manejo de error, prueba) en "piezasDiseno".\n` +
  `5. "hayTareas" es true solo si tasks.md existe y tiene al menos una línea "- [ ]" o "- [x]".\n` +
  `No cambies ningún archivo.`,
  { label: 'spec', schema: SPEC },
)

if (!spec) return 'No se pudo leer docs/specs/. Revisa que exista la carpeta y vuelve a intentar.'
if (!spec.nombre) {
  return `Indica qué spec planear, por ejemplo \`/plan-tasks ${spec.candidatos[0] ?? '<nombre>'}\`. ` +
    `Specs disponibles: ${spec.candidatos.length ? spec.candidatos.join(', ') : 'ninguna en docs/specs/'}.`
}
if (spec.faltan.length) {
  return `La spec ${spec.nombre} no tiene ${spec.faltan.join(' ni ')}. Sin requisitos y diseño no hay qué planear: ` +
    `escríbelos primero con el skill specify.`
}
log(`Spec ${spec.nombre}: ${spec.criterios.length} criterios, ${spec.piezasDiseno.length} piezas del diseño`)

// ---------------------------------------------------------------- 2. estimación inicial (un solo planner)

if (!spec.hayTareas) {
  phase('Estimación')
  // Uno solo: la lista inicial necesita ver la spec entera para repartir el trabajo sin solaparse.
  const est = await agent(planner(spec.nombre, 'estimacion'), { agentType: 'planner', label: 'estimacion', schema: ESTIMACION })
  if (!est) return terminar('la estimación inicial falló', 'El planner de estimación no respondió. Vuelve a lanzar el workflow.')
  anotar(est.problemasSpec)
  if (est.estado === 'BLOQUEADO') {
    historial.push({ paso: 'Estimación', planners: 1, resultado: 'BLOQUEADO' })
    return terminar('BLOQUEADO en la estimación', est.porQue)
  }
  const s = await sintetizar(spec.nombre, 'estimacion',
    [{ tarea: 'todas', titulo: 'lista inicial', accion: 'estimación inicial', bloque: est.bloque }], [], 'Estimación')
  if (!s) return terminar('la estimación no se pudo escribir', 'El sintetizador no respondió. Vuelve a lanzar el workflow.')
  avisarNoAplicado(s)
  historial.push({ paso: 'Estimación', planners: 1, resultado: `${est.totalTareas} tareas iniciales` })
}

// ---------------------------------------------------------------- 3. rondas + 4. cierre

const vistas = new Set()   // tareas faltantes ya agregadas, para no volver a agregarlas en otra ronda
let rondas = 0, cierres = 0, cierreFinal = null, progreso = null

while (true) {
  progreso = await medir(spec.nombre, `progreso ${rondas}.${cierres}`)
  if (!progreso) return terminar('sin poder medir el progreso', 'El script progreso.py no respondió.')
  if (progreso.huerfanas.length) log(`Aviso: el comentario de revisadas cita tareas inexistentes: ${progreso.huerfanas.join(', ')}`)

  // ---- cierre: todo iterado -> revisión final del plan completo
  if (progreso.pendientes.length === 0) {
    if (cierres >= MAX_CIERRES) break
    cierres++
    const cierre = await agent(planner(spec.nombre, 'revision'),
      { agentType: 'planner', phase: 'Cierre', label: `cierre ${cierres}`, schema: CIERRE })
    if (!cierre) { log(`El cierre ${cierres} no respondió; se reintenta`); continue }
    anotar(cierre.problemasSpec)
    historial.push({ paso: `Cierre ${cierres}`, planners: 1, resultado: `${cierre.estado}: ${cierre.accion}` })
    if (cierre.estado === 'COMPLETO') { cierreFinal = cierre; break }
    if (cierre.estado === 'BLOQUEADO') return terminar('BLOQUEADO en la revisión final', cierre.porQue)
    // CONTINUAR: corrigió algo del conjunto; el sintetizador lo escribe y se vuelve a medir.
    avisarNoAplicado(await sintetizar(spec.nombre, 'revision', cierre.correcciones, [], 'Cierre'))
    continue
  }

  // ---- ronda: un planner por tarea pendiente, en paralelo (todos solo leen)
  if (rondas >= MAX_RONDAS) break
  rondas++
  const fase = `Ronda ${rondas}`
  const pendientes = progreso.pendientes
  const propuestas = await parallel(pendientes.map(t => () =>
    agent(planner(spec.nombre, 'propuesta', t.id),
      { agentType: 'planner', phase: fase, label: `${t.id}. ${t.titulo}`, schema: PROPUESTA })))

  const recibidas = pendientes.map((t, i) => ({ t, p: propuestas[i] })).filter(x => x.p)
  if (recibidas.length < pendientes.length) {
    log(`${pendientes.length - recibidas.length} planners no respondieron; sus tareas siguen pendientes para la próxima ronda`)
  }
  recibidas.forEach(x => anotar(x.p.problemasSpec))

  // Un bloqueo es una decisión del usuario: sin ella no hay consenso posible.
  const bloqueadas = recibidas.filter(x => x.p.estado === 'BLOQUEADO')
  if (bloqueadas.length) {
    historial.push({ paso: fase, planners: pendientes.length, resultado: `${bloqueadas.length} bloqueadas` })
    return terminar('BLOQUEADO', 'Decisiones que necesita el usuario:\n' +
      bloqueadas.map(x => `- Tarea ${x.t.id}: ${x.p.porQue}`).join('\n'))
  }

  // Conflicto: una propuesta cambia otra tarea que también se revisó en esta ronda.
  const enRonda = new Set(recibidas.map(x => x.t.id))
  const pares = new Map()
  for (const x of recibidas) {
    for (const otra of x.p.afectaA.filter(id => id !== x.t.id && enRonda.has(id))) {
      const k = [x.t.id, otra].sort().join('-')
      if (!pares.has(k)) pares.set(k, [x.t.id, otra])
    }
  }
  const enConflicto = new Set([...pares.values()].flat())

  // Árbitros en paralelo: también son de solo lectura, devuelven un bloque por tarea en disputa.
  const arbitrajes = (await parallel([...pares.values()].map(([a, b]) => () => {
    const pa = recibidas.find(x => x.t.id === a), pb = recibidas.find(x => x.t.id === b)
    return agent(planner(spec.nombre, 'revision', `${a}, ${b}`,
      `conflicto entre las propuestas para las tareas ${a} ("${pa.t.titulo}") y ${b} ("${pb.t.titulo}"). ` +
      `Decide qué queda de las dos y devuelve un bloque por cada una (o ELIMINAR). ` +
      `Propuesta para ${a}: ${JSON.stringify(pa.p)} — Propuesta para ${b}: ${JSON.stringify(pb.p)}`),
    { agentType: 'planner', phase: fase, label: `árbitro ${a}/${b}`, schema: ARBITRAJE })
  }))).filter(Boolean)
  arbitrajes.forEach(a => anotar(a.problemasSpec))
  const arbitroBloqueado = arbitrajes.find(a => a.estado === 'BLOQUEADO')
  if (arbitroBloqueado) return terminar('BLOQUEADO en un arbitraje', arbitroBloqueado.porQue)

  // Tareas faltantes: una por cada cosa que cubren, contra todo lo ya agregado en rondas anteriores.
  const faltantes = []
  for (const f of [...recibidas.flatMap(x => x.p.tareasFaltantes), ...arbitrajes.flatMap(a => a.tareasFaltantes)]) {
    const k = clave(f)
    if (!vistas.has(k)) { vistas.add(k); faltantes.push(f) }
  }

  // Consenso de la ronda: propuestas sin conflicto + bloques de los árbitros. Un conflicto sin
  // árbitro (falló) queda fuera: esas tareas siguen pendientes y vuelven en la próxima ronda.
  const consenso = [
    ...recibidas.filter(x => !enConflicto.has(x.t.id))
      .map(x => ({ tarea: x.t.id, titulo: x.t.titulo, accion: x.p.accion, bloque: x.p.bloque })),
    ...arbitrajes.flatMap(a => a.bloques),
  ]

  // El único paso que escribe tasks.md en la ronda.
  const s = await sintetizar(spec.nombre, 'ronda', consenso, faltantes, fase)
  if (!s) log('El sintetizador no respondió; la ronda se repite con las mismas tareas')
  avisarNoAplicado(s)

  const cuenta = acc => recibidas.filter(x => x.p.accion.toLowerCase().startsWith(acc)).length
  historial.push({
    paso: fase,
    planners: pendientes.length + pares.size,
    resultado: [
      `${cuenta('sin cambios')} sin cambios`, `${cuenta('corregida')} corregidas`, `${cuenta('dividida')} divididas`,
      `${cuenta('fusionada')} fusionadas`, `${cuenta('eliminada')} eliminadas`, `${faltantes.length} agregadas`,
      `${pares.size} conflictos`, s ? `→ ${s.porcentaje}%` : 'sin sintetizar',
    ].join(', '),
  })
}

// ---------------------------------------------------------------- 5. informe

if (!cierreFinal) {
  return terminar(`sin converger (${progreso?.porcentaje ?? '?'}% iterado)`,
    `Se alcanzó el límite de ${MAX_RONDAS} rondas o ${MAX_CIERRES} cierres sin una revisión final COMPLETO. ` +
    `Si las mismas tareas cambian en cada ronda, casi siempre la spec es ambigua en ese punto: revísala y vuelve a lanzar.`)
}

const alcance = cierreFinal.alcance.map(a =>
  `| ${a.tarea} | ${a.criterios.join(', ') || '—'} | ${a.piezas.join(', ') || '—'} | ${a.tamano} |`).join('\n')

return terminar(
  `tasks.md iterado al ${progreso.porcentaje}% (${progreso.iteradas}/${progreso.total}), revisión final: COMPLETO`,
  [
    `**Alcance evaluado:** criterios ${cierreFinal.criterios.cubiertos} de ${cierreFinal.criterios.total}; ` +
    `piezas del diseño ${cierreFinal.piezas.cubiertas} de ${cierreFinal.piezas.total}; ` +
    `sin cubrir: ${cierreFinal.sinCubrir.length ? cierreFinal.sinCubrir.join(', ') : 'ninguno'}; ` +
    `fuera del alcance de la spec: ${cierreFinal.fueraDeAlcance.length ? cierreFinal.fueraDeAlcance.join(', ') : 'nada'}.`,
    '',
    '| Tarea | Criterios | Piezas del diseño | Tamaño |',
    '|---|---|---|---|',
    alcance,
    '',
    '`COMPLETO` significa que el plan es coherente, no que esté aprobado: revisa docs/specs/' +
    `${spec.nombre}/tasks.md y apruébalo antes de implementar.`,
  ].join('\n'),
)
