"""Parses every .sql of the lab with sqlglot in the dialect of the engine that runs it.

The dbt models have Jinja, so what gets parsed is the compiled SQL in target/compiled:
run the dbt project first, as in Lab 5, or nothing is listed for it.
psql meta-commands, psql variables, sqlcmd variables and GO are dropped before parsing,
because the client resolves them before the engine sees the text.

Usage: python3 checagens/sql_por_dialeto.py [<lab folder>]
"""

from __future__ import annotations

import logging
import re
import sys
from dataclasses import dataclass
from pathlib import Path

import sqlglot
from sqlglot.errors import SqlglotError

LOGGER = logging.getLogger("sql_por_dialeto")

META_PSQL = re.compile(r"^\s*\\.*$", re.MULTILINE)
VARIAVEL_PSQL = re.compile(r":'[a-z_]+'|(?<![:\w]):[a-z_]+\b")
VARIAVEL_SQLCMD = re.compile(r"\$\([A-Za-z_]+\)")
LOTE_GO = re.compile(r"^\s*GO\s*$", re.MULTILINE | re.IGNORECASE)
COMANDO_SQLCMD = re.compile(r"^\s*:[a-z]+\b.*$", re.MULTILINE | re.IGNORECASE)


@dataclass(frozen=True)
class Grupo:
    pasta: str
    dialeto: str


GRUPOS = (
    Grupo("sql", "postgres"),
    Grupo("linhagem/postgres", "postgres"),
    Grupo("sqlserver/sql", "tsql"),
    Grupo("linhagem/mssql", "tsql"),
    Grupo("projeto_dbt/target/compiled", "postgres"),
    Grupo("linhagem/dbt/target/compiled", "postgres"),
    Grupo("alternativa_duckdb/projeto/target/compiled", "duckdb"),
)


class Checagem:
    """Runs one parse per file and reports the first error of each."""

    def limpar(self, texto: str, dialeto: str) -> str:
        if dialeto == "tsql":
            texto = LOTE_GO.sub(";", texto)
            texto = COMANDO_SQLCMD.sub("", texto)
            return VARIAVEL_SQLCMD.sub("x", texto)
        if dialeto == "postgres":
            texto = META_PSQL.sub("", texto)
            return VARIAVEL_PSQL.sub("'x'", texto)
        return texto

    def checar(self, arquivo: Path, dialeto: str) -> str | None:
        texto = self.limpar(arquivo.read_text(encoding="utf-8"), dialeto)
        try:
            sqlglot.parse(texto, read=dialeto)
        except SqlglotError as falha:
            return " ".join(str(falha).split())[:140]
        return None


def main(argv: list[str]) -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s", stream=sys.stdout)
    logging.getLogger("sqlglot").setLevel(logging.ERROR)
    raiz = Path(argv[0]) if argv else Path(__file__).resolve().parent.parent
    checagem = Checagem()
    LOGGER.info("sqlglot %s", sqlglot.__version__)
    falhas = 0
    for grupo in GRUPOS:
        for arquivo in sorted((raiz / grupo.pasta).rglob("*.sql")):
            erro = checagem.checar(arquivo, grupo.dialeto)
            falhas += erro is not None
            situacao = "ok" if erro is None else f"FALHA {erro}"
            LOGGER.info("%s %s %s", grupo.dialeto, arquivo.relative_to(raiz), situacao)
    LOGGER.info("falhas: %d", falhas)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
