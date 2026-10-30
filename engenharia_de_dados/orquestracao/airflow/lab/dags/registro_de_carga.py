"""Run SQL in the database, log every load, alert when the row count repeats."""

import pendulum

from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.sdk import dag, get_current_context, task

CONN_ID = "loja_db"


def alertar(context) -> None:
    # Stand-in for a real channel (email, chat); prints so the lab needs no credentials.
    ti = context["task_instance"]
    print(f"ALERTA: a task {ti.task_id} falhou na execução {context['run_id']}")


@dag(
    schedule="0 7,13 * * *",
    start_date=pendulum.datetime(2026, 10, 1, tz="America/Sao_Paulo"),
    catchup=False,
    max_active_runs=1,
    default_args={"retries": 1, "retry_delay": pendulum.duration(seconds=30)},
    tags=["mentoria", "laboratorio"],
)
def registro_de_carga():
    criar_tabelas = SQLExecuteQueryOperator(
        task_id="criar_tabelas",
        conn_id=CONN_ID,
        sql="sql/criar_tabelas.sql",
    )

    carregar_pedidos_tratados = SQLExecuteQueryOperator(
        task_id="carregar_pedidos_tratados",
        conn_id=CONN_ID,
        sql="sql/carregar_pedidos_tratados.sql",
    )

    @task
    def registrar_carga() -> int:
        contexto = get_current_context()
        tipo = contexto["dag_run"].run_type.value
        hook = PostgresHook(postgres_conn_id=CONN_ID)
        linhas = hook.get_first("SELECT count(*) FROM pedidos_tratados")[0]
        hook.run(
            "INSERT INTO controle_carga (run_id, tipo_execucao, linhas) "
            "VALUES (%s, %s, %s)",
            parameters=(contexto["run_id"], tipo, linhas),
        )
        print(f"Carga registrada: {linhas} linhas, tipo {tipo}")
        return linhas

    @task(retries=0, on_failure_callback=alertar)
    def checar_repeticao(linhas_agora: int) -> None:
        hook = PostgresHook(postgres_conn_id=CONN_ID)
        anterior = hook.get_first(
            "SELECT linhas FROM controle_carga ORDER BY id DESC LIMIT 1 OFFSET 1"
        )
        if anterior is None:
            print("Primeira carga registrada, nada para comparar.")
            return
        if anterior[0] == linhas_agora:
            raise ValueError(
                f"A contagem repetiu a carga anterior ({linhas_agora} linhas). "
                "A origem pode não ter sido atualizada."
            )
        print(f"Contagem mudou: {anterior[0]} para {linhas_agora} linhas.")

    linhas = registrar_carga()
    criar_tabelas >> carregar_pedidos_tratados >> linhas
    checar_repeticao(linhas)


registro_de_carga()
