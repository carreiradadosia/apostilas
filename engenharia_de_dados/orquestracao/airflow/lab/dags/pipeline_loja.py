"""Same SQL files as scripts/pipeline.py, now run by Airflow, one task per layer.

Two Dags differ only in the bronze file: loja_ingenua appends, loja_idempotente replaces the day.
"""

from pathlib import Path

import pendulum
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.sdk import dag, get_current_context, task

CONN_ID = "dw_db"
SQL_DIR = Path(__file__).parent / "sql"
# The run at 06:00 local time loads the day before its logical date.
DIA = "{{ macros.ds_add(ds, -1) }}"


def criar_dag(dag_id: str, arquivo_bronze: str):
    @dag(
        dag_id=dag_id,
        schedule="0 6 * * *",
        start_date=pendulum.datetime(2026, 10, 15, tz="America/Sao_Paulo"),
        catchup=False,
        max_active_runs=1,
        default_args={"retries": 1, "retry_delay": pendulum.duration(seconds=10)},
        tags=["mentoria", "laboratorio"],
    )
    def pipeline():
        @task
        def bronze(dia: str) -> None:
            hook = PostgresHook(postgres_conn_id=CONN_ID)
            hook.run((SQL_DIR / arquivo_bronze).read_text(), parameters={"dia": dia}, split_statements=True)
            contexto = get_current_context()
            # Lab only: fail after the commit on the first try, like a worker lost mid-run.
            if contexto["dag_run"].conf.get("simular_queda") and contexto["ti"].try_number == 1:
                raise RuntimeError("Queda simulada depois do commit: o dia já foi gravado no bronze.")

        silver = SQLExecuteQueryOperator(
            task_id="silver",
            conn_id=CONN_ID,
            sql="sql/silver_pedidos.sql",
            parameters={"dia": DIA},
            split_statements=True,
        )

        gold = SQLExecuteQueryOperator(
            task_id="gold",
            conn_id=CONN_ID,
            sql="sql/gold_vendas_por_dia.sql",
            parameters={"dia": DIA},
            split_statements=True,
        )

        registrar = SQLExecuteQueryOperator(
            task_id="registrar_carga",
            conn_id=CONN_ID,
            sql="sql/registrar_carga.sql",
            parameters={"dia": DIA, "executor": "airflow:{{ dag_run.run_type.value }}"},
        )

        bronze(DIA) >> silver >> gold >> registrar

    return pipeline()


criar_dag("loja_ingenua", "bronze_pedidos_ingenuo.sql")
criar_dag("loja_idempotente", "bronze_pedidos.sql")
