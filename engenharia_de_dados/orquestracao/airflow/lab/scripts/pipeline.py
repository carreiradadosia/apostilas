"""Run the same SQL files the Dag runs, in order, as one transaction."""

import argparse
import os
import sys
from datetime import date, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import psycopg

SQL_DIR = Path(os.environ.get("SQL_DIR", Path(__file__).resolve().parents[1] / "dags" / "sql"))
PASSOS = ["bronze_pedidos.sql", "silver_pedidos.sql", "gold_vendas_por_dia.sql"]


def ontem_em_brasilia() -> date:
    return datetime.now(ZoneInfo("America/Sao_Paulo")).date() - timedelta(days=1)


def instrucoes(arquivo: Path) -> list[str]:
    # The files keep ";" out of literals and comments, so a plain split is enough here.
    return [s.strip() for s in arquivo.read_text(encoding="utf-8").split(";") if s.strip()]


def main() -> int:
    parser = argparse.ArgumentParser(description="Carga bronze, silver e gold de um dia.")
    parser.add_argument("--dia", type=date.fromisoformat, default=ontem_em_brasilia())
    parser.add_argument("--modo", choices=["idempotente", "ingenuo"], default="idempotente")
    parser.add_argument("--executor", default="manual")
    args = parser.parse_args()

    passos = list(PASSOS)
    if args.modo == "ingenuo":
        passos[0] = "bronze_pedidos_ingenuo.sql"
    params = {"dia": args.dia.isoformat(), "executor": args.executor}
    agora = datetime.now(ZoneInfo("America/Sao_Paulo")).isoformat(timespec="seconds")
    print(f"{agora} dia={params['dia']} modo={args.modo} executor={args.executor}")

    # The context manager commits at the end, or rolls everything back on any error.
    with psycopg.connect(os.environ["DW_URL"]) as conn:
        for nome in passos + ["registrar_carga.sql"]:
            for sql in instrucoes(SQL_DIR / nome):
                conn.execute(sql, params)
            print(f"  {nome}: ok")
        bronze, silver, receita = conn.execute(
            "SELECT linhas_bronze, linhas_silver, receita_paga FROM controle.carga ORDER BY id DESC LIMIT 1"
        ).fetchone()
    print(f"  resultado: bronze={bronze} silver={silver} receita_paga={receita}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
