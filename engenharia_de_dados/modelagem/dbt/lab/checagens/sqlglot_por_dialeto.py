"""Parses each .sql file with sqlglot twice, without dialect and as Postgres, and prints the first error.

Usage: python3 checagens/sqlglot_por_dialeto.py <dir> [<dir> ...]
psql meta-commands (lines starting with a backslash) are dropped before parsing, as psql does.
"""

from __future__ import annotations

import logging
import sys
from dataclasses import dataclass
from pathlib import Path

import sqlglot
from sqlglot.errors import SqlglotError

LOGGER = logging.getLogger("sqlglot_por_dialeto")


@dataclass(frozen=True)
class Resultado:
    arquivo: Path
    dialeto: str
    erro: str | None

    def linha(self) -> str:
        situacao = "ok" if self.erro is None else f"FALHA {self.erro}"
        return f"{self.dialeto:<12} {self.arquivo}  {situacao}"


class Checagem:
    """Runs the same parse the workspace validator runs, plus the Postgres dialect."""

    DIALETOS: tuple[str | None, ...] = (None, "postgres")

    def texto_sem_meta_comandos(self, arquivo: Path) -> str:
        linhas = arquivo.read_text(encoding="utf-8").splitlines()
        return "\n".join(linha for linha in linhas if not linha.lstrip().startswith("\\"))

    def checar(self, arquivo: Path) -> list[Resultado]:
        texto = self.texto_sem_meta_comandos(arquivo)
        resultados = []
        for dialeto in self.DIALETOS:
            try:
                sqlglot.parse(texto, read=dialeto)
                erro = None
            except SqlglotError as falha:
                erro = str(falha).splitlines()[0][:140]
            resultados.append(Resultado(arquivo, dialeto or "sem_dialeto", erro))
        return resultados


def main(argv: list[str]) -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s", stream=sys.stdout)
    LOGGER.info("sqlglot %s", sqlglot.__version__)
    checagem = Checagem()
    falhas = 0
    for raiz in map(Path, argv):
        for arquivo in sorted(raiz.rglob("*.sql")):
            for resultado in checagem.checar(arquivo):
                falhas += resultado.erro is not None
                LOGGER.info("%s", resultado.linha())
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
