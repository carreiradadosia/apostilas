"""Compare the hand SELECT of silver.pedidos with the dbt model stg_pedidos, ignoring case and spacing.

The only expected difference is how the source is written: bronze.pedidos by hand, source() in dbt.
Usage, from the lab folder: python3 checagens/comparar_select_pedidos.py
"""

import re
from pathlib import Path

LAB = Path(__file__).resolve().parent.parent


def normalizar(texto: str) -> str:
    """Drop comments, unify case and spacing, so that only the SQL tokens are compared."""
    sem_comentario = re.sub(r"--[^\n]*", " ", texto)
    return re.sub(r"\s+", " ", sem_comentario).strip().rstrip(";").strip().lower()


def select_a_mao() -> str:
    """The statement that builds silver.pedidos in the hand script, without the CREATE TABLE line."""
    script = (LAB / "sql" / "20_silver.sql").read_text(encoding="utf-8")
    inicio = script.index("CREATE TABLE silver.pedidos AS")
    fim = script.index(";", inicio)
    return script[inicio + len("CREATE TABLE silver.pedidos AS") : fim]


def select_dbt() -> str:
    """The dbt model, with source() written back as the table it resolves to."""
    modelo = (LAB / "projeto_dbt" / "models" / "silver" / "stg_pedidos.sql").read_text(
        encoding="utf-8"
    )
    return re.sub(
        r"\{\{\s*source\('bronze',\s*'pedidos'\)\s*\}\}", "bronze.pedidos", modelo
    )


def main() -> None:
    a_mao, dbt = normalizar(select_a_mao()), normalizar(select_dbt())
    print(f"tokens a mao: {len(a_mao.split())}, tokens dbt: {len(dbt.split())}")
    print(
        "SELECT igual, trocando source('bronze', 'pedidos') por bronze.pedidos:",
        a_mao == dbt,
    )


if __name__ == "__main__":
    main()
