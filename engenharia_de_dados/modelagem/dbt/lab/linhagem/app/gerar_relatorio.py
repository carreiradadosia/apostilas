"""Fictional application that generates the report "faturamento por loja" in SQL Server.

It connects like a packaged system would: through a driver, with its own application name, sending
RPC calls with parameters. The lab only observes it from the database side.
"""

import argparse
import datetime as dt
import logging
import os

import pytds

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logging.getLogger("pytds").setLevel(logging.WARNING)
log = logging.getLogger("gerar_relatorio")

INICIO = dt.date(2026, 10, 20)
FIM = dt.date(2026, 10, 22)


class Relatorio:
    """Runs one flavour of the report on an open connection."""

    def __init__(self, conexao: pytds.Connection) -> None:
        self._conexao = conexao

    def _imprimir(self, cursor: pytds.Cursor) -> None:
        for linha in cursor.fetchall():
            log.info("linha %s", tuple(str(valor) for valor in linha))

    def padrao(self) -> None:
        with self._conexao.cursor() as cursor:
            cursor.callproc("relatorios.faturamento_por_loja", (INICIO, FIM))
            self._imprimir(cursor)
        with self._conexao.cursor() as cursor:
            # A parameter sent apart from the text, as an ORM does: goes as sp_executesql.
            cursor.execute(
                "SELECT dia, SUM(valor_item) AS total FROM relatorios.vw_faturamento_itens "
                "WHERE dia >= %s GROUP BY dia ORDER BY dia",
                (dt.date(2026, 10, 21),),
            )
            self._imprimir(cursor)
        with self._conexao.cursor() as cursor:
            # A value glued into the text: goes as a plain batch.
            cursor.execute(
                "SELECT pedido_id, valor_item FROM relatorios.vw_faturamento_itens "
                "WHERE TRIM(cliente) = N'Cliente A'"
            )
            self._imprimir(cursor)

    def procedure(self, nome: str) -> None:
        with self._conexao.cursor() as cursor:
            cursor.callproc(f"relatorios.{nome}", (INICIO, FIM))
            self._imprimir(cursor)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("cenario", help="padrao or a procedure name in the relatorios schema")
    parser.add_argument("--app", default="erp_relatorios", help="application name sent at login")
    argumentos = parser.parse_args()

    with pytds.connect(
        dsn="mssql",
        database="rede",
        user="app_relatorio",
        password=os.environ["MSSQL_APP_PASSWORD"],  # higiene:ignore, read from the environment
        appname=argumentos.app,
        autocommit=True,
    ) as conexao:
        relatorio = Relatorio(conexao)
        if argumentos.cenario == "padrao":
            relatorio.padrao()
        else:
            relatorio.procedure(argumentos.cenario)


if __name__ == "__main__":
    main()
