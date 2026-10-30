"""Print the DATAS, RECEITA, TEMPLATE and error lines of the lab task logs."""

import json
import sys
from pathlib import Path

MARCAS = ("DATAS ", "RECEITA ", "TEMPLATE ")


def main(raiz: str, filtro: str) -> None:
    for log in sorted(Path(raiz).glob("dag_id=*/run_id=*/task_id=*/attempt=*.log")):
        if filtro not in str(log):
            continue
        partes = {p.split("=", 1)[0]: p.split("=", 1)[1] for p in log.parts if "=" in p}
        cabecalho = f"## {partes['dag_id']} | {partes['run_id']} | {partes['task_id']}"
        linhas = []
        for bruta in log.read_text().splitlines():
            try:
                evento = json.loads(bruta)
            except json.JSONDecodeError:
                continue
            texto = str(evento.get("event", ""))
            nivel = evento.get("level", "")
            if any(m in texto for m in MARCAS):
                linhas.append(
                    texto.split("] ", 1)[-1] if "TEMPLATE" in texto else texto
                )
            elif nivel == "error" or "Task instance in" in texto:
                erro = evento.get("error_detail") or ""
                resumo = ""
                if isinstance(erro, list) and erro:
                    resumo = f" {erro[0].get('exc_type')}: {erro[0].get('exc_value')}"
                linhas.append(f"[{nivel}] {texto}{resumo}")
        print(cabecalho)
        print("\n".join(linhas) if linhas else "(sem linhas marcadas)")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "")
