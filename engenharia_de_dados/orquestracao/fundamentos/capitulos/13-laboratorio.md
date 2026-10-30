---
title: "13. Laboratório"
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

[Índice](../README.md#capítulos) · [Anterior: 12. Do script à Dag: o mesmo fluxo, muda quem roda](12-do-script-a-dag.md) · [Próximo: 14. Exercícios, entregáveis e mini-desafio](14-exercicios-entregaveis-e-mini-desafio.md)

## 13. Laboratório

"Entendi o conceito. Dá para ver isso funcionando no meu computador, sem servidor e sem nuvem?"

Dá. Este laboratório roda a rede de lojas fictícia numa máquina comum, com dados sintéticos. Você vai rodar o fluxo à mão e como Dag, ver o número da diretoria dobrar e voltar ao certo, receber um alerta e entender o atendimento da meia-noite.

| Lab | O que você vê | Perfil do compose |
|---|---|---|
| 0 | A máquina pronta | nenhum |
| 1 | Réplica só leitura e o fluxo à mão | `manual` |
| 2 | A primeira Dag | `airflow` |
| 3 | Registro de carga com alerta | `airflow` |
| 4 | Duplicar e consertar | `manual` e `airflow` |
| 5 | Meia-noite e datas | `airflow` |

**Onde está o código**

O laboratório fica no módulo do Airflow desta trilha, na pasta `engenharia_de_dados/orquestracao/airflow/lab/` do repositório clonado. É um compose leve só: o Postgres sobe sempre, o `runner` do fluxo à mão fica no perfil `manual`, e o Airflow, com as Dags da primeira execução, do registro de carga, da loja e das datas, no perfil `airflow`. Rode todos os comandos de dentro dessa pasta. O ambiente sobe uma vez e fica no ar do Lab 1 ao Lab 5; só o fim do Lab 5 derruba tudo. O `README.md` da pasta repete o passo a passo, e a pasta `saidas/` guarda a saída real de cada lab.

**Como ler o nível de cada bloco**

Todo bloco traz o nível de verificação. Nível 1: conferido na documentação oficial. Nível 2: passa no validador. Nível 3: executado em ambiente descartável, com a saída capturada.

Salvo onde o bloco diz outra coisa, tudo foi executado em 2026-10-29, com Airflow 3.3.2 (Python 3.13.15) e PostgreSQL 16.15, em Linux nativo, no laboratório da pasta acima. A subida do Airflow e o Lab 3 rodaram também no Windows, com WSL2 e Docker Engine dentro do Ubuntu, na versão do laboratório usada para escrever esta apostila, com a mesma imagem e as mesmas Dags. O compose passou em `docker compose config -q`, e as Dags passaram no `ruff check` e no `ruff format --check` (ruff 0.12.12).

### Lab 0: Preparar a máquina

"Meu notebook é Windows. Aguenta?"

Pré-condição: Linux, ou Windows 10 versão 2004 ou mais nova, ou Windows 11. O Windows Home não é coberto por este material.

**No Windows, o Airflow pede o WSL2**, o Linux que roda dentro do Windows. O guia de início do Airflow também manda trabalhar na home do Linux.

```powershell
wsl --install
```

*Nível 1: conferido na documentação da Microsoft em 2026-10-29; não executado neste laboratório.*

Rode no PowerShell como administrador, no Windows 10 versão 2004 (build 19041) ou no Windows 11. O comando instala o Ubuntu já em WSL 2 e pede reinício. No primeiro uso, você cria usuário e senha do Linux, sem relação com os do Windows.

**Docker, dois caminhos.** O testado aqui é o Docker Engine dentro do Ubuntu. O outro é o Docker Desktop com backend WSL 2: pede WSL 2.1.5 ou mais novo, Windows 10 22H2 ou Windows 11 23H2 nas edições Enterprise, Pro ou Education, 8 GB de RAM e virtualização ligada na BIOS. Com WSL antigo, o `vmmem.exe` pode consumir toda a memória. O Docker Desktop não foi verificado neste laboratório.

**Licença do Docker Desktop.** É grátis para uso pessoal, educação, código aberto não comercial e empresas com menos de 250 funcionários **e** menos de 10 milhões de dólares de receita anual. Uso profissional em organização maior e em governo exige assinatura paga. No notebook da empresa, confira antes.

**Memória.** O Airflow recomenda no mínimo 4 GB. No Windows, a VM do WSL2 recebe por padrão metade da memória: num Windows de 8 GB, cerca de 4 GB e mais 2 GB de swap. O limite muda no `%UserProfile%\.wslconfig`, que só vale depois que a VM para (`wsl --shutdown`).

Os contêineres são leves: cerca de 0,7 GiB ociosos e pico de 1,1 GiB. Sob teto rígido de 1,8 GiB, sem swap, o cenário completo rodou. Com duas CPUs, ficou saudável em 91 s, dentro da faixa medida com 14. No Windows, o que pesa é o cache: no teste, a VM do WSL chegou a 9,2 GB, e a memória livre do Windows caiu a cerca de 2 GB. Numa máquina com 8 GB físicos, isso não foi medido.

**Disco: olhe o físico.** O disco virtual do WSL mora no C:, e o `df` do Linux mostra o tamanho máximo dele, não o que sobra no C:. Só a imagem do Airflow ocupa 2,33 GB. Confira no PowerShell:

```powershell
Get-PSDrive C | Select-Object Free
```

*Nível 3: executado no Windows do teste em 2026-10-29. Saída: o espaço livre do C:, em bytes.*

**Clone na home do Linux, não em `/mnt/c`.** A Docker e a Microsoft recomendam o sistema de arquivos do Linux. No teste, ler arquivo no contêiner foi de 120 a 170 vezes mais lento em `/mnt/c`; nas Dags pequenas daqui, o Airflow não mostrou diferença. A máquina do teste tinha a opção `metadata` ligada no `/mnt/c`, que não é o padrão do WSL; sem ela, não foi verificado. Prefere editor do Windows? Grave pelo caminho `\\wsl.localhost`: Dag nova apareceu em cerca de 29 s.

**Fim de linha LF.** Quem clona de dentro do Ubuntu recebe os `.sh` com LF. O risco é o Git for Windows com `core.autocrlf=true`, que troca LF por CRLF. Com CRLF, o `preparar.sh` falha com `bash\r` não encontrado e não cria o `.env`. Se o CRLF estiver no script de inicialização do Postgres, a primeira subida cai, e na seguinte o Postgres fica pronto sem a base `loja`, sem que o teste de saúde perceba. Um `.gitattributes` com `*.sh text eol=lf` força LF.

**O dono dos arquivos.** Na pasta do laboratório, rode:

```bash
./preparar.sh
```

*Nível 3: executado em Linux nativo e no WSL2, 2026-10-29.*

Saída esperada: `.env criado com AIRFLOW_UID=1000 e segredos aleatórios.` No WSL, o primeiro usuário recebe o UID 1000; no Linux, aparece o seu número. O guia do Compose do Airflow manda gravar `AIRFLOW_UID=$(id -u)`, senão os arquivos ficam com dono root. Tutorial antigo fixa 50000: o ambiente sobe, mas criar ou editar Dag dá `Permission denied`.

**Imagem e porta.** A página da imagem diz que o Python padrão é o 3.12, mas a `apache/airflow:3.3.2` roda o 3.13.15. O compose do laboratório já fixa a tag explícita `apache/airflow:3.3.2-python3.13`; no registro, as duas tags têm o mesmo digest. A interface abre sem login, por isso a porta fica presa ao `127.0.0.1`. Com Docker Engine no WSL, o encaminhamento de localhost, ligado por padrão, leva a porta ao Windows; abrir a interface no navegador do Windows não foi verificado.

**Nota sobre SQL Server.** O laboratório usa só PostgreSQL. A imagem do Airflow 3.3.2 não traz o provider do SQL Server, e o `postgres_fdw` lê só servidores PostgreSQL. O caminho com SQL Server não foi testado aqui.

**O equívoco comum**

Copiar número do tutorial. O espaço se mede no disco físico, e o UID se lê na sua máquina.

### Lab 1: Réplica só leitura e o fluxo à mão

"Como leio o ERP sem travar a produção? E dá para rodar bronze, silver e gold sem ferramenta nova?"

Pré-condição: Lab 0. Rode na pasta do laboratório.

A réplica aqui é simulada: o banco `erp` tem um papel que só lê, e o banco `dw` lê esse banco pelo `postgres_fdw`, a extensão que acessa dados de outro servidor PostgreSQL. Tudo em SQL.

```bash
docker compose up -d --wait postgres
docker compose exec -T postgres psql -U dw -d dw \
  -c "SELECT count(*) AS pedidos_lidos_pela_replica FROM replica.pedidos;"
docker compose exec -T postgres psql -U replica_leitura -h localhost -d erp \
  -c "BEGIN READ WRITE; UPDATE pedidos SET valor = 0 WHERE id = 101;"
```

*Nível 3: PostgreSQL 16.15, Linux nativo, 2026-10-29.*

Saída esperada: a contagem dá `10`, e a escrita falha com `ERROR:  permission denied for table pedidos`.

Repare no `BEGIN READ WRITE`. O papel tem a sessão marcada como só leitura, e esse comando contorna a marca. Quem barra de fato é o GRANT apenas de SELECT.

Agora o degrau à mão. Um script Python executa os arquivos SQL de cada camada, em ordem, numa transação só. O tratamento fica no SQL; o Python só executa.

```bash
docker compose build runner
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-21
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-22
```

*Nível 3: imagem `python:3.13.15-alpine3.24` com `psycopg[binary]==3.3.5`, PostgreSQL 16.15, 2026-10-29.*

Saída esperada, na última linha de cada dia:

```text
  resultado: bronze=4 silver=4 receita_paga=430.90
  resultado: bronze=3 silver=3 receita_paga=111.90
  resultado: bronze=3 silver=3 receita_paga=293.30
```

Cada dia levou cerca de 3 s, sem Airflow. O serviço `runner` pertence ao perfil `manual` do compose, mas citá-lo pelo nome no `run` já o executa sem ativar o perfil.

Quando montamos este laboratório, a primeira tentativa falhou: um comentário SQL tinha ponto e vírgula, e o script divide os arquivos nesse caractere. Nada foi gravado, porque a transação desfez tudo. É o que você quer de um fluxo à mão.

**O equívoco comum**

Achar que marcar a sessão como só leitura protege o banco. Neste laboratório, quem barra a escrita é a permissão. Numa réplica de verdade do PostgreSQL, em hot standby, o próprio servidor recusa qualquer escrita.

### Lab 2: A primeira Dag

"Quando o Airflow entra, eu reescrevo tudo?"

Não. Muda quem roda. Pré-condição: Lab 0. Rode na pasta do laboratório.

```bash
docker compose --profile airflow up -d --wait --wait-timeout 300
docker compose exec airflow-scheduler airflow dags list-import-errors
docker compose exec airflow-scheduler airflow dags unpause ola_orquestracao
docker compose exec airflow-scheduler airflow dags trigger ola_orquestracao
docker compose exec airflow-scheduler airflow dags list-runs ola_orquestracao
```

*Nível 3: Airflow 3.3.2, LocalExecutor e PostgreSQL 16.15, Linux nativo, 2026-10-29.*

Saída esperada: `No data found` nos erros de importação e a execução em `success` cerca de 10 s depois do disparo. No log da tarefa `carregar`, aparece `Total do dia: 245.5`. A interface fica em `http://127.0.0.1:8080`.

O ambiente fica saudável em cerca de 1 min 21 s a 1 min 27 s na primeira vez e 53 s nas seguintes, com a imagem já baixada. No Windows do teste, 41 a 42 s.

A Dag tem três tarefas em sequência, sem sistema externo:

```python
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
```

*Trecho do arquivo executado acima (nível 3); imports de `airflow.sdk`.*

O fluxo da loja como Dag está em `dags/pipeline_loja.py`. Ele lê os mesmos arquivos SQL do Lab 1, uma tarefa por camada: `bronze >> silver >> gold >> registrar_carga`. Você o roda no Lab 4.

**Se a Dag não aparecer.** O Airflow procura arquivos novos por varredura periódica, a cada 300 s no padrão. O laboratório reduz para 30 s.

**Se a máquina apertar.** Sem servidor, `airflow dags test` num contêiner que sai roda esta Dag com SQLite em cerca de 33 s. O `airflow standalone` sobe tudo num contêiner, mas usa cerca de 1 GiB: o ganho é simplicidade, não memória.

**O equívoco comum**

Achar que o Airflow é o código de limpeza. Ele é quem roda o código.

### Lab 3: Registro de carga e alerta

"Como sei que a carga falhou, se ela termina verde?"

Registro de carga é a tabela com cada carga: quando rodou, se foi agendada ou manual, quantas linhas. Pré-condição: Lab 2, Airflow no ar.

A Dag `registro_de_carga` trata os pedidos em SQL no banco, grava a contagem em `controle_carga` e compara com a carga anterior. Se repetir, a checagem falha e o alerta dispara. O código da checagem e do alerta é o da seção 9.4, no arquivo `dags/registro_de_carga.py` (nível 3).

Despause a Dag e espere a execução agendada, criada nesse momento, aparecer em `success`:

```bash
docker compose exec airflow-scheduler airflow dags unpause registro_de_carga
docker compose exec airflow-scheduler airflow dags list-runs registro_de_carga
```

Depois, chegam dois pedidos novos e você dispara duas cargas manuais:

```bash
docker compose exec postgres psql -U loja -d loja -c \
  "INSERT INTO pedidos_origem (id, cliente, valor, status, criado_em) VALUES
   (6, 'Cliente E', 99.90, 'pago', '2026-10-29 10:00:00'),
   (7, 'Cliente F', 15.00, NULL, '2026-10-29 11:30:00');"
docker compose exec airflow-scheduler airflow dags trigger registro_de_carga
docker compose exec airflow-scheduler airflow dags trigger registro_de_carga
docker compose exec postgres psql -U loja -d loja -c \
  "SELECT id, run_id, tipo_execucao, linhas FROM controle_carga ORDER BY id;"
```

*Nível 3: Airflow 3.3.2, Linux nativo e Windows com WSL2 e Docker Engine, 2026-10-29.*

Saída esperada: três linhas em `controle_carga`. A agendada, criada ao despausar, com 5. A primeira manual, com 7, que passa. A segunda manual repete 7 e falha em `checar_repeticao`. No log dessa tarefa, filtrado:

```text
ValueError A contagem repetiu a carga anterior (7 linhas). A origem pode não ter sido atualizada.
ALERTA: a task checar_repeticao falhou na execução manual__...
```

Vamos ver o que aconteceu. A carga rodou sem erro, e a origem não mudou. Sem o registro, a execução seria verde. O alerta aqui escreve no log para o laboratório não precisar de credencial. Na vida real, o mesmo callback chama um notifier que manda e-mail ou mensagem; esse envio não foi testado neste laboratório.

Contagem repetida é sinal, não prova. Ela pede que alguém olhe.

Terminou? Deixe o ambiente no ar: o Lab 4 usa o mesmo banco e o mesmo Airflow.

**O equívoco comum**

Tratar verde como dado certo. Verde quer dizer que o código terminou, não que o número chegou.

### Lab 4: Duplicar e consertar

"Se a carga rodar duas vezes, o número da diretoria dobra?"

Depende de como ela grava. Idempotência é isto: rodar de novo dá o mesmo resultado de rodar uma vez. Pré-condição: Lab 1, com o dia 20 já carregado uma vez, e o ambiente no ar. Rode na pasta do laboratório.

**À mão.** A versão ingênua só faz INSERT, sem chave. A idempotente apaga o dia e insere de novo, na mesma transação.

```bash
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20 --modo ingenuo
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20 --modo ingenuo
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20
```

*Nível 3: PostgreSQL 16.15, 2026-10-29.*

Saída esperada: `bronze=8 silver=8 receita_paga=861.80`, depois `bronze=12 silver=12 receita_paga=1292.70`, e a versão idempotente volta a `bronze=4 silver=4 receita_paga=430.90`. Todas terminam com sucesso. A idempotente conserta o dia já duplicado.

**Pela Dag, com nova tentativa.** Confirme o Airflow ao lado do mesmo banco (se ele já subiu no Lab 2, o `up` não muda nada) e despause a versão ingênua:

```bash
docker compose --profile airflow up -d --wait --wait-timeout 300
docker compose --profile airflow exec -T airflow-scheduler airflow dags list-import-errors
docker compose --profile airflow exec -T airflow-scheduler airflow dags unpause loja_ingenua
docker compose --profile airflow exec -T airflow-scheduler airflow dags list-runs loja_ingenua
```

*Nível 3: Airflow 3.3.2, Linux nativo, 2026-10-29. Interface em `http://127.0.0.1:8080`.*

Ao despausar, o Airflow cria a execução agendada mais recente. Ela carrega um dia em que a loja fictícia não tem pedido: zero linhas, e sucesso. Guarde isso: é uma falha silenciosa, a carga roda, não traz nada e termina verde. É o tipo de problema que o registro de carga do Lab 3 ajuda a pegar.

Espere essa execução terminar. Depois, zere as camadas e dispare o dia com a queda:

```bash
docker compose exec -T postgres psql -U dw -d dw \
  -c 'TRUNCATE bronze.pedidos, silver.pedidos, gold.vendas_por_dia, controle.carga RESTART IDENTITY;'
docker compose --profile airflow exec -T airflow-scheduler airflow dags trigger loja_ingenua \
  -l 2026-10-21T09:00:00+00:00 -r retry_ingenuo -c '{"simular_queda": true}'
docker compose --profile airflow exec -T airflow-scheduler airflow dags list-runs loja_ingenua
ls logs/dag_id=loja_ingenua/run_id=retry_ingenuo/task_id=bronze/
docker compose exec -T postgres psql -U dw -d dw -c 'SELECT * FROM gold.vendas_por_dia;'
```

*Nível 3: Airflow 3.3.2, Linux nativo, 2026-10-29.*

**Atenção: a falha é simulada.** O `simular_queda` faz a tarefa do bronze gravar, confirmar e cair de propósito na primeira tentativa. Na vida real, isso acontece quando o processo morre depois de gravar e antes de avisar o orquestrador.

Saída esperada, depois de a execução chegar a `success`: `attempt=1.log` e `attempt=2.log` no bronze, e o gold do dia 20 com 8 pedidos e `861.80`. A data lógica, 21/10 às 06h de Brasília, carrega o dia anterior.

Repita os dois blocos com `loja_idempotente` no lugar de `loja_ingenua` e `retry_idempotente` no lugar de `retry_ingenuo`. A segunda tentativa apaga as 4 linhas da primeira e regrava 4. O gold fica em 4 pedidos e `430.90`.

**Reprocessamento de datas passadas (backfill).** Primeiro, sempre o ensaio:

```bash
docker compose --profile airflow exec -T airflow-scheduler airflow backfill create \
  --dag-id loja_ingenua --from-date 2026-10-21 --to-date 2026-10-23 --dry-run
```

*Nível 3: Airflow 3.3.2, 2026-10-29.*

O ensaio lista uma data lógica só, `2026-10-22 09:00:00+00:00`. Data sem hora vira meia-noite em UTC, então a execução das 09:00 UTC do dia 23 fica depois do fim. A do dia 21 já existe, é a sua execução com queda, e sem reprocessar ela fica de fora.

Agora zere as camadas e rode o reprocessamento de verdade, com o fim explícito e reprocessando o que já terminou:

```bash
docker compose exec -T postgres psql -U dw -d dw \
  -c 'TRUNCATE bronze.pedidos, silver.pedidos, gold.vendas_por_dia, controle.carga RESTART IDENTITY;'
docker compose --profile airflow exec -T airflow-scheduler airflow backfill create \
  --dag-id loja_ingenua --from-date 2026-10-21 --to-date 2026-10-23T23:59:59+00:00 \
  --reprocess-behavior completed
docker compose exec -T postgres psql -U dw -d dw -c 'SELECT * FROM gold.vendas_por_dia ORDER BY dia;'
```

*Nível 3: Airflow 3.3.2, 2026-10-29.*

Rode o `backfill create` uma segunda vez, depois que as três execuções terminarem. Na ingênua, os três dias dobram: de 430,90, 111,90 e 293,30 para 861,80, 223,80 e 586,60. Zere de novo e repita com `loja_idempotente`: nas duas vezes, os números ficam em 430,90, 111,90 e 293,30, os mesmos do Lab 1.

Se a segunda vez responder `AlreadyRunningBackfill`, espere alguns segundos e tente de novo; o scheduler ainda está fechando o reprocessamento anterior.

**O equívoco comum**

Achar que nova tentativa conserta. Ela repete o que o código faz. Se o código acrescenta, ela duplica.

### Lab 5: Meia-noite e datas

"Por que aparece atendimento à meia-noite numa loja que fecha às 22h?"

Porque o horário foi gravado em UTC, três horas à frente de Brasília. Pré-condição: Lab 1 e o Airflow do Lab 2 no ar. Rode na pasta do laboratório.

```bash
docker compose exec -T postgres psql -U dw -d dw \
  -c "SET TimeZone = 'UTC';" \
  -c "SELECT id, cliente, valor, status, criado_em_utc, dia_local FROM silver.pedidos ORDER BY id;"
```

*Nível 3: PostgreSQL 16.15, 2026-10-29. Se a silver estiver vazia ou duplicada, rode antes os três comandos `pipeline.py` do Lab 1.*

Saída esperada, na linha do pedido 104:

```text
 104 | Cliente D     | 310.90 | pago         | 2026-10-21 00:30:00+00 | 2026-10-20
```

O pedido foi às 21h30 do dia 20, horário da loja. O `AT TIME ZONE 'America/Sao_Paulo'` da silver lê o horário sem fuso como sendo de Brasília e o converte. Numa sessão em UTC, ele vira 00h30 do dia 21. Agrupar pela data UTC jogaria a venda para o dia seguinte. Por isso a silver guarda `dia_local`, e o gold agrupa por ele.

**Agora a janela do orquestrador.** No mesmo Airflow, seis Dags iguais, em `dags/datas_por_timetable.py`, só mudam a agenda e leem visitas sintéticas gravadas em UTC. A loja fecha às 22h.

```bash
docker compose exec airflow-scheduler airflow dags unpause datas_trigger_intervalo
docker compose exec airflow-scheduler airflow dags unpause datas_dia_brasilia
docker compose cp checagens/extrair_logs.py airflow-scheduler:/tmp/extrair_logs.py
docker compose exec airflow-scheduler python /tmp/extrair_logs.py /opt/airflow/logs dag_id=datas_
```

*Nível 3: Airflow 3.3.2, LocalExecutor e PostgreSQL 16.15, Linux nativo, 2026-10-29, em duas rodadas, às 20h10 e às 20h23 de Brasília. Espere as duas execuções agendadas chegarem a `success`, alguns segundos depois de despausar, antes de ler os logs.*

O que a execução agendada de 2026-10-29 leu:

| Dag | Janela, em horário de Brasília | Visitas lidas |
|---|---|---|
| `datas_trigger_intervalo` (dia em UTC) | 27/10 21h00 a 28/10 21h00 | 27/10 21h00, 27/10 21h45, 28/10 10h05 |
| `datas_dia_brasilia` (dia em Brasília) | 28/10 00h00 a 29/10 00h00 | 28/10 10h05, 28/10 21h30 |

A janela em UTC pega duas visitas da noite anterior e perde a das 21h30 do próprio dia. A janela no fuso de Brasília lê exatamente o dia da loja.

**Não verificado:** reproduzir esta tabela em outra data. As visitas sintéticas são fixas, de 27 a 29 de outubro de 2026; num outro dia, a execução agendada não as encontra.

**O equívoco comum**

Achar que o dia da execução é o dia do dado. Confira a janela e o fuso antes de confiar no número.

**Desmontar o ambiente**

Ainda na pasta do laboratório, derrube tudo:

```bash
docker compose --profile airflow --profile manual down --volumes --remove-orphans
```

*Nível 3, 2026-10-29.* Somem os contêineres, o volume do banco e a rede. A imagem do `runner`, de cerca de 73 MB, fica; apague com `docker image rm orquestracao-lab-runner:local` se quiser. Se for recomeçar do zero, apague também a pasta `logs/`, para não misturar logs de rodadas diferentes.

Rodou tudo? O capítulo 14 pede que você faça sozinho.

---

[Índice](../README.md#capítulos) · [Anterior: 12. Do script à Dag: o mesmo fluxo, muda quem roda](12-do-script-a-dag.md) · [Próximo: 14. Exercícios, entregáveis e mini-desafio](14-exercicios-entregaveis-e-mini-desafio.md)
