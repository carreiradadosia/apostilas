"""Smallest useful Dag: three tasks in order, no external system."""

import pendulum

from airflow.sdk import dag, task


@dag(
    schedule=None,
    start_date=pendulum.datetime(2026, 10, 1, tz="America/Sao_Paulo"),
    catchup=False,
    tags=["mentoria", "laboratorio"],
)
def ola_orquestracao():
    @task
    def extrair() -> list[float]:
        return [120.00, 80.50, 45.00]

    @task
    def transformar(valores: list[float]) -> float:
        return round(sum(valores), 2)

    @task
    def carregar(total: float) -> None:
        print(f"Total do dia: {total}")

    carregar(transformar(extrair()))


ola_orquestracao()
