#!/usr/bin/env python3
"""Mide cuánto de un tasks.md ya fue iterado por el planner.

Una tarea cuenta como iterada si está hecha ([x]) o aparece en el
comentario <!-- planner: revisadas ... -->. La unidad de trabajo de una
ronda es la tarea de primer nivel: está pendiente si ella o alguna de sus
subtareas no está iterada.

Uso: python progreso.py <ruta/a/tasks.md> [--json]
"""

import json
import re
import sys
from pathlib import Path

TAREA = re.compile(r"^(\s*)- \[([ xX])\](\*)? (\d+(?:\.\d+)*)\.?\s+(.*)$")
REVISADAS = re.compile(r"<!--\s*planner:\s*revisadas\s*(.*?)\s*-->")


def analizar(texto):
    tareas = []
    for linea in texto.splitlines():
        m = TAREA.match(linea)
        if m:
            tareas.append({
                "id": m.group(4),
                "hecha": m.group(2).lower() == "x",
                "opcional": bool(m.group(3)),
                "titulo": m.group(5).strip(),
            })

    m = REVISADAS.search(texto)
    revisadas = set()
    if m:
        revisadas = {x.strip() for x in m.group(1).split(",") if x.strip()}

    for t in tareas:
        t["iterada"] = t["hecha"] or t["id"] in revisadas

    pendientes = []
    for t in tareas:
        if "." in t["id"]:
            continue
        grupo = [x for x in tareas if x["id"] == t["id"] or x["id"].startswith(t["id"] + ".")]
        if not all(x["iterada"] for x in grupo):
            pendientes.append({"id": t["id"], "titulo": t["titulo"]})

    ids = {t["id"] for t in tareas}
    iteradas = sum(t["iterada"] for t in tareas)
    total = len(tareas)
    return {
        "total": total,
        "iteradas": iteradas,
        "porcentaje": round(100 * iteradas / total, 1) if total else 0.0,
        "pendientes": pendientes,
        "hay_comentario": m is not None,
        # números en el comentario que ya no existen en el plan (renumeración olvidada)
        "revisadas_huerfanas": sorted(revisadas - ids),
    }


def main():
    args = [a for a in sys.argv[1:] if a != "--json"]
    if len(args) != 1:
        print(__doc__.strip())
        sys.exit(2)
    ruta = Path(args[0])
    texto = ruta.read_text(encoding="utf-8") if ruta.exists() else ""
    r = analizar(texto)
    if "--json" in sys.argv:
        print(json.dumps(r, ensure_ascii=False, indent=2))
        return
    if r["total"] == 0:
        print("Sin tareas: hace falta la estimación inicial.")
        return
    print(f"Iterado: {r['porcentaje']}% ({r['iteradas']}/{r['total']})")
    if r["pendientes"]:
        print("Pendientes: " + ", ".join(f"{p['id']}. {p['titulo']}" for p in r["pendientes"]))
    if r["revisadas_huerfanas"]:
        print("Aviso: el comentario de revisadas cita tareas que no existen: "
              + ", ".join(r["revisadas_huerfanas"]))


if __name__ == "__main__":
    main()
