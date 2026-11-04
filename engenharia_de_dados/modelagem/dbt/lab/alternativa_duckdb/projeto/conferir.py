"""Reads back the tables dbt built in the DuckDB file, in the same container run."""

import duckdb

conexao = duckdb.connect("/tmp/lab.duckdb", read_only=True)
print("duckdb", duckdb.__version__)
print(conexao.sql("select * from vendas_por_dia order by dia"))
print(conexao.sql("select pedido_id, '[' || cliente || ']' as cliente, status from stg_pedidos where pedido_id in (101, 102, 105, 110) order by 1"))
print(conexao.sql("select id, '[' || cliente || ']' as cliente_na_seed from bronze_pedidos where id in (101, 105, 107, 110) order by 1"))
