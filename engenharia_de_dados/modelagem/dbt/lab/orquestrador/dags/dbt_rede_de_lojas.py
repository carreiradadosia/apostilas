"""The orchestrator does not clean data: it runs dbt, tells it which day, and reads the exit code."""

import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag

DBT = "/opt/airflow/dbt-venv/bin/dbt"
# target and logs go to /tmp so the run never writes into the mounted project.
FLAGS = "--project-dir /lab/projeto_dbt --target-path /tmp/dbt-target --log-path /tmp/dbt-logs"


@dag(
    dag_id="dbt_rede_de_lojas",
    schedule="0 6 * * *",
    start_date=pendulum.datetime(2026, 10, 20, tz="America/Sao_Paulo"),
    catchup=False,
    max_active_runs=1,
    tags=["mentoria", "laboratorio"],
)
def dbt_rede_de_lojas():
    # dbt build already runs seeds, snapshots, models and tests in graph order.
    # Unit tests belong to development and CI, so the scheduled run leaves them out.
    BashOperator(
        task_id="dbt_build",
        bash_command=f"{DBT} build {FLAGS} --exclude test_type:unit --vars '{{dia_foto: \"{{{{ ds }}}}\"}}'",
    )


dbt_rede_de_lojas()
