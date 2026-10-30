---
title: "8. Fuso horário: o dia de quem?"
date: 2026-10-29
type: capitulo
status: draft
project: zambotto-mentoria
tags:
  - engenharia-de-dados
  - orquestracao
  - apostila
  - mentoria
---

> Capítulo gerado a partir da [apostila completa](../apostila.md), que é a fonte. Não edite este arquivo: a correção entra na `apostila.md`, e os capítulos são gerados de novo.

[Índice](../README.md#capítulos) · [Anterior: 7. Tempo: agendamento, data lógica, reprocesso e catchup](07-tempo.md) · [Próximo: 9. Saber que falhou: registro de carga, alerta e falha silenciosa](09-saber-que-falhou.md)

## 8. Fuso horário: o dia de quem?

"Por que aparece atendimento à meia-noite se a loja fecha às 22h?"

Ninguém atendeu à meia-noite. O atendimento foi às 21h em Brasília, e o sistema gravou o horário em UTC. O dado não está errado. Está em outro fuso.

Na orquestração, o fuso decide duas coisas: a que horas a carga roda e em que dia cada registro cai. Vamos ver as duas.

### 8.1 UTC por padrão

"Por que o Airflow não usa o horário de Brasília?"

**O que é**

UTC é o tempo universal coordenado. Em 2026, Brasília fica três horas atrás dele o ano inteiro. O Brasil não tem horário de verão desde 2019, e a imagem do Airflow 3.3.2 calcula -03:00 para `America/Sao_Paulo` em janeiro e em outubro.

**Como funciona no Airflow**

O Airflow guarda datas em UTC, por dentro e no banco de metadados. O fuso padrão, `default_timezone`, vem como `utc`, e a documentação recomenda deixar assim.

**O equívoco comum**

Achar que, operando só no Brasil, dá para guardar tudo no horário de Brasília. A documentação diz que, mesmo num fuso só, é boa prática guardar o dado em UTC no seu banco, por causa das transições de horário de verão. Guarde em UTC e converta para Brasília só na hora de dizer a que dia o registro pertence.

### 8.2 Agendar: meia-noite de quem?

"Agendei para meia-noite. Por que rodou às 21h?"

**Como funciona no Airflow**

Data sem fuso vale no fuso padrão. Com o padrão em `utc`, um cron `"0 0 * * *"` dispara à meia-noite UTC, que são 21h em Brasília. A carga de uma loja que fecha às 22h roda antes de o dia acabar.

A documentação prefere Dags em UTC; quando a agenda precisa seguir o horário local, ela indica um `start_date` com fuso, criado com `pendulum`. No laboratório, a agenda também leva o fuso escrito no `CronTriggerTimetable`. As mesmas tarefas ganharam Dags com agendas diferentes; as duas últimas abaixo têm janela de dados de um dia.

O bloco é um trecho do `datas_por_timetable.py` do laboratório: mostra quatro das seis Dags do arquivo, em outra ordem. As importações (`pendulum`, `timedelta` de `datetime` e `CronTriggerTimetable` de `airflow.sdk`) e a função `_build`, que monta cada Dag com as mesmas três tarefas, vêm antes delas, no mesmo arquivo. Copiado sozinho, o trecho não roda; o nível 3 declarado no fim do capítulo vale para o arquivo completo.

```python
UTC_START = pendulum.datetime(2026, 10, 19, tz="UTC")
SP_START = pendulum.datetime(2026, 10, 19, tz="America/Sao_Paulo")

datas_cron_puro = _build(
    "datas_cron_puro",
    "0 0 * * *",
    UTC_START,
    "bare cron string, default config",
)
datas_22h_brasilia = _build(
    "datas_22h_brasilia",
    CronTriggerTimetable("0 22 * * *", timezone="America/Sao_Paulo"),
    SP_START,
    "store closing time in Brasilia, no interval",
)
datas_trigger_intervalo = _build(
    "datas_trigger_intervalo",
    CronTriggerTimetable("0 0 * * *", timezone="UTC", interval=timedelta(days=1)),
    UTC_START,
    "CronTriggerTimetable with interval of one day",
)
datas_dia_brasilia = _build(
    "datas_dia_brasilia",
    CronTriggerTimetable(
        "0 0 * * *", timezone="America/Sao_Paulo", interval=timedelta(days=1)
    ),
    SP_START,
    "local calendar day in Brasilia, interval of one day",
)
```

**O equívoco comum**

Achar que o problema é só do Airflow. O cron do sistema operacional também tem fuso. O capítulo 4 já mostrou o relógio do contêiner do cron em UTC: no laboratório, ele marcava 16:38 quando eram 13:38 em Brasília. No cronie, a variável `CRON_TZ` define o fuso da tabela. O pacote `cron` do Debian roda num fuso só e não aceita fuso por usuário.

### 8.3 Gravar: o dia de quem?

"Em que dia esse atendimento entra no relatório?"

**Como funciona na prática**

Agendar no fuso certo não resolve o dado. O contexto e os templates entregam datas em UTC, mesmo com a agenda em `America/Sao_Paulo`. A documentação diz que o Airflow não converte essas datas para o horário local: cabe à Dag calcular o dia carregado.

O caso que mais engana é o `ds`. Ele é a data lógica no formato `AAAA-MM-DD`, tirada do valor em UTC. Uma Dag agendada às 22h de Brasília do dia 28, sem `interval`, recebe `ds=2026-10-29`. Quem grava em `dt={{ ds }}` manda a carga do dia 28 para a partição do dia 29.

**O caso da meia-noite, em Python**

Vamos refazer o caso com seis atendimentos sintéticos gravados em UTC:

```python
# Synthetic store visits stored in UTC. The store closes at 22:00 Brasilia time.
VISITAS_UTC = [
    "2026-10-27T12:15:00+00:00",  # 27/10 09:15 Brasilia
    "2026-10-27T17:40:00+00:00",  # 27/10 14:40 Brasilia
    "2026-10-28T00:00:00+00:00",  # 27/10 21:00 Brasilia, looks like midnight in UTC
    "2026-10-28T00:45:00+00:00",  # 27/10 21:45 Brasilia
    "2026-10-28T13:05:00+00:00",  # 28/10 10:05 Brasilia
    "2026-10-29T00:30:00+00:00",  # 28/10 21:30 Brasilia
]
```

Saída real, em trechos, das execuções agendadas:

```text
## datas_cron_puro | scheduled__2026-10-29T00:00:00+00:00 | mostrar_datas
DATAS logical_date=2026-10-29T00:00:00+00:00 (Brasilia 28/10 21:00)
## datas_22h_brasilia | scheduled__2026-10-29T01:00:00+00:00 | template_ds
TEMPLATE ds=2026-10-29 data_interval_start=2026-10-29 01:00:00+00:00
## datas_trigger_intervalo | scheduled__2026-10-29T00:00:00+00:00 | receita_particao
RECEITA janela=[2026-10-28T00:00:00+00:00, 2026-10-29T00:00:00+00:00)
RECEITA particao_gravada=dt=2026-10-28
RECEITA linhas_lidas=3
RECEITA linha utc=2026-10-28T00:00:00+00:00 brasilia=27/10 21:00
RECEITA linha utc=2026-10-28T00:45:00+00:00 brasilia=27/10 21:45
RECEITA linha utc=2026-10-28T13:05:00+00:00 brasilia=28/10 10:05
## datas_dia_brasilia | scheduled__2026-10-29T03:00:00+00:00 | receita_particao
RECEITA janela=[2026-10-28T03:00:00+00:00, 2026-10-29T03:00:00+00:00)
RECEITA particao_gravada=dt=2026-10-28
RECEITA linhas_lidas=2
RECEITA linha utc=2026-10-28T13:05:00+00:00 brasilia=28/10 10:05
RECEITA linha utc=2026-10-29T00:30:00+00:00 brasilia=28/10 21:30
```

Leia de cima para baixo. O cron sem fuso disparou às 21h de Brasília. A Dag das 22h recebeu o `ds` do dia seguinte. A janela em UTC gravou no dia 28 dois atendimentos do dia 27 e perdeu o das 21h30 do próprio dia 28. A janela em Brasília leu exatamente o dia local.

Nas duas janelas, a partição saiu `dt=2026-10-28`. Na de Brasília, por coincidência: 03:00 UTC ainda é dia 28. Não confie nisso. Converta o início da janela para o horário de Brasília antes de montar o nome da partição, como a saída acima já mostra ao lado de cada horário em UTC.

**O mesmo deslocamento em SQL**

No laboratório, o ERP sintético guarda o horário local, sem fuso. No Postgres, `AT TIME ZONE 'America/Sao_Paulo'` sobre um horário sem fuso lê o valor como horário daquele fuso e devolve um horário com fuso. A silver guarda as duas coisas: o instante e o dia local. É o `silver_pedidos.sql` da seção 3.2, sem mudança: `criado_em AT TIME ZONE 'America/Sao_Paulo'` vai para `criado_em_utc`, e `criado_em::date`, o dia do horário local, vai para `dia_local`.

Saída real, linha do pedido 104, na bronze e depois na silver, lida numa sessão em UTC:

```text
 id  |   cliente    | valor  | valor_texto |  status   |      criado_em      | _dia_referencia
 104 | Cliente D    | 310.90 | 310,90      | pago      | 2026-10-20 21:30:00 | 2026-10-20

 id  |    cliente    | valor  |    status    |     criado_em_utc      | dia_local
 104 | Cliente D     | 310.90 | pago         | 2026-10-21 00:30:00+00 | 2026-10-20
```

O pedido das 21h30 do dia 20 vira 00:30 UTC do dia 21. Agrupar pela data UTC jogaria esse pedido para o dia seguinte. A gold soma o dia pelo `dia_local`, e o pedido conta no dia 20. Saída real da gold na mesma execução:

```text
    dia     | pedidos | pedidos_pagos | receita_paga
 2026-10-20 |       4 |             2 |       430.90
```

A receita paga de 430,90 inclui os 310,90 do pedido 104. É a frase do capítulo 3 em ação: o Airflow não converte o horário do dado; quem converte o pedido para o dia local é o SQL da silver.

**O equívoco comum**

Achar que o servidor no Brasil resolve. Com o padrão em `utc`, data sem fuso é lida como UTC, onde quer que a máquina esteja. Quem cuida do dia local é a sua Dag e o seu SQL.

### 8.4 A tela também tem fuso

"A interface mostra 21:00. Rodou fora de hora?"

Talvez não. Na 3.3.2, a interface mostra os horários no fuso do navegador por padrão, e um seletor oferece UTC, o fuso detectado e a lista completa. No laboratório, a mesma execução apareceu com 29/10 no identificador, que é UTC, e 28/10 21:00 na coluna Executar Depois.

**O equívoco comum**

Confiar na página oficial de fuso. Em dois trechos, ela diz que a interface mostra UTC; o código da 3.3.2 usa o fuso do navegador. Antes de concluir que a carga rodou fora de hora, confira o fuso escolhido no seletor.

**Como inspecionar**

Rode no ambiente do Airflow:

```bash
airflow config get-value core default_timezone
```

Saída no laboratório: `utc`. Depois, faça o teste da linha conhecida. Escolha um registro cujo horário você sabe, como o atendimento das 21h, e confira em que dia ele caiu na silver e na gold.

**Para levar**

Guarde em UTC. Agende com o fuso escrito. Calcule o dia local na Dag ou no SQL, e não confie no `ds` para isso.

**Verificação do código deste capítulo**

- Dag `datas_por_timetable.py` (agendas e atendimentos sintéticos): nível 3. Executada em 2026-10-29, em ambiente descartável, com a imagem `apache/airflow:3.3.2` (Python 3.13), num contêiner `standalone`; a apostila fixa `apache/airflow:3.3.2-python3.13`, com o mesmo Python. Comandos que provaram: `airflow dags unpause` em cada Dag, com `catchup=False`, que cria a execução agendada mais recente; leitura dos logs das tarefas com o script `extrair_logs.py` do laboratório; e `airflow config get-value core default_timezone`, que devolveu `utc`.
- Mesma Dag no nível 2: `ruff check --select AIR,E,F,W,I --preview dags/` e `ruff format --check dags/` com ruff 0.12.12, sem erro, em 2026-10-29.
- SQL da silver com `AT TIME ZONE`: nível 3. Executado em 2026-10-29 com Postgres `16.15-alpine`. Comandos que provaram: `python scripts/pipeline.py --dia 2026-10-20`, a consulta à `silver.pedidos` depois de `SET TimeZone = 'UTC'` e a consulta à `gold.vendas_por_dia`.
- Fuso do contêiner do cron: nível 3, `date` dentro do contêiner do laboratório em 2026-10-29. O laboratório usou o `crond` do busybox; `CRON_TZ` e o comportamento do cron do Debian ficam no nível 1, só documentação.

Com a hora e o dia no lugar, falta saber quando a carga deu errado. É o capítulo 9.

---

[Índice](../README.md#capítulos) · [Anterior: 7. Tempo: agendamento, data lógica, reprocesso e catchup](07-tempo.md) · [Próximo: 9. Saber que falhou: registro de carga, alerta e falha silenciosa](09-saber-que-falhou.md)
