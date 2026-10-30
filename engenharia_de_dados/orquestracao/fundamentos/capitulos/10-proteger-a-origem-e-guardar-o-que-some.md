---
title: "10. Proteger a origem e guardar o que some"
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

[Índice](../README.md#capítulos) · [Anterior: 9. Saber que falhou: registro de carga, alerta e falha silenciosa](09-saber-que-falhou.md) · [Próximo: 11. Onde rodar e quanto custa: a decisão do gestor](11-onde-rodar-e-quanto-custa.md)

## 10. Proteger a origem e guardar o que some

Dois cuidados vêm antes de qualquer Dag. O primeiro é ler a origem sem travá-la. O segundo é perceber que alguns dados só existem hoje. Se ninguém guardar, amanhã sumiram.

### 10.1 Ler sem travar: a réplica só leitura

"O ERP trava quando eu consulto em produção. Por onde começo?"

**O que é**

Réplica só leitura é uma cópia do banco de produção que aceita consulta e não aceita escrita. No PostgreSQL, a réplica em espera ativa (hot standby) é estritamente só leitura: nem tabela temporária se grava nela.

**Como funciona na prática**

No laboratório, a réplica é simulada por um papel de leitura no mesmo servidor. O armazém é o banco que guarda as camadas bronze, silver e gold, e ele lê esse papel com `postgres_fdw`. O trecho abaixo cria o papel.

```sql
-- Excerpt from the lab init script: the superuser creates the role,
-- the owner of the erp database runs the grants.
CREATE ROLE replica_leitura LOGIN PASSWORD :'replica_pw';
ALTER ROLE replica_leitura SET default_transaction_read_only = on;
GRANT CONNECT ON DATABASE erp TO replica_leitura;
GRANT USAGE ON SCHEMA public TO replica_leitura;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replica_leitura;
```

Nível 3: trecho do script de inicialização do laboratório, executado em ambiente descartável em 2026-10-29, PostgreSQL 16.15; `:'replica_pw'` é variável passada ao psql com `-v`.

Vamos ver qual linha protege de verdade. Um UPDATE comum falha porque a transação é só leitura. Abra a transação como leitura e escrita, e o padrão cai. Quem barra a escrita é a permissão:

```text
$ docker compose exec -T postgres psql -U replica_leitura -h localhost -d erp -c "BEGIN READ WRITE; UPDATE pedidos SET valor = 0 WHERE id = 101;"
BEGIN
ERROR:  permission denied for table pedidos
```

Nível 3: executado em ambiente descartável em 2026-10-29, PostgreSQL 16.15 (imagem `postgres:16.15-alpine`), com o comando acima.

Um detalhe do laboratório: o `postgres_fdw` chega ao banco remoto por um servidor estrangeiro, o objeto que guarda os dados de conexão desse banco. Aqui, ele aponta para o nome do serviço, não para `127.0.0.1`. Quando quem conecta não é superusuário, o `postgres_fdw` exige que o servidor remoto peça senha. A imagem oficial deixa `127.0.0.1` entrar sem pedir senha (regra `trust`), e a conexão falha; pelo nome do serviço, a regra pede senha.

Mesmo com réplica de verdade, dê ao usuário da carga só SELECT.

**E no SQL Server?**

O laboratório só tem Postgres; o SQL Server não foi testado aqui. A edição que tem réplica legível ficou no capítulo 2: a Enterprise, não a Standard. Um detalhe a mais da documentação da Microsoft: a réplica legível do Always On não aceita gravação nos bancos secundários, mas aceita em outros bancos da mesma instância.

**O equívoco comum**

Achar que `default_transaction_read_only` protege. Ele é um padrão, e padrão se contorna. A barreira é a permissão.

### 10.2 Não sufocar a origem

"A réplica aguenta qualquer coisa que eu rodar?"

**O que é**

Pool é o limite de tarefas simultâneas contra um mesmo sistema.

**Como funciona na prática**

Sem ajuste, o Airflow deixa até 16 execuções da mesma Dag rodarem juntas, e o pool padrão tem 128 vagas. Para uma origem frágil, use um pool com poucas vagas e `max_active_runs` baixo na Dag. A Dag da loja, no laboratório, roda com `max_active_runs=1`.

O reprocessamento de datas passadas também pesa. Cada dia vira uma execução, e cada execução lê a origem. Ensaie antes com `--dry-run`, que imprime as datas consideradas. Depois limite com `--max-active-runs`. O limite da Dag não vale para o backfill, como a seção 7.3 mostrou: a Dag da loja, com `max_active_runs=1`, rodou três dias do backfill ao mesmo tempo, porque o backfill guardou o próprio limite, 10.

Nível 3: executado em ambiente descartável em 2026-10-29, Airflow 3.3.2 (imagem `apache/airflow:3.3.2`, Python 3.13.15), com `airflow backfill create --dag-id loja_ingenua --from-date 2026-10-21 --to-date 2026-10-23T23:59:59+00:00 --reprocess-behavior completed`. As três execuções começaram com menos de 2 milissegundos de diferença, e o registro do backfill no banco de metadados do Airflow mostrou `max_active_runs` 10.

A hora cheia é outro risco. Quase todo mundo agenda à meia-noite ou na hora redonda, e os picos se somam na plataforma e na origem. A Shopify relata ter espalhado os horários de forma determinística, a partir de um hash do nome da Dag. O livro de SRE do Google descreve o mesmo problema.

**O equívoco comum**

Pensar que a réplica é infinita. Ela protege a produção e ainda sente cada consulta que você manda.

### 10.3 O dado que some: a foto agendada

"O sistema troca o preço toda noite. Como eu sei o preço de ontem?"

**O que é**

Quando a origem troca um valor sem guardar o anterior, o histórico só existe se alguém capturar o valor antes da troca. Há dois caminhos: uma foto agendada ou a captura de mudanças (CDC).

**Como funciona na prática**

Se a escolha for a foto, o papel da orquestração é fazê-la rodar todo dia, no horário e no fuso certos, com nova tentativa e alerta se falhar. O valor sobrescrito entre duas fotos não se recupera depois.

O laboratório não tem a Dag da foto, mas o cabeçalho da Dag da loja, que você viu na seção 6.4, mostra três dessas escolhas: o horário em `schedule="0 6 * * *"`, o fuso na `start_date` em `America/Sao_Paulo` e a nova tentativa em `default_args`. O alerta não está nesse cabeçalho; o capítulo 9 mostra como ligar. A execução das 6h de Brasília apareceu com a data `2026-10-29T09:00:00+00:00`, em UTC, como o capítulo 8 explica. Nível 3: executado em ambiente descartável em 2026-10-29, Airflow 3.3.2, com `airflow dags list-import-errors` sem erro e execuções em sucesso.

Nas camadas bronze, silver e gold, prática recomendada e não obrigatória, a foto é dado cru e entra antes de qualquer tratamento.

Se você ainda roda quase tudo à mão, tudo bem. A foto é forte candidata a ser o primeiro passo agendado, porque o dia em que ela falha não volta.

**O equívoco comum**

Achar que dá para buscar depois. Ninguém volta no tempo para fotografar o preço de ontem.

### 10.4 O que é de Orquestração e o que é de Modelagem

"Guardar as versões do preço é trabalho do Airflow?"

| Pergunta | De quem é |
|---|---|
| A que horas a foto roda, em que fuso, com nova tentativa, alerta e registro de carga | Orquestração |
| Como guardar e consultar as versões, com colunas de vigência | Modelagem e transformação |
| Se a foto diária resolve ou se o caso pede CDC | Negócio, com o time |

A técnica se chama dimensão de mudança lenta (slowly changing dimension, SCD). O tipo 1 sobrescreve o valor e perde o histórico. O tipo 2 acrescenta uma linha nova, com início e fim de vigência e um indicador da linha atual.

O snapshot do dbt implementa o tipo 2 sobre tabela que muda, com as colunas `dbt_valid_from` e `dbt_valid_to`. A documentação do dbt chama o snapshot de captura de mudanças em lote: ele compara a tabela a cada execução e não lê o log do banco, como faz o CDC do glossário. Por isso continua sendo uma foto, e o que muda entre duas fotos se perde. Ele precisa rodar em agenda, em geral entre uma vez por hora e uma vez por dia, com a ressalva de que cada caso pode variar.

Duas notas valem desde já. Na estratégia `check`, sem `updated_at` configurado, o início de vigência é o horário da execução: a hora da foto vira o início de vigência, e não o momento em que o preço mudou na origem. E snapshot não se reconstrói; a documentação sugere um schema separado para ele.

O como fica para o conceito de Modelagem e transformação. A lição de orquestração é esta: a foto que não rodou não volta.

Réplica, foto no horário e alerta custam máquina e gente. O capítulo 11 põe número nisso.

---

[Índice](../README.md#capítulos) · [Anterior: 9. Saber que falhou: registro de carga, alerta e falha silenciosa](09-saber-que-falhou.md) · [Próximo: 11. Onde rodar e quanto custa: a decisão do gestor](11-onde-rodar-e-quanto-custa.md)
