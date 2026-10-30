"""Print the dates each Dag run receives, under different timetables, in Airflow 3.

Every Dag here has the same three independent tasks:

- mostrar_datas: prints logical_date, data interval, ds, ts and run_after.
- receita_particao: applies the "read and write a specific partition using
  data_interval_start" recipe to a tiny synthetic table of visits stored in UTC.
- template_ds: renders {{ ds }} and {{ data_interval_start }} in a Bash command.
"""

from __future__ import annotations

from datetime import timedelta

import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG, CronDataIntervalTimetable, CronTriggerTimetable, task

SP = pendulum.timezone("America/Sao_Paulo")

# Synthetic store visits stored in UTC. The store closes at 22:00 Brasilia time.
VISITAS_UTC = [
    "2026-10-27T12:15:00+00:00",  # 27/10 09:15 Brasilia
    "2026-10-27T17:40:00+00:00",  # 27/10 14:40 Brasilia
    "2026-10-28T00:00:00+00:00",  # 27/10 21:00 Brasilia, looks like midnight in UTC
    "2026-10-28T00:45:00+00:00",  # 27/10 21:45 Brasilia
    "2026-10-28T13:05:00+00:00",  # 28/10 10:05 Brasilia
    "2026-10-29T00:30:00+00:00",  # 28/10 21:30 Brasilia
]

CHAVES = (
    "logical_date",
    "data_interval_start",
    "data_interval_end",
    "ds",
    "ts",
)


def _fmt(value):
    if value is None:
        return "None"
    if hasattr(value, "in_timezone"):
        local = value.in_timezone(SP).strftime("%d/%m %H:%M")
        return f"{value.isoformat()} (Brasilia {local})"
    return str(value)


def _build(dag_id: str, schedule, start_date, descricao: str) -> DAG:
    with DAG(
        dag_id=dag_id,
        schedule=schedule,
        start_date=start_date,
        catchup=False,
        description=descricao,
        tags=["datas-e-fuso"],
    ) as dag:

        @task
        def mostrar_datas(**context):
            dag_run = context["dag_run"]
            print(f"DATAS dag_id={dag_id}")
            print(f"DATAS timetable={type(context['dag'].timetable).__name__}")
            print(f"DATAS run_id={dag_run.run_id}")
            print(
                f"DATAS run_type={getattr(dag_run.run_type, 'value', dag_run.run_type)}"
            )
            print(f"DATAS run_after={_fmt(getattr(dag_run, 'run_after', None))}")
            print(f"DATAS dag_run.logical_date={_fmt(dag_run.logical_date)}")
            for chave in CHAVES:
                if chave in context:
                    print(f"DATAS {chave}={_fmt(context[chave])}")
                else:
                    print(f"DATAS {chave}=AUSENTE do contexto")

        @task
        def receita_particao(**context):
            inicio = context.get("data_interval_start")
            fim = context.get("data_interval_end")
            if inicio is None or fim is None:
                print(
                    "RECEITA sem data_interval_start ou data_interval_end no contexto"
                )
                return
            linhas = [v for v in VISITAS_UTC if inicio <= pendulum.parse(v) < fim]
            duracao = fim - inicio
            print(f"RECEITA janela=[{inicio.isoformat()}, {fim.isoformat()})")
            print(f"RECEITA duracao={duracao}")
            print(f"RECEITA particao_gravada=dt={inicio.strftime('%Y-%m-%d')}")
            print(f"RECEITA linhas_lidas={len(linhas)}")
            for v in linhas:
                local = pendulum.parse(v).in_timezone(SP)
                print(f"RECEITA linha utc={v} brasilia={local.strftime('%d/%m %H:%M')}")

        template_ds = BashOperator(
            task_id="template_ds",
            bash_command=(
                'echo "TEMPLATE ds={{ ds }} '
                'data_interval_start={{ data_interval_start }}"'
            ),
        )

        mostrar_datas()
        receita_particao()
        template_ds

    return dag


UTC_START = pendulum.datetime(2026, 10, 19, tz="UTC")
SP_START = pendulum.datetime(2026, 10, 19, tz="America/Sao_Paulo")

datas_cron_puro = _build(
    "datas_cron_puro",
    "0 0 * * *",
    UTC_START,
    "bare cron string, default config",
)
datas_preset_daily = _build(
    "datas_preset_daily",
    "@daily",
    UTC_START,
    "@daily preset, default config",
)
datas_trigger_intervalo = _build(
    "datas_trigger_intervalo",
    CronTriggerTimetable("0 0 * * *", timezone="UTC", interval=timedelta(days=1)),
    UTC_START,
    "CronTriggerTimetable with interval of one day",
)
datas_intervalo_classico = _build(
    "datas_intervalo_classico",
    CronDataIntervalTimetable("0 0 * * *", timezone="UTC"),
    UTC_START,
    "CronDataIntervalTimetable, the Airflow 2 default",
)
datas_dia_brasilia = _build(
    "datas_dia_brasilia",
    CronTriggerTimetable(
        "0 0 * * *", timezone="America/Sao_Paulo", interval=timedelta(days=1)
    ),
    SP_START,
    "local calendar day in Brasilia, interval of one day",
)
datas_22h_brasilia = _build(
    "datas_22h_brasilia",
    CronTriggerTimetable("0 22 * * *", timezone="America/Sao_Paulo"),
    SP_START,
    "store closing time in Brasilia, no interval",
)
