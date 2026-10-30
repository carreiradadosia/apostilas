---
title: "Apostila completa, Engenharia de Dados"
date: 2026-10-30
type: apostila
status: active
tags: [mentoria, apostila]
---

# Apostila completa, Engenharia de Dados

> Arquivo gerado a partir do `trilha.yml`. Nao edite a mao: rode `gerar_trilha.py` novamente, senao a edicao se perde e o documento diverge.

Cada capitulo abaixo e a apostila de um modulo, na ordem recomendada da
trilha. Para estudar um assunto isolado, va direto ao modulo.

## Sumario

- [Capitulo 1, Fundamentos de orquestração](#capitulo-1-fundamentos-de-orquestração)

---

## Capitulo 1, Fundamentos de orquestração

Fonte: `orquestracao/fundamentos/apostila.md`

### Apostila, Orquestração: fundamentos, do script à mão à Dag

> Trilha de Engenharia de Dados. Conduzida por Iuri Zambotto.

#### Sumário

- [0. Como usar esta apostila](#0-como-usar-esta-apostila)
- [1. Objetivo pedagógico](#1-objetivo-pedagógico)
- [2. Contexto de negócio](#2-contexto-de-negócio)
- [3. O que é orquestrar, e o que não é](#3-o-que-é-orquestrar-e-o-que-não-é)
- [4. Os degraus: à mão, agendador, orquestrador](#4-os-degraus-à-mão-agendador-orquestrador)
- [5. Vocabulário mínimo: Dag, tarefa, dependência, execução e estado](#5-vocabulário-mínimo-dag-tarefa-dependência-execução-e-estado)
- [6. Nova tentativa e idempotência: o preço do orquestrador](#6-nova-tentativa-e-idempotência-o-preço-do-orquestrador)
- [7. Tempo: agendamento, data lógica, reprocesso e catchup](#7-tempo-agendamento-data-lógica-reprocesso-e-catchup)
- [8. Fuso horário: o dia de quem?](#8-fuso-horário-o-dia-de-quem)
- [9. Saber que falhou: registro de carga, alerta e falha silenciosa](#9-saber-que-falhou-registro-de-carga-alerta-e-falha-silenciosa)
- [10. Proteger a origem e guardar o que some](#10-proteger-a-origem-e-guardar-o-que-some)
- [11. Onde rodar e quanto custa: a decisão do gestor](#11-onde-rodar-e-quanto-custa-a-decisão-do-gestor)
- [12. Do script à Dag: o mesmo fluxo, muda quem roda](#12-do-script-à-dag-o-mesmo-fluxo-muda-quem-roda)
- [13. Laboratório](#13-laboratório)
- [14. Exercícios, entregáveis e mini-desafio](#14-exercícios-entregáveis-e-mini-desafio)
- [15. Rubrica de validação da aprendizagem](#15-rubrica-de-validação-da-aprendizagem)
- [16. Erros comuns e como corrigir](#16-erros-comuns-e-como-corrigir)
- [17. Plano de continuidade](#17-plano-de-continuidade)
- [18. Glossário](#18-glossário)
- [Referências](#referências)
- [Fontes verificadas (2026-10-29)](#fontes-verificadas-2026-10-29)
- [Reconferência na 3.4.0](#reconferência-na-340)

#### 0. Como usar esta apostila

Por onde começar, se você não tem tempo de ler tudo? Pelo seu objetivo. Cada perfil de mentorado
tem um caminho curto, e nem todo caminho passa pelo laboratório.

**Leitura linear ou revisão pontual**

Na primeira vez, leia em ordem: cada capítulo usa o vocabulário do anterior. Para revisar, vá
direto pelo sumário. Termo novo tem definição de uma frase no glossário (18).

**Roteiro por perfil**

| Se você | Leia |
|---|---|
| quer só entender do que se trata | 3 e o começo do 4 |
| gerencia e quer decidir | 2, 4 e 11, com as perguntas para o seu time no fim do 11 |
| está começando na área | do 1 ao 13, em ordem, e o exercício prático do 14 |
| já trabalha com dados e quer migrar para engenharia | 5 a 10, 12, 13 e 14 |
| já é engenheiro e mira o próximo nível | 6 a 11 e 17 |

Quem vai montar segue até o laboratório. Quem decide não precisa instalar nada. Se hoje você roda
tudo à mão, está num bom ponto de partida: o capítulo 4 mostra quando vale automatizar.

**Versão de referência**

O exemplo é o Apache Airflow 3.3.2, estável desde 2026-09-17, na imagem
`apache/airflow:3.3.2-python3.13`. A linha 2 está em fim de vida desde 2026-04-22 e não recebe
mais correção. Achou tutorial antigo? Confira a versão antes de copiar.

**O que você precisa ter**

- Para ler: SQL básico, de ler e escrever um SELECT.
- Para o laboratório: Linux ou Windows com WSL2, nas combinações testadas que o capítulo 13
  lista; Docker com Compose 2.14.0 ou mais novo; 4 GB de memória para o Docker, sendo 8 GB o
  ideal segundo a documentação do Airflow; e espaço livre no disco físico. O arquivo oficial do
  Airflow para o Compose, no serviço de inicialização, avisa sem bloquear quando há menos de 10 GB
  de disco livre, 4000 MiB de memória ou 2 CPUs. Use os 10 GB de disco como piso.

O laboratório da mentoria usa um arquivo mais leve, sem essa checagem. Confira você, no Linux ou
no terminal do WSL:

```bash
docker compose version
numfmt --to=iec $(docker info --format '{{.MemTotal}}')
```

Nível 3, executado em 2026-10-29 num Linux com Docker 28.3.3 e GNU coreutils 9.4. Saída:
`Docker Compose version v2.39.1` e `31G`. A sua será outra. Vale o Compose 2.14.0 ou mais novo.
A memória sai em GiB, potência de 1024, e num Windows de 8 GB o WSL entrega cerca de 4 GB à VM
por padrão, então um valor um pouco abaixo de 4G é esperado. Perto de 4G já é suficiente para o
laboratório leve, que usou entre 1,1 e 1,3 GiB no teste; o compose oficial pode avisar abaixo
disso.

**O equívoco comum: medir o disco errado**

No Windows, o `df` de dentro do WSL mostra o tamanho máximo do disco virtual, não o que sobra no
disco físico. O disco virtual é o arquivo `ext4.vhdx`, em geral no C:. Na máquina de teste da
mentoria, o `df` mostrava cerca de 205 GiB livres com o C: em pouco mais de 2 GB. Confira no
PowerShell:

```powershell
Get-PSDrive C | Select-Object Free
```

Nível 3, executado em 2026-10-29 no Windows 11 (versão 10.0.26200) com WSL 2.7.13.0. A saída vem
em bytes. Se o WSL ou o Docker Desktop morar em outro disco, confira esse disco.

#### 1. Objetivo pedagógico

"Pesquisei com IA como montar meus dados. Recebi uma lista de ferramentas e arquiteturas. Por onde eu começo?"

Essa pergunta veio de um gerente de TI que montava a primeira arquitetura de dados da empresa. A lista não estava errada. Mesmo assim, ele travou. Ferramenta sem conceito não ajuda a decidir.

O que destravou foi conceito em degraus, um de cada vez, com uma ferramenta só como exemplo. Esta apostila segue esse caminho.

**O que você consegue fazer ao terminar**

- **Decidir** se uma carga fica à mão, vai para um agendador ou pede um orquestrador, com custo e risco de cada opção.
- **Separar** o código que trata o dado de quem roda esse código.
- **Desenhar** um fluxo de carga como Dag: o grafo dos passos, com ordem e dependência.
- **Tornar** uma carga segura para rodar de novo, sem duplicar linha.
- **Reprocessar** dias que já passaram, sabendo que intervalo cada execução cobre.
- **Detectar** quando uma carga falhou ou terminou sem trazer dado, antes da diretoria.
- **Perguntar** ao time o que importa antes de contratar: onde roda, quanto custa, quem mantém.

**O equívoco comum**

Achar que o objetivo é aprender uma ferramenta. A ferramenta muda de versão. O critério de decisão continua valendo.

#### 2. Contexto de negócio

"Como eu garanto que o número da diretoria chega todo dia, certo? E como sei quando ele não chegou?"

A apostila inteira responde a essa pergunta. Vamos responder acompanhando uma empresa fictícia.

**A rede de lojas**

O fio condutor é uma rede de lojas fictícia, com dados sintéticos. Ela tem quatro peças.

| Peça | O que é | No laboratório |
|---|---|---|
| ERP | Sistema que registra cada pedido | Banco `erp`, tabela `pedidos` |
| Réplica só leitura | Cópia do banco do ERP que aceita consulta e não aceita escrita | Simulada por um papel que só tem GRANT de SELECT no banco `erp`; o banco `dw` lê essa réplica por `postgres_fdw` |
| Armazém | Camadas bronze, silver e gold, tratadas em SQL | Banco `dw` |
| BI | Painel da diretoria, hoje alimentado por planilha | Fora do laboratório |

(Montagem executada no nível 3 em ambiente descartável, com Airflow 3.3.2 e PostgreSQL 16.15, em
2026-10-29.)

**Por que a réplica vem antes de tudo**

Nesta rede, o ERP trava tabela quando alguém consulta direto na produção: um relatório pesado segura quem está registrando pedido. Por isso o primeiro passo não é ferramenta de dados. É a réplica.

No PostgreSQL, uma réplica em espera ativa (hot standby) só aceita leitura; nem tabela temporária pode ser gravada nela. No SQL Server, a réplica legível do Always On trata toda consulta com isolamento por instantâneo (snapshot), o que elimina a disputa entre quem lê e quem escreve.

Se você decide a compra, confira a edição antes de prometer. O grupo de disponibilidade básico, da edição Standard, não permite leitura na réplica secundária. A réplica legível é recurso do grupo completo, da edição Enterprise.

**Bronze, silver e gold**

Da réplica, o dado passa por três camadas. Bronze guarda o dado cru, como chegou. Silver guarda o dado validado. Gold guarda o dado enriquecido, pronto para o negócio.

A documentação da Databricks chama esse desenho de arquitetura medalhão. Segui-lo é prática recomendada, não requisito.

O tratamento de cada camada é SQL dentro do banco. Quem roda esse SQL na ordem certa, e guarda o que aconteceu, é o assunto desta apostila.

**Duas frequências, um teto**

Um setor quer o número duas vezes por dia. Outro quer várias vezes por hora. A diretoria vai receber o número todo dia.

A atualização agendada do Power BI permite oito por dia na capacidade compartilhada. Duas por dia cabem com folga. Em Premium, PPU ou Fabric, o teto sobe para até 48 por dia, o que dá uma a cada meia hora. Várias por hora passam desse teto. E fonte local, como um ERP na rede da empresa, exige gateway.

É o primeiro sinal de que o horário do BI não resolve tudo.

**Começar à mão é uma decisão válida**

Na mentoria, o gerente de TI do capítulo 1 decidiu rodar tudo à mão no começo e automatizar quando a entrega à diretoria virasse recorrente. Os mentores concordaram. A rede fictícia segue o mesmo caminho.

À mão, você descobre de onde vem cada número e valida o SQL. Automatizar um SQL ainda errado só repete o erro mais vezes.

A hora de subir de degrau é critério da mentoria, não norma de mercado. Os sinais: a frequência aumenta, os passos se multiplicam, você precisa de alerta e de nova tentativa (retry), a entrega vira compromisso. O capítulo 4 detalha cada um.

**O equívoco comum**

Achar que começar à mão é atraso. O risco está em automatizar antes de saber o que o número significa.

Antes de escolher degrau, vale separar o que é orquestração do que não é. É o próximo capítulo.

#### 3. O que é orquestrar, e o que não é

"Trato o dado em Python ou em SQL?" A pergunta aparece cedo, na primeira arquitetura. A resposta
curta: o tratamento fica em SQL, no banco. O Python só manda rodar, na ordem certa.

Por trás dela está a frase guia desta apostila: **o orquestrador não é o código de limpeza, é
quem roda o código.** Vamos ver por que ela vale e onde termina o papel do orquestrador.

##### 3.1 Orquestrar é rodar na ordem, com memória

"O que um orquestrador faz que um script não faz?"

**O que é**

A definição técnica é executar um fluxo definido: primeiro A, depois B, depois C. A frase está
na documentação do Kubernetes, que a usa para dizer que ele não é só isso. Nos orquestradores de
dados, esse fluxo vem com estado, nova tentativa e histórico, como mostram as
ferramentas abaixo.

**Como funciona na prática**

Ferramentas diferentes descrevem o mesmo núcleo. O Luigi cuida de dependências, fluxo,
visualização e falhas, e avisa que não substitui os motores que processam o dado: só costura as
tarefas. O Prefect promete rastrear estado, tratar falha e monitorar.

O Apache Airflow, nosso exemplo, se define como plataforma para orquestrar fluxos em lote. A
mesma página cita também treino de modelos e cargas com LLM, mas o caso típico é o lote. Serve
bem quando o fluxo tem início e fim e roda em agenda, disparado por horário ou por evento. O
fluxo é escrito em Python, o que traz versionamento, trabalho em equipe e teste. Pela interface
você dispara uma execução, lê o log, reprocessa datas passadas (backfill) e roda de novo só as
tarefas que falharam. A documentação avisa: quem prefere clicar a programar talvez não ache ali
a melhor escolha, porque algum código sempre será necessário.

**O equívoco comum**

Ver a orquestração como uma etapa do fluxo, entre ingerir e transformar. Joe Reis, coautor do
livro *Fundamentals of Data Engineering* (2022), separa as etapas do ciclo de vida (gerar,
armazenar, ingerir, transformar, servir) das correntes que atravessam todas elas. Orquestração é
uma dessas correntes, ao lado de segurança e DataOps, entre outras. O orquestrador não faz uma
etapa. Ele faz as etapas acontecerem na ordem.

##### 3.2 Quem roda o código e quem trata o dado

"Se o Airflow é programado em Python, a limpeza também não deveria ser em Python?"

**O que é**

O orquestrador decide quando e em que ordem cada passo roda. O banco executa o SQL que trata o
dado.

**Como funciona na prática**

A documentação do Airflow é direta: a Dag, o grafo de tarefas do fluxo, não se importa com o que
acontece dentro das tarefas. Ela cuida de como executá-las: ordem, tentativas, tempo limite.

Na rede de lojas desta apostila, a camada silver resolve nulo, espaço sobrando, maiúscula e fuso
do pedido que veio do bronze. Quem faz isso é este SQL, arquivo completo:

```sql
-- Clean the day: nulls, padding, case, drop the redundant text column, local time to UTC.
DELETE FROM silver.pedidos
WHERE dia_local = %(dia)s::date;

INSERT INTO silver.pedidos (id, cliente, valor, status, criado_em_utc, dia_local)
SELECT
    id,
    COALESCE(NULLIF(initcap(trim(cliente)), ''), 'Não informado'),
    valor,
    COALESCE(lower(trim(status)), 'desconhecido'),
    criado_em AT TIME ZONE 'America/Sao_Paulo',
    criado_em::date
FROM bronze.pedidos
WHERE _dia_referencia = %(dia)s::date;
```

A parte do Airflow que cuida da silver é este trecho da Dag:

```python
silver = SQLExecuteQueryOperator(
    task_id="silver",
    conn_id=CONN_ID,
    sql="sql/silver_pedidos.sql",
    parameters={"dia": DIA},
    split_statements=True,
)

bronze(DIA) >> silver >> gold >> registrar
```

A tarefa aponta para o arquivo SQL e para o banco. `DIA` é o dia processado, o anterior à data
lógica; datas ganham capítulo próprio adiante. A última linha define a ordem. Nenhuma linha de
Python troca nulo nem ajusta fuso.

O laboratório prova a separação. O mesmo `silver_pedidos.sql` rodou à mão, por um script, e
depois como tarefa da Dag. Para 20 de outubro de 2026, o gold deu a mesma receita paga nas duas
formas: 430,90. Mudou quem manda rodar. O tratamento não mudou.

> Verificação: nível 3. Executado em 2026-10-29, em Linux nativo, com Airflow 3.3.2 (imagem
> `apache/airflow:3.3.2`, o mesmo digest de `apache/airflow:3.3.2-python3.13`, a tag que esta
> apostila fixa; Python 3.13.15) e Postgres 16.15-alpine. À mão:
> `docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20`. Pela Dag:
> `airflow tasks states-for-dag-run loja_idempotente retry_idempotente`, com `silver` em
> `success`, numa execução disparada com data lógica 2026-10-21 09:00 UTC (dia processado
> 20/10), em que a primeira tentativa do bronze tem uma queda simulada de propósito, pelo conf
> `simular_queda`; silver e gold rodaram uma vez, com sucesso. Python aprovado no `ruff check`
> (ruff 0.12.12). Trechos de `dags/sql/silver_pedidos.sql` e `dags/pipeline_loja.py`, do
> laboratório do capítulo 13.

Por isso começar à mão é um caminho válido. O SQL que você valida hoje é o mesmo que o
orquestrador vai rodar quando a entrega virar recorrente.

**O equívoco comum**

Achar que o orquestrador carrega o dado entre os passos. Ele passa referência e estado, não a
tabela. O XCom, canal do Airflow entre tarefas, é para pouco dado; a documentação veta valores
grandes, como tabelas em memória do Python (dataframes). Arquivo no disco local também não serve,
porque a tarefa seguinte provavelmente roda em outro servidor. Dado grande fica num armazenamento
remoto, e segue adiante só o caminho. Na Dag da loja, cada tarefa lê e grava no banco.

##### 3.3 Os vizinhos que não são orquestração

"Pesquisei e apareceram DMS, Debezium e dbt na mesma lista que o Airflow. É tudo a mesma coisa?"

**O que é**

Não. São vizinhos, e cada um responde a uma pergunta diferente.

| Categoria | Exemplo | Pergunta que responde |
|---|---|---|
| Orquestração | Airflow | Quando e em que ordem cada passo roda, e o que aconteceu com ele? |
| Replicação e captura de mudanças (CDC) | AWS DMS, Debezium | Como levar cada mudança da origem para outro lugar, de forma contínua? |
| Organização de SQL | dbt | Como escrever e encadear as transformações em SQL no banco? |

**Como funciona na prática**

Ferramentas de replicação e CDC, como o AWS DMS e o Debezium, leem as mudanças no log de
transações do banco de origem e as levam de forma contínua para outro lugar. O orquestrador não
faz essa cópia. No caso do DMS, o Airflow tem operadores para criar, iniciar, parar e apagar a
tarefa de replicação e um sensor que espera a tarefa terminar; quem copia continua sendo o DMS.

O dbt organiza a transformação em SQL: você escreve consultas `SELECT` e ele cria as tabelas e
visões (views) no banco, na ordem certa entre os modelos. Quando ele roda, quem decide é o
agendamento, na plataforma do próprio dbt ou num orquestrador como o Airflow, em que a execução
do dbt vira um passo do fluxo.

**O equívoco comum**

Achar que, com o dbt, o orquestrador some. O dbt resolve a ordem entre os modelos dele, dentro do
banco. Quem encadeia o dbt com o que está fora dele, como a carga que vem da réplica, é o
orquestrador.

Se orquestrar é rodar na ordem e guardar o que aconteceu, a próxima pergunta é quando você
precisa disso. O capítulo 4 responde em degraus.

#### 4. Os degraus: à mão, agendador, orquestrador

"Preciso de Airflow já, ou posso começar rodando à mão?" A resposta depende do degrau em que a
carga está. São três. Cada um custa mais que o anterior e resolve algo que o anterior não
resolve. Você sobe quando o sinal aparece, não quando a ferramenta aparece numa lista.

##### 4.1 Degrau 1: à mão

"Rodar à mão no começo não é amador?"

**O que é**

Rodar à mão é você disparar o script quando precisa e conferir o resultado na tela.

**Como funciona na prática**

No laboratório da mentoria, um script Python executa em ordem os arquivos SQL de bronze, silver e
gold de um dia, numa transação só. O Python não trata dado: só manda o banco rodar o SQL. Cada
dia levou cerca de 3 segundos, contando a subida do contêiner pelo `docker compose run`, sem
Airflow.

```bash
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20
```

Trecho da saída:

```text
  bronze_pedidos.sql: ok
  silver_pedidos.sql: ok
  gold_vendas_por_dia.sql: ok
  registrar_carga.sql: ok
  resultado: bronze=4 silver=4 receita_paga=430.90
```

Nível 3: executado em ambiente descartável em 2026-10-29, com Docker Engine 28.3.3, Compose
2.39.1, Postgres 16.15, Python 3.13.15 e psycopg 3.3.5, sobre dados sintéticos.

A primeira tentativa falhou: um comentário com ponto e vírgula partiu a instrução no lugar
errado, e nada foi gravado. É para isso que este degrau serve: descobrir o dado, errar perto e
validar o SQL antes de pôr qualquer coisa num horário.

**O equívoco comum**

Achar que começar à mão é erro. O capítulo 2 já contou: o gerente de TI do caso começou assim, e
os mentores concordaram. O custo deste degrau está na pessoa: se ela esquece ou sai de férias, a
carga não roda.

##### 4.2 Degrau 2: agendador

"Se eu agendar o script, já estou orquestrando?"

**O que é**

Agendador é a ferramenta que dispara um comando num horário; ele não resolve dependência entre
passos.

**Como funciona na prática**

O cron é o agendador do Unix. Pela especificação POSIX, o crontab é uma lista de comandos com
horários. A única reação a erro descrita é mandar por e-mail a saída não redirecionada. Não há
dependência entre comandos nem nova tentativa. O livro de SRE do Google resume: o cron
dispara e esquece.

No laboratório, o script do degrau 1 foi para um crontab que roda a cada minuto. Os cinco campos
são minuto, hora, dia do mês, mês e dia da semana.

```text
* * * * * cd /lab && python scripts/pipeline.py --executor cron >> /var/log/pipeline.log 2>&1
```

Nível 3: executado em ambiente descartável em 2026-10-29, com o `crond` do busybox numa imagem
`python:3.13.15-alpine3.24`. O cron fica aqui como explicação, sem laboratório para você.

Depois, derrubamos a réplica. O erro ficou num arquivo dentro do contêiner, nada tentou de novo
antes do minuto seguinte e o registro de carga não ganhou linha. Sem alerta configurado, ninguém
seria avisado. E o relógio do contêiner estava em UTC: um agendamento de 07h ali dispararia às
04h de Brasília. O capítulo 8 volta ao fuso.

Você provavelmente já tem um agendador: o Agendador de Tarefas do Windows (ou o
`schtasks /create /sc` na linha de comando), o SQL Server Agent, o `pg_cron` no Postgres ou a
atualização agendada do Power BI. A tabela da seção 4.4 compara o que cada um entrega. Se o seu
cron mora no WSL, atenção: a distro desliga depois de 15 segundos ociosa e, por inferência que
não testamos, o cron só dispara com ela de pé.

**O equívoco comum**

Achar que agendar é orquestrar. Agendar resolve a hora; não resolve a ordem, o aviso nem o
histórico. O intervalo curto tem armadilha própria: se a execução anterior ainda não terminou, a
próxima já começa, e elas se empilham. E o modelo periódico fica mais frágil à medida que o volume
cresce. O livro de SRE prefere pular a dobrar, porque a execução pulada se recupera e a dobrada
às vezes não. Se você fica no cron, o `flock -n` faz a execução sobreposta falhar em vez de
esperar:

```bash
( flock -n carga.lock sh -c 'echo "1a: rodando"; sleep 3; echo "1a: fim"' ) &
sleep 0.5
flock -n carga.lock sh -c 'echo "2a: rodando"'; echo "2a saiu com $?"
wait
flock -n carga.lock sh -c 'echo "3a: rodando"'; echo "3a saiu com $?"
```

```text
1a: rodando
2a saiu com 1
1a: fim
3a: rodando
3a saiu com 0
```

Nível 3: executado em ambiente descartável em 2026-10-29, com o util-linux 2.39.3. A segunda
execução não começou; a terceira rodou depois que a trava foi liberada.

##### 4.3 Degrau 3: orquestrador

"O que o Airflow faz que o agendador não faz?"

**O que é**

Orquestrador é quem roda o código na ordem certa e guarda o estado; não é o código de limpeza.

**Como funciona na prática**

O salto não é ter horário, porque o cron também tem. É dependência entre passos, estado de cada
execução, nova tentativa, aviso e histórico. A seção 3.1 mostrou o que o Airflow oferece para
isso: o fluxo escrito em Python e uma interface para disparar, ler o log, reprocessar datas
passadas e refazer só as tarefas que falharam.

Nova tentativa e aviso existem, mas é você quem liga. No Airflow 3.3.2, o padrão é zero novas
tentativas, e o aviso de falha vem de uma função de retorno (callback) ou de um notificador
(notifier) que você configura. Os capítulos 6 e 9 mostram os dois.

O preço, medido numa mesma máquina em 2026-10-29: os degraus 1 e 2 couberam na casa de 34 MiB de
memória, já com o banco, e numa imagem de 72,7 MB. O Airflow no modo local (LocalExecutor) subiu
em 1 min 17 s, em quatro contêineres. Ficou na casa de 680 MiB logo depois de subir e de 0,86 GiB
depois dos experimentos, com imagem de 2,33 GB. E ele sempre exige algum código, como a seção 3.1
avisou.

**O equívoco comum**

Achar que o orquestrador melhora o dado. Ele não limpa nulo nem acerta fuso; quem faz isso é o
SQL da silver. Se o SQL de tratamento não está validado, o orquestrador repete o erro no horário,
todo dia.

##### 4.4 Tabela comparativa

| Degrau e ferramenta | Dispara por | Nova tentativa | Aviso de falha | Ordem entre passos | Histórico e reprocesso | Custo e risco |
|---|---|---|---|---|---|---|
| À mão | Você | Você roda de novo | Você vê na tela | A ordem do script | Só o que o script registrar; você roda dia a dia | Quase nada de máquina; depende de alguém lembrar |
| cron | Horário | Não | E-mail com a saída não redirecionada | Não | Só o que o script registrar | Na casa de 5 MiB no laboratório; o erro fica num arquivo que ninguém lê |
| Agendador de Tarefas do Windows | Horário e evento do sistema | Sim, com contagem e intervalo | Aviso nativo não achado na documentação | Não conferido | Sem reprocesso de datas passadas; roda um horário perdido se você ligar a opção, desligada por padrão e só para alguns tipos de gatilho por horário | Já vem no Windows |
| SQL Server Agent | Agenda, alerta ou sob demanda | Não conferido | E-mail via Database Mail | Passos dentro de um trabalho (job) | Não conferido | Vem desligado; não existe no Express |
| `pg_cron` | Horário, dentro do Postgres | Não conferido | Não conferido | Não conferido | Histórico numa tabela do banco; uma instância de cada trabalho por vez | Fuso padrão GMT |
| Atualização agendada do Power BI | Horário: 8 por dia na capacidade compartilhada, 48 em Premium, PPU ou Fabric | Não conferido | E-mail ao dono; agenda desativada após quatro falhas seguidas | Não conferido | Não conferido | Começa em até 15 minutos do horário, pode atrasar até uma hora; banco na sua rede exige gateway |
| Airflow | Horário ou evento | Sim, por tarefa; zero por padrão | Função de retorno ou notificador que você configura | Sim, a Dag é o grafo | Estado e log de cada execução; backfill pela interface | Na casa de 0,86 GiB e imagem de 2,33 GB no laboratório; exige código e alguém que mantenha |

Alguns agendadores, como o SQL Server Agent, encadeiam passos dentro de um mesmo trabalho; o que
continua faltando é dependência entre trabalhos e sistemas e reprocesso de datas passadas.

"Não conferido" quer dizer que a documentação aberta para esta apostila não respondeu, não que o
recurso falte.

##### 4.5 Quando subir de degrau

"Como sei que chegou a hora de automatizar?"

**O que é**

O sinal de subir é o momento em que o degrau atual passa a custar mais que o próximo. Os sinais
abaixo são critério da mentoria; nenhuma fonte primária neutra lista quando automatizar.

**Como funciona na prática**

Vamos ao caso. Um setor quer o número duas vezes por dia; outro, várias vezes por hora. A
atualização agendada do Power BI permite 8 por dia na capacidade compartilhada. Duas por dia
cabem com folga. Várias por hora não cabem, nem no limite de 48 por dia, que dá duas por hora em
média. O segundo setor pede um agendador fora do BI, e os outros sinais decidem entre cron e
orquestrador.

Depois vem a diretoria. Enquanto a entrega é eventual, rodar à mão é razoável. Quando ela vira
diária, ganha a cara do que o livro de SRE chama de trabalho penoso (toil): manual, repetitivo,
automatizável, tático, sem valor duradouro e crescendo junto com o serviço.

Sinais de subir:

- A carga ganhou dia e hora, e alguém cobra quando ela não chega.
- Há passos que dependem uns dos outros: réplica, bronze, silver, gold e registro de carga.
- Alguém precisa saber quando falhou, e a falha pede nova tentativa.
- Você precisa refazer dias passados depois de corrigir o SQL.
- A frequência passou do que a ferramenta atual aguenta.

Sinais de que ainda não é hora:

- O SQL de tratamento ainda não está validado.
- Você ainda está descobrindo de onde vem cada número.
- A entrega ainda é eventual.

**O equívoco comum**

Subir por catálogo, não por sinal. O mesmo livro avisa que não convém automatizar todo componente
de todo sistema e que automação sem critério cria tantos problemas quanto resolve. Suba um degrau
por vez e leve junto o que aprendeu à mão.

Quando o sinal aparecer, você vai precisar das palavras do orquestrador. O capítulo 5 dá o
vocabulário mínimo.

#### 5. Vocabulário mínimo: Dag, tarefa, dependência, execução e estado

Antes do código, o desenho. Este capítulo dá as palavras do desenho e mostra o que o orquestrador guarda de cada execução, com o Airflow 3.3.2 como exemplo.

##### 5.1 Dag, o fluxo como grafo

"Todo mundo fala em Dag. O que é isso?"

**O que é**

Dag é um grafo dirigido sem ciclo de tarefas. No Airflow, é a definição do fluxo.

Dirigido: cada seta tem sentido. Sem ciclo: nenhum caminho volta ao ponto de partida. A documentação do Airflow escreve "Dag", e não "DAG", porque ali o termo foi além da estrutura matemática.

**Como funciona na prática**

Vamos desenhar o fluxo da loja no papel:

```text
réplica só leitura   (origem: o bronze lê dela, não é tarefa)
        |
        v
     bronze --> silver --> gold --> registrar_carga --> checar_repeticao
```

Este é o desenho alvo. No laboratório ele está dividido em duas Dags: uma faz bronze, silver, gold e o registro; a outra registra a carga e checa a repetição.

Cada nome é uma tarefa. Cada seta é uma dependência.

**O equívoco comum**

Achar que a Dag faz o trabalho. Ela só diz a ordem. Quem limpa nulo e ajusta fuso é o SQL de cada camada.

##### 5.2 Tarefa, operador e sensor

"Cada nome do desenho vira o quê no código?"

**O que é**

Tarefa (task) é um passo da Dag, criado a partir de um operador. Operador é um modelo de tarefa, como o que executa SQL num banco.

**Como funciona na prática**

Chamar um operador dentro da Dag cria uma tarefa. Na Dag do fluxo da loja (pipeline_loja), silver, gold e registrar_carga usam o `SQLExecuteQueryOperator`; o bronze é uma função Python com `@task`, que também vira tarefa.

Sensor é um operador que só espera uma condição externa. Se a réplica atrasar, um sensor antes do bronze espera por ela. O laboratório não usa sensor.

**O equívoco comum**

Achar que a tarefa precisa tratar o dado em Python. Aqui o Python só manda rodar. O tratamento é SQL, dentro do banco.

##### 5.3 Dependência e disparo

"Como o orquestrador sabe a ordem? E o que faz o fluxo começar?"

**O que é**

Dependência é a aresta do grafo: uma tarefa só começa depois das anteriores.

**Como funciona na prática**

Por padrão, uma tarefa espera todas as anteriores terminarem com sucesso. No código, a seta do desenho vira `>>`:

```python
bronze(DIA) >> silver >> gold >> registrar
```

Nível 3: Airflow 3.3.2, Linux, 2026-10-29; `airflow tasks states-for-dag-run` mostrou as quatro tarefas em `success`, na ordem. `DIA` é o dia processado (capítulo 7).

Passar o resultado de uma tarefa para outra também cria a dependência. Numa Dag menor do laboratório, registro_de_carga, é assim que checar_repeticao espera registrar_carga:

```python
linhas = registrar_carga()
criar_tabelas >> carregar_pedidos_tratados >> linhas
checar_repeticao(linhas)
```

Nível 3, mesma versão e data: três execuções, uma agendada e duas com `airflow dags trigger registro_de_carga`, gravaram 5, 7 e 7 linhas; a terceira falhou em checar_repeticao, como esperado.

A execução nasce, no dia a dia, de três jeitos. Disparo por horário: a agenda cria a execução; no laboratório, `0 6 * * *`, todo dia às 6h de Brasília, porque a data de início da Dag declara esse fuso; sem fuso declarado, o Airflow usa UTC (capítulo 8). Disparo por evento: a Dag roda quando uma tarefa atualiza um dado (asset) e termina com sucesso. E disparo à mão. O reprocessamento de datas passadas e o catchup também criam execuções; ficam para o capítulo 7.

**O equívoco comum**

Achar que horário resolve ordem. Agendar a gold meia hora depois do bronze não é dependência. Se o bronze atrasar, a gold roda com dado velho.

##### 5.4 Execução e estado

"O que o orquestrador guarda cada vez que o fluxo roda?"

**O que é**

Execução da Dag (Dag run) é uma instância da Dag no tempo, com estado próprio. Dentro dela, cada tarefa vira uma instância de tarefa, também com estado.

**Como funciona na prática**

O caminho ideal de uma tarefa e os estados que você mais vai ver fora dele:

| Caminho ideal | Fora do caminho ideal |
|---|---|
| `none`, `scheduled`, `queued`, `running`, `success` | `failed`, `up_for_retry`, `upstream_failed` |

A execução herda o estado das tarefas finais, as que não têm seguinte; o capítulo 9 mostra a armadilha que isso esconde. O Airflow guarda ainda o tipo da execução, agendada ou manual, e um log por tentativa.

**Como inspecionar**

```bash
airflow tasks states-for-dag-run registro_de_carga <run_id>
```

Saída observada na execução que repetiu a contagem (trecho, sem as colunas de data):

```text
task_id                   | state
==========================+========
criar_tabelas             | success
carregar_pedidos_tratados | success
registrar_carga           | success
checar_repeticao          | failed
```

Nível 3: Airflow 3.3.2, Linux, 2026-10-29, via `docker compose exec airflow-scheduler`.

**O equívoco comum**

Achar que `success` quer dizer dado certo. Quer dizer que a tarefa terminou sem erro. No laboratório, simulamos uma queda logo depois de o bronze gravar. A Dag do laboratório liga uma nova tentativa (`retries=1`); sem isso, o Airflow 3 não tenta de novo. A nova tentativa gravou o dia de novo (dois logs, `attempt=1.log` e `attempt=2.log`), e tudo terminou em `success`, com cada pedido duas vezes no bronze. A queda foi simulada; a duplicação, real. Capítulos 6 e 9.

##### 5.5 As peças do Airflow 3: quem lê, quem decide, onde fica

"Salvei o arquivo da Dag. Por que ela não aparece?"

**O que é**

O Airflow 3 é feito de peças separadas, cada uma com um papel.

**Como funciona na prática**

- **Dag processor**: lê os arquivos das Dags. No Airflow 3, roda à parte, até no ambiente local.
- **Scheduler**: decide o que roda e quando. O executor é configuração dele; o padrão, `LocalExecutor`, roda até 32 tarefas (`parallelism`) como subprocessos do scheduler. Em contêiner, ajuste o `parallelism` ao limite de memória; o laboratório usa 4.
- **API server**: substitui o webserver do Airflow 2.
- **Banco de metadados**: guarda execuções, estados e histórico.

O Dag processor procura arquivo novo a cada 300 segundos, por padrão: Dag nova pode levar até cinco minutos para aparecer. Arquivo conhecido é relido a cada 30 segundos. O laboratório baixa a busca para 30.

Entre tarefas passa pouco dado, pelo XCom, como a seção 3.2 mostrou; no laboratório, só a contagem de linhas. No Airflow 3, o XCom é limpo a cada nova tentativa.

Três padrões mudaram no Airflow 3: sem agenda, a Dag só roda à mão, porque o padrão de `schedule` é `None`; toda Dag nasce pausada; e o catchup, que cria sozinho as execuções perdidas, vem desligado. No laboratório, as Dags nasceram com `is_paused` em `True`. Nível 3: Airflow 3.3.2, Linux, 2026-10-29, com `airflow dags list` via `docker compose exec airflow-scheduler`.

**O equívoco comum**

Material do Airflow 2 diz que o scheduler lê os arquivos. No 3, quem lê é o Dag processor, e ele é obrigatório. Se a Dag não aparece, confira se ele está de pé, espere a próxima busca e rode `airflow dags list-import-errors`; no laboratório, `No data found` quis dizer nenhum arquivo com erro. Nível 3: Airflow 3.3.2, Linux, 2026-10-29, com `airflow dags list-import-errors` via `docker compose exec airflow-scheduler`.

Com o vocabulário na mão, vamos ao custo que vem junto: o orquestrador roda as coisas de novo. É o capítulo 6.

#### 6. Nova tentativa e idempotência: o preço do orquestrador

"Rodei a carga de ontem de novo, só para garantir. O painel dobrou. Nada deu erro. O que aconteceu?"

O orquestrador traz três jeitos de rodar o mesmo dia outra vez. A nova tentativa de uma tarefa que falhou. O reprocessamento de datas passadas. E a limpeza (clear) de uma tarefa, para ela rodar de novo. À mão, você faz o mesmo quando esquece que já rodou.

Esse é o preço do orquestrador. Antes de ligar qualquer um desses recursos, a carga precisa aguentar rodar de novo.

##### 6.1 Idempotência

"Idempotência parece palavra de engenheiro. Por que eu preciso dela?"

**O que é**

Idempotência: rodar de novo dá o mesmo resultado de rodar uma vez.

A definição que usamos parte da RFC 9110, a especificação do HTTP: um método é idempotente quando várias requisições idênticas têm o mesmo efeito de uma só. A RFC também diz que o cliente não deve repetir sozinho uma requisição que não é idempotente. Ela trata de HTTP, não de dados; levar a definição para uma carga é extrapolação nossa, didática. A lógica vale igual: só repita sozinho o que aguenta ser repetido.

**Como funciona no Airflow**

A página de boas práticas do Airflow 3.3.2 transforma isso em regra para cada tarefa:

- Trate a tarefa como uma transação de banco, sem resultado pela metade.
- Ela deve dar o mesmo resultado a cada reexecução, porque o Airflow pode tentar de novo.
- Não use INSERT numa reexecução, porque pode duplicar linha. Troque por UPSERT, que insere ou atualiza pela chave, numa operação só.
- Leia e grave numa partição específica; a documentação sugere `data_interval_start` como partição. Atenção: no Airflow 3, com a agenda em cron padrão, a janela tem duração zero e esse valor é o próprio momento do disparo; o capítulo 7 mostra como escolher o dia certo, e o laboratório usa a data lógica menos um dia. Nunca leia "o dado mais recente disponível".
- Não use `now()` em cálculo crítico.

**O equívoco comum**

Achar que idempotência é assunto só de engenheiro sênior. Ela é a primeira coisa a conferir em qualquer carga que alguém, ou algo, pode rodar duas vezes.

##### 6.2 O que provamos: o mesmo dia, duas vezes

"Se eu rodar o dia 20 de novo, o que muda?" Vamos ver por que duplicou.

**Como funciona na prática**

No laboratório da rede de lojas, a carga de um dia lê a réplica, grava o bronze e refaz silver e gold. Testamos duas versões do bronze. A ingênua só insere. A idempotente apaga o dia e insere de novo, na mesma transação. O `%(dia)s` é o dia que o script passa.

```sql
-- Naive load: every rerun of the same day appends the same rows again.
INSERT INTO bronze.pedidos
    (id, cliente, valor, valor_texto, status, criado_em, atualizado_em, _dia_referencia)
SELECT id, cliente, valor, valor_texto, status, criado_em, atualizado_em, %(dia)s::date
FROM replica.pedidos
WHERE criado_em >= %(dia)s::date
  AND criado_em < %(dia)s::date + 1;
```

```sql
-- Idempotent load: replace the whole day, the caller commits both statements together.
DELETE FROM bronze.pedidos
WHERE _dia_referencia = %(dia)s::date;

INSERT INTO bronze.pedidos
    (id, cliente, valor, valor_texto, status, criado_em, atualizado_em, _dia_referencia)
SELECT id, cliente, valor, valor_texto, status, criado_em, atualizado_em, %(dia)s::date
FROM replica.pedidos
WHERE criado_em >= %(dia)s::date
  AND criado_em < %(dia)s::date + 1;
```

Nível 3: executado em ambiente descartável em 2026-10-29, com
`docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20` e o mesmo comando
com `--modo ingenuo`; PostgreSQL 16.15, Python 3.13.15, psycopg 3.3.5. Dados sintéticos.

Carregamos o dia 20 com a versão que apaga e regrava: 4 linhas, 430,90. Rodar de novo deu o mesmo. Depois, sobre esse dia já carregado, rodamos a versão ingênua duas vezes: 8 linhas e 861,80, depois 12 linhas e 1.292,70. Por fim, voltamos à versão que apaga e regrava.

| Ordem | Versão | Linhas no bronze | Receita do dia |
|---|---|---|---|
| 1 | Apaga e regrava o dia | 4 | 430,90 |
| 2 | Apaga e regrava o dia | 4 | 430,90 |
| 3 | Ingênua (só INSERT) | 8 | 861,80 |
| 4 | Ingênua (só INSERT) | 12 | 1.292,70 |
| 5 | Apaga e regrava o dia | 4 | 430,90 |

Todas as execuções terminaram com sucesso. Nenhum erro, nenhum aviso.

A quinta execução rodou sobre o dia triplicado e voltou a 4 linhas e 430,90. Apagar e regravar também conserta o dia duplicado.

**O equívoco comum**

Silver e gold já apagavam e regravavam o dia. Mesmo assim, dobraram, porque refizeram o dia a partir de um bronze duplicado. A idempotência começa no primeiro passo que grava.

##### 6.3 Quatro jeitos de gravar, um que duplica calado

"Eu ponho chave primária e pronto?"

**Como funciona na prática**

Gravamos a mesma carga do dia 21 duas vezes, em três tabelas de rascunho, e comparamos com a versão que apaga e regrava o dia.

| Jeito de gravar | Segunda carga do mesmo dia | Sinal | Serve para |
|---|---|---|---|
| INSERT sem chave | Duplica: 3 linhas viram 6 | Nenhum, termina com sucesso | Nada que possa rodar de novo |
| INSERT com chave primária | Falha com `duplicate key value violates unique constraint` | Alto, a carga para | Barrar a duplicação; não roda de novo sozinha |
| UPSERT (`ON CONFLICT DO UPDATE`) | Fica igual: 3 linhas | Nenhum, resultado igual | Linhas com chave estável, como o número do pedido |
| Apagar e regravar o dia | Fica igual e conserta o dia duplicado | Nenhum, resultado igual | Carga por dia ou por partição |

No PostgreSQL, `ON CONFLICT DO UPDATE` garante um resultado atômico, INSERT ou UPDATE, mesmo com concorrência, desde que não haja um erro independente. É o que se chama UPSERT.

```sql
INSERT INTO com_upsert SELECT id, valor FROM replica.pedidos WHERE criado_em::date = '2026-10-21'
    ON CONFLICT (id) DO UPDATE SET valor = EXCLUDED.valor;
```

Nível 3: executado em ambiente descartável em 2026-10-29, duas vezes seguidas, com
`psql -U dw -d dw -f -` contra PostgreSQL 16.15. Na tabela com chave primária e INSERT puro, a segunda carga respondeu:

```text
psql:<stdin>:11: ERROR:  duplicate key value violates unique constraint "com_chave_pkey"
DETAIL:  Key (id)=(105) already exists.
```

Esses jeitos têm nome na literatura. No repositório de código do livro *Data Engineering Design
Patterns*, de Bartosz Konieczny, o capítulo de idempotência reúne padrões que aqui chamamos de
sobrescrita (Fast Metadata Cleaner, Data Overwrite), de merge (Merger, Stateful Merger) e de
idempotência por chave (Keyed Idempotency), entre outros.

**O equívoco comum**

Achar que a chave primária resolve. Ela troca a duplicação calada por uma falha alta, o que é melhor que dobrar. Mas a mesma carga, rodada de novo, bate na mesma chave e falha outra vez.

##### 6.4 Nova tentativa: ligar depois, com teto

"Por que não ligo cinco tentativas em tudo e esqueço?"

**O que é**

Nova tentativa (retry): rodar de novo uma tarefa que falhou. No Airflow 3, desligada por padrão.

**Como funciona no Airflow**

Sem configuração, o Airflow 3.3.2 não tenta de novo: `default_task_retries` vale 0. Também não há tempo limite: com `default_task_execution_timeout` vazio, a tarefa nunca é interrompida por demora. Você liga as tentativas na Dag ou na tarefa. No laboratório, ligamos uma, com 10 segundos de espera:

```python
@dag(
    dag_id=dag_id,
    schedule="0 6 * * *",
    start_date=pendulum.datetime(2026, 10, 15, tz="America/Sao_Paulo"),
    catchup=False,
    max_active_runs=1,
    default_args={"retries": 1, "retry_delay": pendulum.duration(seconds=10)},
    tags=["mentoria", "laboratorio"],
)
```

Nível 3: passou em `ruff check --select E,F,W,I,B,UP` (ruff 0.12.12) e foi executado em ambiente
descartável em 2026-10-29, no Airflow 3.3.2 (imagem `apache/airflow:3.3.2`, o mesmo digest de `apache/airflow:3.3.2-python3.13`, com Python 3.13.15), com
`airflow dags trigger loja_ingenua -l 2026-10-21T09:00:00+00:00 -r retry_ingenuo -c '{"simular_queda": true}' -o plain`
dentro do contêiner do scheduler, e o equivalente para `loja_idempotente`.

Depois provocamos uma queda. Atenção: a falha é simulada. Na primeira tentativa, a tarefa do bronze grava, confirma e levanta um erro, como um processo que cai logo depois de gravar.

- Na versão ingênua, a segunda tentativa grava o dia outra vez. A execução termina com sucesso. O gold dobra: 8 pedidos e 861,80.
- Na versão idempotente, a segunda tentativa apaga as 4 linhas da primeira e regrava 4. O gold fica em 4 pedidos e 430,90.

**Espera crescente e teto**

Nova tentativa resolve falha passageira. A AWS chama as novas tentativas de egoístas: cada uma gasta mais tempo do servidor e pode piorar uma sobrecarga. A recomendação é backoff exponencial (esperar cada vez mais entre uma tentativa e outra), com teto, com jitter (um sorteio na espera, para as tentativas não chegarem juntas) e com limite de tentativas. E, para a AWS, uma chamada com efeito colateral só é segura de repetir se for idempotente; uma carga que grava dado é exatamente esse caso.

Não verificado: se o Airflow 3.3.2 sorteia a espera; não conferimos isso na documentação.

**Erro que tentar de novo não resolve**

Uma chave de API inválida continua inválida na quinta tentativa. Esse erro deve falhar direto, com `AirflowFailException`, que marca a tarefa como falha e ignora as tentativas restantes. Desde a versão 3.3.0, as políticas de nova tentativa (Retry Policies) decidem por tipo de erro entre tentar de novo, falhar já ou seguir a regra padrão. Podem falhar antes; nunca passam do máximo configurado.

**O equívoco comum**

Tratar nova tentativa como conserto. Numa carga que não é idempotente, ela troca uma falha visível por um número dobrado e verde.

##### 6.5 Pular é melhor que dobrar

"E se eu não souber se a carga de ontem rodou?"

**O que é**

O livro *Site Reliability Engineering*, do Google, separa as rotinas agendadas em dois eixos. Algumas rodam duas vezes sem dano, como a coleta de lixo; outras não, como o envio de um boletim por e-mail. Algumas podem pular uma execução; outras não, como a folha de pagamento. Entre pular e dobrar, o Google prefere pular: a execução pulada se recupera, a dobrada às vezes não. E o dono deve acompanhar o efeito da rotina por conta própria.

**Como funciona na prática**

Na rede de lojas, o efeito é a receita do dia. O status verde não mostrou a duplicação em nenhum caminho testado na versão ingênua:

- nova tentativa: 430,90 virou 861,80;
- reprocessamento de três dias, rodado duas vezes: os três dias dobraram;
- limpeza da tarefa do bronze e das seguintes, num dia já carregado: 111,90 virou 223,80.

Na versão idempotente, a nova tentativa e o reprocessamento não mudaram o número; a limpeza foi testada só na ingênua. O capítulo 7 detalha o reprocessamento, e o 9 mostra como o registro de carga acompanha o efeito.

**Como inspecionar antes de ligar**

1. Rode o mesmo dia duas vezes, à mão.
2. Compare contagem de linhas e soma depois de cada uma. Precisam ser iguais.
3. Confira se cada passo que grava apaga e regrava a sua partição ou usa UPSERT pela chave.
4. Procure `now()` e "o mais recente" no SQL que calcula número.
5. Só então ligue as tentativas, com teto e espera crescente.

Começar à mão continua valendo. É à mão que você vê o número dobrar pela primeira vez, sem diretoria olhando.

**O equívoco comum**

Achar que o status verde prova que o dado está certo. Ele prova que o código terminou.

Se rodar de novo é seguro, falta saber qual dia cada execução processa. É o capítulo 7.

#### 7. Tempo: agendamento, data lógica, reprocesso e catchup

"Corrigi o SQL da silver. Como refaço a semana passada para a diretoria?"

Antes de apertar qualquer botão, responda duas perguntas. Qual dia cada execução processa? E o que acontece se um dia rodar duas vezes? A segunda o capítulo 6 já respondeu: só reprocesse a versão que apaga e regrava o dia. Este capítulo responde a primeira.

Tudo aqui foi conferido no Airflow 3.3.2. Onde a documentação e o comportamento divergem, seguimos o que rodou.

##### 7.1 A agenda vira uma regra: o timetable

"Escrevi `@daily`. Que dia essa execução carrega?"

**O que é**

Timetable é a regra que transforma a agenda em execuções e janelas de dados. Janela de dados é o intervalo de tempo que uma execução deve processar.

**Como funciona no Airflow**

No Airflow 3, a configuração `create_cron_data_intervals` vem desligada. Assim, `"0 0 * * *"`, `"@daily"` e `"@hourly"` viram `CronTriggerTimetable`, e `timedelta(days=1)` vira `DeltaTriggerTimetable`. Sem `interval=`, o `CronTriggerTimetable` não tem janela: data lógica, início e fim da janela recebem o mesmo instante, o do disparo. A janela tem duração zero.

Para a janela cobrir o dia anterior, declare `interval=`. A data lógica passa a ser o início da janela, o disparo menos um dia.

Dags diárias iguais, que só mudam a agenda, receberam isto no disparo de 29/10 às 00:00 UTC (21h do dia 28 em Brasília):

| Agenda | Timetable | Janela de dados | `ds` | Linhas lidas da janela |
|---|---|---|---|---|
| `"0 0 * * *"` ou `"@daily"` | `CronTriggerTimetable` | duração zero, no disparo | 2026-10-29 | 0 |
| `CronTriggerTimetable("0 0 * * *", timezone="UTC", interval=timedelta(days=1))` | o mesmo, com intervalo | 28/10 00:00 a 29/10 00:00 UTC | 2026-10-28 | 3 |
| `CronDataIntervalTimetable("0 0 * * *", timezone="UTC")`, o padrão do Airflow 2 | intervalo clássico | 28/10 00:00 a 29/10 00:00 UTC | 2026-10-28 | 3 |

Das três linhas lidas, duas são do dia 27 em Brasília. Isso é fuso, assunto do capítulo 8.

Se você migra do Airflow 2 Dags que dependem de `data_interval_start` e `data_interval_end`, decida antes do upgrade. O guia oficial dá dois caminhos: ligar `create_cron_data_intervals=True` antes do upgrade, para manter o timetable antigo, ou declarar `interval=` no `CronTriggerTimetable`. Mudar essa configuração depois que já existem execuções no Airflow 3 pula uma execução agendada.

**O equívoco comum**

Achar que a receita oficial já resolve. As boas práticas do Airflow mandam gravar numa partição específica e sugerem `data_interval_start` como partição. No padrão do Airflow 3, essa partição é o dia do disparo, não o dia anterior. E se a tarefa lê a janela do início ao fim, como fizemos no laboratório, lê zero linhas.

Cuidado também com duas páginas da documentação. A de execuções da Dag e o FAQ ainda explicam datas pelo modelo de intervalo do Airflow 2, e a primeira manda disparar com `-e`; na 3.3.2, a opção é `-l/--logical-date`, sem padrão. Para o Airflow 3, use a página de timetables, o guia de upgrade e a referência de configuração. Mesmo esta última pede atenção: diz que, no `CronTriggerTimetable`, a data lógica é o momento do disparo, e isso só vale sem `interval=`.

**Como inspecionar**

No laboratório (capítulo 13, Lab 5), seis Dags iguais, que só mudam a agenda, imprimem as datas no log. Trecho da saída real:

```text
## datas_cron_puro | scheduled__2026-10-29T00:00:00+00:00 | mostrar_datas
DATAS logical_date=2026-10-29T00:00:00+00:00 (Brasilia 28/10 21:00)
DATAS data_interval_start=2026-10-29T00:00:00+00:00 (Brasilia 28/10 21:00)
DATAS data_interval_end=2026-10-29T00:00:00+00:00 (Brasilia 28/10 21:00)
DATAS ds=2026-10-29
## datas_trigger_intervalo | scheduled__2026-10-29T00:00:00+00:00 | mostrar_datas
DATAS logical_date=2026-10-28T00:00:00+00:00 (Brasilia 27/10 21:00)
DATAS data_interval_start=2026-10-28T00:00:00+00:00 (Brasilia 27/10 21:00)
DATAS data_interval_end=2026-10-29T00:00:00+00:00 (Brasilia 28/10 21:00)
DATAS ds=2026-10-28
```

##### 7.2 Disparo manual: a data pedida não é a janela

"E se eu disparar à mão, pedindo o dia 20?"

**O que é**

Data lógica é a data a que uma execução se refere. Nem sempre é o momento em que ela roda. No disparo manual, nem sempre bate com a janela.

**Como funciona no Airflow**

O resultado depende do caminho.

| Caminho | Data lógica | Janela de dados |
|---|---|---|
| CLI sem `-l`, ou API com `"logical_date": null` | vazia | vazia; `{{ ds }}` falha com `UndefinedError` |
| CLI com `-l 2026-10-20T00:00:00+00:00` | a pedida; `ds=2026-10-20` | ancorada no momento do disparo, hoje |
| API REST com data lógica | a pedida | inferida a partir da data lógica, terminando nela |
| Botão Acionar da interface | o instante atual, no fuso do navegador | "Inferido da Data Lógica e do Timetable" ou "Especificar Manualmente" |

Pela interface, o `ds` sai da data em UTC. Um disparo entre 21h e 24h de Brasília recebe o dia seguinte.

**O equívoco comum**

Achar que disparar com `-l` refaz aquele dia. Pela CLI, o pedido de 20/10 numa Dag de cron puro gravou a partição de 29/10, o dia do disparo, porque a tarefa usava `data_interval_start`. Com `interval=`, gravou 28/10. Pela API, muda de novo. No cron puro, gravou a partição pedida, lendo janela vazia. Com janela de um dia, gravou o dia anterior ao pedido.

Se a sua lógica precisa da data pedida, leia `logical_date` explicitamente. Para refazer dias, o caminho coerente é o reprocesso.

##### 7.3 Reprocessar a semana: ensaio, limites e a versão certa

"Corrigi a silver. Como refaço os dias?"

**O que é**

Reprocessamento de datas passadas (backfill) é criar execuções para dias que já passaram. Só faz sentido em Dag com agenda por tempo. Roda pela interface, pela CLI e pela API.

**Como funciona no Airflow**

A primeira escolha é o que fazer com o dia que já tem execução:

| `--reprocess-behavior` | Na interface | Dia que já tem execução |
|---|---|---|
| `none`, o padrão | Missing Runs | pula, qualquer que seja o estado |
| `failed` | Missing and Errored Runs | refaz se falhou |
| `completed` | All Runs | refaz se terminou, com sucesso ou falha |

Em qualquer opção, se a última execução do dia ainda está rodando ou na fila, o reprocesso não cria outra.

No caso da silver corrigida, os dias já rodaram com sucesso. Com `none`, o reprocesso pula todos, inclusive um dia com execução manual criada com `-l`. Você precisa de `completed`.

Os limites têm duas pegadinhas. `--from-date` e `--to-date` sem hora viram 00:00 no fuso padrão da instalação (UTC, se ninguém mudou), qualquer que seja o fuso da Dag. E o fim é inclusivo, mas, no `CronTriggerTimetable`, o filtro olha o momento do disparo, não a data lógica.

Vamos ver na Dag da loja. Ela dispara às 06h de Brasília, 09h em UTC, e carrega o dia anterior ao disparo, com `{{ macros.ds_add(ds, -1) }}`. Primeiro, o ensaio:

```bash
# Dry run: prints the logical dates the backfill would create, writes nothing
airflow backfill create --dag-id loja_ingenua \
  --from-date 2026-10-21 --to-date 2026-10-23 --dry-run
```

Trecho da saída real:

```text
    - from_date = 2026-10-21 00:00:00+00:00
    - to_date = 2026-10-23 00:00:00+00:00
| 2026-10-22 09:00:00+00:00 |                 |                  |
```

Pedimos três dias e veio um. O disparo de 21/10 já tinha uma execução manual, e o `none` pulou. O de 23/10 às 09h UTC passou do fim, 00:00 UTC. O ensaio pegou os dois erros sem gravar nada. Ele rodou na Dag ingênua; a idempotente tem a mesma agenda.

Agora o reprocesso de verdade, na versão que apaga e regrava o dia, com hora explícita no fim:

```bash
# Real backfill: explicit end time, reprocess days that already ran
airflow backfill create --dag-id loja_idempotente \
  --from-date 2026-10-21 --to-date 2026-10-23T23:59:59+00:00 \
  --reprocess-behavior completed
```

Saíram três execuções, com datas lógicas 21, 22 e 23. Cada uma carrega o dia anterior, então a gold refez os dias 20, 21 e 22. Rodamos o mesmo comando duas vezes, e a gold ficou assim nas duas:

```text
    dia     | pedidos | pedidos_pagos | receita_paga
------------+---------+---------------+--------------
 2026-10-20 |       4 |             2 |       430.90
 2026-10-21 |       3 |             2 |       111.90
 2026-10-22 |       3 |             3 |       293.30
```

Na versão ingênua, o segundo reprocesso dobrou os três dias. É o que o capítulo 6 mostrou.

Mais três regras:

- **Execuções simultâneas.** O reprocesso tem `max_active_runs` próprio, aplicado à parte do limite da Dag. No laboratório, com `max_active_runs=1` na Dag, as três execuções começaram juntas, e o reprocesso ficou registrado com limite 10. Passe `--max-active-runs` para poupar a réplica. Que isso alivia a origem é inferência nossa, não medida.
- **Um por vez.** Só existe um reprocesso aberto por Dag. Um segundo comando, logo depois de as execuções terminarem, foi recusado com `AlreadyRunningBackfill` até o Airflow fechar o primeiro.
- **O timetable muda as datas.** De 23 a 25, cron puro e intervalo clássico criaram datas lógicas 23, 24 e 25. Com `interval=` de um dia, saíram 22, 23 e 24. Numa Dag à meia-noite de Brasília com `interval=`, o mesmo pedido processou só os dias 22 e 23, porque os limites são 00:00 UTC e o disparo local é 03:00 UTC.

**O equívoco comum**

Reprocessar sem ensaio, com data sem hora. O comando termina com sucesso, e a semana sai com um dia a menos. E, se a carga não for idempotente, com os dias reprocessados em dobro.

##### 7.4 Catchup, pausa e limpar tarefa

"Se eu pausar a Dag no feriado, os dias voltam sozinhos?"

**O que é**

Catchup é criar sozinho as execuções perdidas desde a data de início. No Airflow 3, vem desligado.

**Como funciona no Airflow**

Os padrões do Airflow 3 mudaram. Sem `schedule`, a Dag só roda à mão. Toda Dag nasce pausada. E o catchup vem desligado.

Com `catchup=True`, despausar dispara as execuções perdidas. Com o padrão, os dias do período pausado são pulados e só voltam por reprocesso explícito. No laboratório, uma Dag nova com `"0 7,13 * * *"`, início em 1º de outubro no fuso de Brasília e catchup desligado, criou ao despausar uma execução só: a mais recente, das 07h de Brasília, 10h em UTC.

Limpar (clear) uma tarefa, pela interface ou por `airflow tasks clear`, devolve o estado a vazio e a faz rodar outra vez. Mas confira qual código roda. Com Dags vindas de um pacote de Dags versionado (Dag bundle), como Git, limpar reexecuta por padrão a versão original, não a correção recém-publicada. O reprocesso usa a mais recente. Pacotes locais, S3 e GCS não versionam e rodam sempre o código mais recente.

**O equívoco comum**

Ligar o catchup para refazer dias. Ele só cria o que falta e não refaz o que já rodou. Para a silver corrigida, o caminho é o reprocesso com `completed`. E limpar a tarefa num pacote Git, sem escolher a versão mais recente, roda o código antigo; se o SQL mora no mesmo repositório, roda o SQL antigo também.

##### 7.5 Antes de refazer a semana

1. Confirme que a carga apaga e regrava o dia.
2. Descubra o timetable e qual dia cada data lógica carrega.
3. Rode o ensaio com `--dry-run` e confira cada data.
4. Ponha hora explícita no `--to-date`.
5. Use `--reprocess-behavior completed` para refazer o que já rodou.
6. Limite as execuções simultâneas.
7. Confira a gold e o registro de carga depois.

Se a entrega ainda é à mão, o raciocínio é o mesmo. O script do laboratório recebe o dia em `--dia`, e você escolhe cada dia de propósito.

**Verificação do código deste capítulo**

- Dag `datas_por_timetable.py` (seis agendas): nível 3. Executada em 2026-10-29, em ambiente descartável, com a imagem `apache/airflow:3.3.2` (Python 3.13), num contêiner `standalone`. Comandos que provaram: `airflow dags unpause`, `airflow dags trigger` com e sem `-l`, disparo pela API REST, botão Acionar da interface e `airflow backfill create` com e sem `--dry-run`, com leitura dos logs das tarefas. Nível 2 da mesma Dag: `ruff check --select AIR,E,F,W,I --preview dags/` e `ruff format --check dags/`, ruff 0.12.12, sem erro.
- Dags `loja_ingenua` e `loja_idempotente` (`pipeline_loja.py`): nível 3. Executadas em 2026-10-29 com a imagem `apache/airflow:3.3.2` (Python 3.13) e Postgres `16.15-alpine`. Os dois comandos de reprocesso acima rodaram com `docker compose --profile airflow exec -T airflow-scheduler` na frente; as saídas são trechos. Nível 2: `ruff check --select E,F,W,I,B,UP --line-length 120` e `ruff format --check --line-length 120`, ruff 0.12.12, sem erro.
- Script `pipeline.py` (degrau à mão, argumento `--dia`): nível 3, executado em 2026-10-29 com Postgres 16.15-alpine; nível 2 com o mesmo ruff 0.12.12.
- Dag `registro_de_carga` (despausar com catchup desligado): nível 3, executada em 2026-10-29 com a imagem apache/airflow:3.3.2.
- Dados de pedidos e visitas: sintéticos.

As datas deste capítulo estão em UTC. O capítulo 8 mostra por que isso importa para uma loja em Brasília.

#### 8. Fuso horário: o dia de quem?

"Por que aparece atendimento à meia-noite se a loja fecha às 22h?"

Ninguém atendeu à meia-noite. O atendimento foi às 21h em Brasília, e o sistema gravou o horário em UTC. O dado não está errado. Está em outro fuso.

Na orquestração, o fuso decide duas coisas: a que horas a carga roda e em que dia cada registro cai. Vamos ver as duas.

##### 8.1 UTC por padrão

"Por que o Airflow não usa o horário de Brasília?"

**O que é**

UTC é o tempo universal coordenado. Em 2026, Brasília fica três horas atrás dele o ano inteiro. O Brasil não tem horário de verão desde 2019, e a imagem do Airflow 3.3.2 calcula -03:00 para `America/Sao_Paulo` em janeiro e em outubro.

**Como funciona no Airflow**

O Airflow guarda datas em UTC, por dentro e no banco de metadados. O fuso padrão, `default_timezone`, vem como `utc`, e a documentação recomenda deixar assim.

**O equívoco comum**

Achar que, operando só no Brasil, dá para guardar tudo no horário de Brasília. A documentação diz que, mesmo num fuso só, é boa prática guardar o dado em UTC no seu banco, por causa das transições de horário de verão. Guarde em UTC e converta para Brasília só na hora de dizer a que dia o registro pertence.

##### 8.2 Agendar: meia-noite de quem?

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

##### 8.3 Gravar: o dia de quem?

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

##### 8.4 A tela também tem fuso

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

#### 9. Saber que falhou: registro de carga, alerta e falha silenciosa

"Como eu sei se a carga falhou?"

Essa pergunta veio do gerente de TI que montava a primeira arquitetura de dados. Na sessão, saiu uma ideia: registrar cada carga e alertar quando a contagem de linhas repete a do ciclo anterior.

Uma carga falha de dois jeitos. Quebrando, ou terminando verde.

##### 9.1 Duas formas de falhar

"Se a tarefa ficou verde, deu certo?"

**O que é**

Falha barulhenta é a tarefa que quebra: o estado vira falha, e alguém pode ser avisado. Falha silenciosa é a carga que termina com sucesso e não traz dado, ou traz dado errado.

**Como funciona na prática**

Num teste feito para esta apostila, rodamos o mesmo SQL pelo cron e pelo Airflow. O cron não faz parte do laboratório da mentoria; aqui ele aparece só como resultado observado.

Com o login da réplica cortado, o cron se comportou como o capítulo 4 contou: o erro ficou só num arquivo de log dentro do contêiner, e o `docker compose logs cron` voltou vazio. Ninguém foi avisado, porque não havia alerta configurado.

Num dia sem dado novo, todos os passos do cron disseram `ok`, com `bronze=0`. A execução agendada do Airflow terminou em sucesso, com zero linhas no bronze.

**O equívoco comum**

Achar que verde quer dizer dado certo. Verde quer dizer que o código não lançou erro. Sem checagem explícita, o orquestrador não sabe que zero linhas é problema.

##### 9.2 Avisar quando quebra: callback e notifier

"Quando a tarefa quebra, quem me avisa?"

**O que é**

No Airflow, o aviso vem de callbacks, funções chamadas quando o estado muda. São cinco: `on_success_callback`, `on_failure_callback`, `on_retry_callback`, `on_execute_callback` e `on_skipped_callback`. No lugar da função, cabe um notifier, um notificador pronto.

O alerta de prazo (Deadline Alerts) chama um callback quando a execução da Dag passa do tempo definido. É novo na 3.1, a documentação pede que seja tratado como experimental, e substitui o SLA, que saiu no Airflow 3. Na mentoria, recomendamos começar por callback ou notifier.

**O equívoco comum**

Testar o alerta marcando a tarefa como falha na interface. Estado mudado pela interface ou pela linha de comando não executa callback. O teste fica mudo e não prova nada.

E erro dentro do callback vai para o log do Dag processor, que por padrão não aparece na interface. Callback quebrado é alerta mudo. No laboratório, o `print` do callback apareceu no log da própria tarefa, logo depois da exceção; o callback que quebra não foi testado.

##### 9.3 O registro de carga

"Como sei o que rodou ontem, e quantas linhas trouxe?"

**O que é**

Registro de carga é uma tabela com cada carga: quando rodou, se foi agendada ou manual, quantas linhas.

**Como funciona na prática**

Dá para começar à mão, com um `INSERT` depois de cada carga. Quando a entrega à diretoria virar recorrente, uma tarefa grava a linha sozinha. A tabela do laboratório:

```sql
CREATE TABLE IF NOT EXISTS controle_carga (
    id             bigserial PRIMARY KEY,
    run_id         text NOT NULL,
    tipo_execucao  text NOT NULL,
    linhas         integer NOT NULL,
    registrado_em  timestamptz NOT NULL DEFAULT now()
);
```

A tarefa que grava, trecho da Dag `registro_de_carga`:

```python
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
```

**O equívoco comum**

Gravar o tipo com `str()`. O `run_type` é uma enumeração: `str()` grava `DagRunType.MANUAL`, e `.value` grava `manual`. A primeira versão do laboratório saiu com `DagRunType.SCHEDULED` na tabela, e todo filtro depois teria de conhecer esse texto.

##### 9.4 O alerta que pega a falha verde

"E se a carga rodar e não trouxer nada novo?"

**O que é**

Uma checagem que compara a contagem com a da carga anterior. Se repetiu, a origem pode não ter sido atualizada.

**Como funciona na prática**

Trechos da mesma Dag, sem a indentação da função que a define:

```python
def alertar(context) -> None:
    # Stand-in for a real channel (email, chat); prints so the lab needs no credentials.
    ti = context["task_instance"]
    print(f"ALERTA: a task {ti.task_id} falhou na execução {context['run_id']}")


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
```

A checagem quebra de propósito, e a falha chama o callback. Ela roda sem nova tentativa, porque repetir a comparação não atualiza a origem.

As três cargas do laboratório:

| Carga | Tipo | Linhas | Resultado |
|---|---|---|---|
| 1 | agendada | 5 | sucesso, primeira carga |
| 2 | manual, depois de dois pedidos novos | 7 | sucesso, a contagem mudou de 5 para 7 |
| 3 | manual, sem mudança na origem | 7 | falha em `checar_repeticao`, `ALERTA` no log |

Log da terceira carga, sem o horário de cada linha:

```text
error Task failed with exception
    ValueError A contagem repetiu a carga anterior (7 linhas). A origem pode não ter sido atualizada.
info ALERTA: a task checar_repeticao falhou na execução manual__2026-10-29T15:37:56.280786+00:00
```

Aqui o alerta só escreve no log, para rodar sem credencial. Nenhum canal real foi testado. No seu ambiente, troque o `print` por um canal que alguém lê.

Contagem repetida nem sempre é erro. Num dia sem venda, ela repete de verdade. Por isso o alerta chama uma pessoa, e a pessoa decide.

**O equívoco comum**

Achar que a Dag roda na ordem que você imaginou. Ela roda na ordem que você declarou. Na primeira versão do laboratório, a contagem não dependia da carga. Ela começou junto com a criação das tabelas e falhou com `UndefinedTable`. A Dag tinha uma nova tentativa configurada (no Airflow 3 ela vem desligada), e essa nova tentativa passou e escondeu o erro de ordem. Na carga seguinte, contou antes de carregar, registrou 5 em vez de 7 e disparou um alerta falso.

##### 9.5 Checagens prontas e a tarefa vigia

"Preciso escrever toda checagem à mão?"

**O que é**

Não. As boas práticas do Airflow, na seção de autochecagens (Self-Checks), mandam pôr checagens dentro da própria Dag. O provider common-sql traz `SQLColumnCheckOperator` e `SQLTableCheckOperator`, para coluna e tabela. Traz também `SQLValueCheckOperator`, que compara uma consulta com um valor esperado, e `SQLThresholdCheckOperator`, que confere mínimo e máximo, cada um número ou outra consulta SQL.

Nível 1: a página do provider está na 2.4.0, a imagem do laboratório traz a 2.1.1, e nenhum desses operadores rodou nele.

**O equívoco comum**

Confiar numa tarefa final que roda sempre. O estado da execução vem das tarefas folha, as que não têm nada depois. Uma folha com regra de disparo (trigger rule) `all_done` roda de qualquer jeito e, se passa, deixa a execução verde com falha no meio. A correção da documentação é a tarefa vigia (watcher): uma tarefa com `TriggerRule.ONE_FAILED`, a jusante de todas as outras.

##### 9.6 Quem vigia o orquestrador

"E se o próprio Airflow parar?"

**O que é**

O código HTTP de `/api/v2/monitor/health` não prova saúde. Ele responde 200 mesmo com um componente doente. A saúde está no campo `status` de cada componente. O scheduler vira `unhealthy` depois de 30 segundos sem sinal de vida (heartbeat), o padrão de `scheduler_health_check_threshold`.

O `/api/v2/version` também não serve de prova. No compose oficial, ele respondeu 200 sem token, enquanto `/api/v2/dags` respondeu 401: a resposta não mostra que a API autenticada está de pé. O próprio compose oficial checa o servidor de API por `/api/v2/monitor/health`.

**O equívoco comum**

Confiar num alerta que nunca chegou a ninguém. No postmortem público da queda de 31 de janeiro de 2017, o GitLab conta que o backup diário com `pg_dump` 9.2 falhava contra o PostgreSQL 9.6. Os e-mails de erro do cron eram rejeitados pelo destino, por falta de DMARC. Ninguém soube da falha até precisar restaurar o backup. Entre as ações listadas, estão monitorar o backup e testar a restauração de forma automática.

A lição, na leitura da mentoria: alerta só vale se comprovadamente chega. Provoque uma falha real, executada pelo Airflow, e confira se a mensagem chegou.

**Como inspecionar**

Você roda o registro de carga e o alerta deste capítulo no Lab 3. Para ver o estado de cada tarefa e o registro:

```bash
docker compose exec airflow-scheduler airflow tasks states-for-dag-run registro_de_carga <run_id>
docker compose exec postgres psql -U loja -d loja -c \
  "SELECT id, run_id, tipo_execucao, linhas FROM controle_carga ORDER BY id;"
```

Saída observada (o `run_id` muda a cada execução):

```text
 id |                  run_id                  | tipo_execucao | linhas
----+------------------------------------------+---------------+--------
  1 | scheduled__2026-10-29T10:00:00+00:00     | scheduled     |      5
  2 | manual__2026-10-29T15:37:31.582613+00:00 | manual        |      7
  3 | manual__2026-10-29T15:37:56.280786+00:00 | manual        |      7
(3 rows)
```

**Verificação do código deste capítulo**

- Dag `registro_de_carga` e tabela `controle_carga`: nível 3. Executadas em 2026-10-29, em ambiente descartável, com a imagem `apache/airflow:3.3.2-python3.13` (mesmo digest de `apache/airflow:3.3.2`; Python 3.13.15, provider common-sql 2.1.1), LocalExecutor e Postgres `16.15-alpine`. Comandos que provaram: `airflow dags unpause registro_de_carga`, dois `airflow dags trigger registro_de_carga`, `airflow tasks states-for-dag-run registro_de_carga <run_id>` e a consulta ao `controle_carga` acima. Os comandos de "Como inspecionar" estão no nível 3.
- A mesma Dag no nível 2: `ruff check --select AIR,E,F,W --preview` com ruff 0.12.12, sem erro, em 2026-10-29.
- Operadores de checagem do common-sql e tarefa vigia: nível 1, só documentação.

O registro de carga diz o que aconteceu na sua ponta. O capítulo 10 volta à origem: ler sem travar e guardar o que ela apaga.

#### 10. Proteger a origem e guardar o que some

Dois cuidados vêm antes de qualquer Dag. O primeiro é ler a origem sem travá-la. O segundo é perceber que alguns dados só existem hoje. Se ninguém guardar, amanhã sumiram.

##### 10.1 Ler sem travar: a réplica só leitura

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

##### 10.2 Não sufocar a origem

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

##### 10.3 O dado que some: a foto agendada

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

##### 10.4 O que é de Orquestração e o que é de Modelagem

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

#### 11. Onde rodar e quanto custa: a decisão do gestor

O gerente de TI do capítulo 1 começou à mão, e fez bem. Agora o número vai para a
diretoria todo dia, e a pergunta mudou: "se for Airflow, quanto custa por mês, e quem cuida?".
Vamos responder em três contas: fatura, horas de gente e risco de ciclo de vida.

##### 11.1 Três formas de rodar

**O que é**

Onde rodar é decidir quem cuida da máquina, do banco de metadados e das atualizações: o seu
time, um fornecedor, ou um serviço que só cobra quando a tarefa roda.

**Como funciona na prática**

A documentação do Airflow lista o que fica com você em cada forma.

1. **Máquina própria.** Com a imagem Docker, o seu time monta a instalação, cuida do banco de
   metadados e do schema, monitora e dimensiona memória e CPU. O mínimo recomendado é 4 GB de
   memória; o guia do Docker Compose diz que o ideal é 8 GB.
2. **Serviço gerenciado.** O fornecedor cuida da máquina e do banco de metadados; o fluxo e a
   escolha da versão continuam com você (veja 11.3). A documentação descreve o público: quem
   prefere o Airflow gerenciado e aceita pagar por isso.
3. **Sem servidor (serverless).** O MWAA Serverless, da AWS, cobra pelo tempo de tarefa. Em
   troca, o fluxo é escrito em YAML com operadores da AWS, sem a interface do Airflow. Para
   operador próprio em Python, a AWS indica o ambiente provisionado.

**O equívoco comum**

"Máquina própria sai mais barato." Na fatura, sai mais barato que o gerenciado provisionado; o
sem servidor pode sair ainda mais barato quando o fluxo é curto e raro. A conta do gestor é
fatura mais horas de gente, e o gerenciado troca uma pela outra.

Cuidado também com o atalho. O Docker Compose oficial é para aprender e não dá garantia de
segurança de produção; para produção, a recomendação é Kubernetes com o pacote oficial (Helm
chart). SQLite nunca vai para produção. Num servidor Windows, o Airflow roda só por WSL2 ou
contêiner Linux, e produção só é suportada em Linux.

##### 11.2 A tabela com número

"Me dá um número para a reunião." Aqui está, com as três formas no mesmo provedor. Preço de
tabela da AWS, em dólar, sem imposto nem desconto, consultado em 2026-10-29, num mês de 744
horas, e só o preço por hora do ambiente; outros itens da fatura não entram.

| Forma | Exemplo na AWS | Preço de tabela do ambiente no mês (744 h) | O que fica com o seu time | Limite que pesa |
|---|---|---|---|---|
| Máquina própria | 8 GB e 2 vCPU no Lightsail | cerca de US$ 44 | instalação, banco, atualização, recuperação, monitoramento | o Compose de aprender não serve para produção |
| Gerenciado | MWAA na menor classe (`mw1.micro`) | na casa de US$ 200 a US$ 400, conforme a região | o fluxo e a escolha de versão | até 25 Dags e 3 tarefas ao mesmo tempo, sem autoescala |
| Sem servidor | MWAA Serverless | na casa de US$ 0,08 a US$ 0,10 por hora de tarefa | o fluxo em YAML | sem interface; operador próprio pede o provisionado |

No gerenciado, a ponta de baixo é a Virgínia do Norte, a de cima é São Paulo. Na fatura, a
máquina própria custa cerca de cinco a oito vezes menos.

A coluna de gente não tem preço de tabela. Peça ao time a estimativa em horas por mês para
instalar, atualizar e recuperar a máquina. Se essas horas custam mais que a diferença na
fatura, o gerenciado sai mais barato.

Na geração 3, o Google cobra o gerenciado dele por capacidade: US$ 0,06 por DCU-hora em
us-central1. A DCU (Data Compute Unit) é uma unidade abstrata de medida dos recursos de
computação alocados ao ambiente. O total depende do tamanho do ambiente. Em qualquer provedor, confira
a página de preço no dia da apresentação.

**O equívoco comum**

"Sem servidor é sempre o mais barato." Ele cobra por uso, o que favorece fluxo curto e raro. Em
troca, você perde a interface. Se o time precisa dela para ver falha e histórico, a resposta é o
gerenciado provisionado ou a máquina própria.

##### 11.3 Ciclo de vida: a versão que você compra

**O que é**

Ciclo de vida é até quando uma versão recebe correção. O gestor pergunta: "se pago gerenciado,
a versão é problema dele?". Em parte.

**Como funciona na prática**

<!-- reconferir este trecho, com data, na 3.4.0 antes de publicar -->
- **Projeto Apache:** a estável é a 3.3.2, de 2026-09-17. A 3.4.0 está em versão candidata,
  prevista para 2026-11-02. A linha 3 está em manutenção, sem data de fim. A linha 2 está em fim de vida desde 2026-04-22, sem correção nem suporte.
- **MWAA:** vai até a 3.3.1 e ainda oferece a 2.11.2, que chegou em julho de 2026, depois do fim
  de vida da linha 2. Só troca a versão menor, então sair do 2 para o 3 exige ambiente novo. Cada
  versão tem ao menos 12 meses de suporte, com aviso de 180 dias.
- **Google:** em 2026-04-15, anunciou que o Cloud Composer está se tornando o Managed Service for
  Apache Airflow. A imagem
  mais nova traz a 3.3.1; a padrão ainda é a 2.11.1.
- **Microsoft:** o Airflow do Azure Data Factory não cria instância nova desde 2026-01-01. O
  sucessor, no Fabric, suporta só a 2.10.5, sem rede privada.
- **Astronomer:** mantém a versão do Airflow 3.3 até julho de 2028, e a do 2.11 até abril de 2027.

**O equívoco comum**

"Gerenciado está sempre na versão nova." A padrão pode ser da linha que o projeto já encerrou, e
o produto pode mudar de nome ou parar de aceitar instância nova. Pergunte ao fornecedor: qual
versão, e até quando.

##### 11.4 O que o gerente leva à diretoria

Quando a entrega vira recorrente, o gerente leva
três caminhos: máquina própria por cerca de US$ 44 por mês, mais as horas de quem mantém;
gerenciado menor da AWS na casa de US$ 200 a US$ 400, com menos horas de gente; sem servidor, se
o fluxo couber nos operadores da AWS. A decisão não é a ferramenta. É quem fica com a máquina, a
versão e o alerta.

**Quadro: perguntas para o seu time**

1. Se a carga de ontem rodar de novo agora, o resultado muda?
2. Quem recebe o aviso quando falha, e por qual canal?
3. Como reprocessamos a semana passada, e quanto tempo leva?
4. Onde fica o registro de cada carga: quando rodou, se foi agendada ou manual, quantas linhas?
5. Em que fuso está o horário que combinamos com a diretoria?
6. Temos um ambiente para testar antes de produção, e a Dag tem teste?
7. Qual a versão da ferramenta, e até quando ela tem suporte?
8. Se não for gerenciado, quem mantém a máquina, o banco de metadados e as atualizações?
9. O tratamento roda no banco, ou os dados passam por dentro do orquestrador?

Decidido onde roda, vamos ao código. O capítulo 12 leva o script à mão para uma Dag, sem mudar o SQL.

#### 12. Do script à Dag: o mesmo fluxo, muda quem roda

Você já roda a carga da loja à mão. Funciona, e é um bom começo. Quando a entrega para a
diretoria virar diária, alguém vai ter de rodar o comando todo dia, no horário, e lembrar do que
falhou. Este capítulo troca quem roda. O SQL não muda.

##### 12.1 O mesmo SQL, outro executor

"Vou ter de reescrever o tratamento para o Airflow?" Não.

**O que é**

A Dag é a definição do fluxo: quais passos existem e em que ordem rodam. O tratamento continua
nos arquivos SQL, executados pelo banco. O Python da Dag só encadeia e entrega cada arquivo ao
banco.

**Como funciona na prática**

À mão, no laboratório, você roda um comando por dia; o contêiner `runner` recebe a variável
`DW_URL`, que aponta para o armazém:

```text
$ docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-21
2026-10-29T13:37:09-03:00 dia=2026-10-21 modo=idempotente executor=manual
  bronze_pedidos.sql: ok
  silver_pedidos.sql: ok
  gold_vendas_por_dia.sql: ok
  registrar_carga.sql: ok
  resultado: bronze=3 silver=3 receita_paga=111.90
```

*Saída do laboratório, sem as linhas de contêiner do Compose.*

O script executa quatro arquivos da pasta `dags/sql/` numa transação só. O arquivo
`dags/pipeline_loja.py` lê os mesmos arquivos, da mesma pasta, e cria duas Dags que só mudam no
arquivo do bronze: `loja_idempotente`, a deste capítulo, e `loja_ingenua`, que só insere
(capítulo 6). O bronze é uma tarefa Python só para o laboratório simular a queda depois de gravar
(capítulo 6); o SQL que ele roda é o mesmo do script.

```python
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
```

> Verificação: nível 3. É o arquivo `dags/pipeline_loja.py` do laboratório do capítulo 13,
> sem mudança, executado em 2026-10-29 em ambiente descartável, com a imagem `apache/airflow:3.3.2`
> (mesmo digest de `apache/airflow:3.3.2-python3.13`, a tag que a apostila fixa) e PostgreSQL
> 16.15 em contêiner. Comandos que provaram: `airflow dags list-import-errors`,
> `airflow dags trigger` e `airflow tasks states-for-dag-run`, com as saídas da seção 12.4, e
> `airflow backfill create` (capítulo 7). Nível 2: `ruff check --select E,F,W,I,B,UP
> --line-length 120` e `ruff format --check --line-length 120`, ruff 0.12.12, sem erro.

O que acontece a cada dia:

1. O Dag processor lê o arquivo e registra as duas Dags, cada uma com quatro tarefas.
2. Com a `start_date` no fuso de São Paulo, `0 6 * * *` cria uma execução às 6h de Brasília (9h
   em UTC, no laboratório). Fuso é o capítulo 8.
3. `DIA` vira o dia anterior à data lógica (capítulo 7).
4. Cada tarefa abre a Connection `dw_db`, troca `%(dia)s` pelo valor e manda o arquivo ao banco.
5. A última tarefa grava quem rodou: `airflow:scheduled` na execução das 6h, `airflow:manual` num
   disparo à mão e `airflow:backfill` num reprocessamento de datas passadas.

Por que `split_statements=True`? Os arquivos de bronze, silver e gold têm um `DELETE` e um
`INSERT`, e o psycopg 3, driver do Postgres na imagem 3.3.2, não executa várias instruções com
parâmetros num comando só. Ligada, a opção separa as instruções; o padrão é desligada.
`catchup=False` deixa explícito o padrão do Airflow 3, e `max_active_runs=1` segura uma execução
agendada por vez; o reprocessamento de datas passadas tem limite próprio (capítulo 7).

Uma diferença é real. O script grava tudo numa transação. Na Dag, cada camada é uma tarefa com
conexão própria, que grava ao terminar: no laboratório, para o dia 21, o silver leu as 3 linhas que
o bronze acabara de gravar. Se o gold falhar, bronze e silver já estão no banco. Por isso bronze,
silver e gold apagam o dia antes de inserir, e rodar de novo dá o mesmo resultado (capítulo 6). O
registro de carga é a exceção: ganha uma linha por execução, porque guarda o histórico.

**O equívoco comum**

Achar que o Airflow é o código de limpeza. Ele é quem roda o código. Tratamento errado no script
continua errado na Dag, só que todo dia às 6h.

##### 12.2 Imports do Airflow 3 e o que saiu do 2

"Copiei um tutorial e deu erro antes de rodar. O que houve?"

**O que é**

No Airflow 3, o que você escreve na Dag (`dag`, `task`, `DAG`) vem de `airflow.sdk`, e os
operadores vêm de pacotes de provedores (providers).

**Como funciona na prática**

| No material do Airflow 2 | Na 3.3.2 | Use |
|---|---|---|
| `DAG(schedule_interval="@daily")` | `TypeError` | `schedule="@daily"` |
| `from airflow.providers.postgres.operators.postgres import PostgresOperator` | `ModuleNotFoundError` | `SQLExecuteQueryOperator`, do provider common-sql |
| `from airflow.operators.python_operator import PythonOperator` | `ModuleNotFoundError` | `airflow.providers.standard.operators.python` |
| `from airflow.decorators import dag, task` | ainda importa | `from airflow.sdk import dag, task` |

> Verificação: nível 3. Cada linha da coluna do meio foi observada em 2026-10-29, em ambiente
> descartável, na imagem `apache/airflow:3.3.2`.

O guia de atualização marca os caminhos antigos que ainda importam para remoção numa versão
futura. Aprenda só os novos. O `MsSqlOperator` também saiu, e o pacote do SQL Server manda usar o
mesmo `SQLExecuteQueryOperator`. Para um ERP em SQL Server, a troca esperada é a Connection; o
laboratório só testou Postgres.

**O equívoco comum**

Reinstalar tudo por causa de um erro de import. Antes, confira a versão do tutorial.

##### 12.3 O que não vai no arquivo da Dag

"Posso deixar a senha e uma consulta de configuração no topo do arquivo?"

**O que é**

O Dag processor relê cada arquivo a cada 30 segundos, no padrão. Tudo que está no topo roda a cada
leitura, não só quando a Dag executa.

**Como funciona na prática**

- Nada de acesso a banco, rede ou cálculo pesado no topo. `Variable.get` no topo faz uma chamada a
  cada leitura; use o modelo de texto (template) `{{ var.value.<nome> }}`, resolvido na execução.
- `start_date` fixa. Com `datetime.now()`, o agendamento se confunde e o Airflow 3 cria uma versão
  nova da Dag a cada leitura. Desde a 3.2, o Dag processor avisa.
- Senha fora do código. A Connection pode vir de uma variável de ambiente `AIRFLOW_CONN_` mais o id
  em maiúsculas: `AIRFLOW_CONN_DW_DB` alimenta `conn_id="dw_db"`. O mascaramento nos logs vale para
  o que vem de Connection ou Variable; valor repassado por XCom não é mascarado.
- Paciência com Dag nova. Ela pode levar até cerca de 5 minutos para aparecer, pela varredura
  explicada na seção 5.5. O laboratório baixa para 30 segundos.

**O equívoco comum**

Salvar o arquivo, não ver a Dag e concluir que está quebrada. Rode
`airflow dags list-import-errors` antes de mexer.

##### 12.4 Como inspecionar

"Como sei que a Dag funciona antes de subir?"

Dag é código de produção. Teste antes, nesta ordem:

```bash
python dags/pipeline_loja.py
airflow dags list-import-errors
airflow dags test loja_idempotente 2026-10-22
airflow tasks states-for-dag-run loja_idempotente <run_id>
```

1. O Python carrega o arquivo no mesmo ambiente do scheduler: dependência faltando ou erro de
   sintaxe aparecem aqui, antes de qualquer execução.
2. A lista de erros responde `No data found`.
3. O `dags test` roda uma execução inteira, sem agendador, na data lógica que você passar. Num
   contêiner que sai, com SQLite e a imagem já baixada, a Dag mínima levou cerca de 33 s, contando
   a criação do banco.
4. O `states-for-dag-run` mostra o estado de cada tarefa, com o `run_id` da execução. No
   laboratório, para a execução `retry_idempotente`, disparada com data lógica 2026-10-21 às 9h
   UTC, a saída foi esta (o bronze passou na segunda tentativa, depois da queda simulada do
   capítulo 6):

```text
dag_id           | logical_date              | task_id         | state   | start_date                       | end_date
=================+===========================+=================+=========+==================================+=================================
loja_idempotente | 2026-10-21T09:00:00+00:00 | silver          | success | 2026-10-29T16:47:09.015959+00:00 | 2026-10-29T16:47:10.751191+00:00
loja_idempotente | 2026-10-21T09:00:00+00:00 | gold            | success | 2026-10-29T16:47:11.313194+00:00 | 2026-10-29T16:47:12.529448+00:00
loja_idempotente | 2026-10-21T09:00:00+00:00 | registrar_carga | success | 2026-10-29T16:47:13.532590+00:00 | 2026-10-29T16:47:14.638679+00:00
loja_idempotente | 2026-10-21T09:00:00+00:00 | bronze          | success | 2026-10-29T16:47:06.639183+00:00 | 2026-10-29T16:47:08.811795+00:00
```

Se preferir a interface, abra a execução da Dag e confira o estado de cada tarefa.

Por fim, olhe o registro de carga. Os mesmos dias, rodados à mão e pela Dag. À mão:

```text
 id | executor | dia_referencia | linhas_bronze | linhas_silver | receita_paga
----+----------+----------------+---------------+---------------+--------------
  1 | manual   | 2026-10-20     |             4 |             4 |       430.90
  2 | manual   | 2026-10-21     |             3 |             3 |       111.90
  3 | manual   | 2026-10-22     |             3 |             3 |       293.30
(3 rows)
```

Pela Dag, num reprocessamento dos mesmos três dias, rodado duas vezes (capítulo 7):

```text
 id |     executor     | dia_referencia | linhas_bronze | linhas_silver | receita_paga
----+------------------+----------------+---------------+---------------+--------------
  1 | airflow:backfill | 2026-10-22     |             3 |             3 |       293.30
  2 | airflow:backfill | 2026-10-21     |             3 |             3 |       111.90
  3 | airflow:backfill | 2026-10-20     |             4 |             4 |       430.90
  4 | airflow:backfill | 2026-10-20     |             4 |             4 |       430.90
  5 | airflow:backfill | 2026-10-21     |             3 |             3 |       111.90
  6 | airflow:backfill | 2026-10-22     |             3 |             3 |       293.30
(6 rows)
```

Mesmos números. Só mudou quem rodou.

> Verificação: nível 3. Saídas copiadas sem mudança do laboratório, executado em
> 2026-10-29 em ambiente descartável, com a imagem `apache/airflow:3.3.2` e PostgreSQL 16.15:
> `airflow dags list-import-errors`, `airflow tasks states-for-dag-run` da execução
> `retry_idempotente`, o script à mão e o backfill. Os comandos do Airflow rodaram com
> `docker compose --profile airflow exec -T airflow-scheduler` na frente. Os 33 s vêm do
> `airflow dags test` da Dag mínima, no mesmo dia e na mesma imagem. `python dags/pipeline_loja.py`
> e `airflow dags test loja_idempotente 2026-10-22` também estão no nível 3: rodaram em 2026-10-29
> no laboratório do capítulo 13, com `docker compose exec airflow-scheduler` na frente e a imagem
> `apache/airflow:3.3.2-python3.13`. O primeiro terminou sem saída e com código 0; o segundo marcou
> a execução como `successful` em cerca de 15 s e gravou o dia 21 no registro de carga, com o
> executor `airflow:manual`.

**O equívoco comum**

Tratar o `dags test` como simulação. Ele executa as tarefas de verdade, e o que a Dag grava vai
para o banco. Aponte a Connection para um banco de homologação, com a Dag parametrizada por
variável de ambiente, nunca para a produção.

Agora é com você. O capítulo 13 monta tudo isso na sua máquina.

#### 13. Laboratório

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

##### Lab 0: Preparar a máquina

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

##### Lab 1: Réplica só leitura e o fluxo à mão

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

##### Lab 2: A primeira Dag

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

##### Lab 3: Registro de carga e alerta

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

##### Lab 4: Duplicar e consertar

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

##### Lab 5: Meia-noite e datas

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

#### 14. Exercícios, entregáveis e mini-desafio

"Li tudo. Como sei que consigo fazer sozinho?"

Fazendo. São três níveis. O conceitual pede uma decisão, o cenário pede um diagnóstico e o prático pede prova na tela. O mini-desafio junta datas, fuso e reprocesso.

Tente antes de ler o gabarito. Leve o entregável para a call: o mentor vai pedir para ver, não para ouvir.

##### 14.1 Nível conceitual

"Preciso mesmo de um orquestrador para isso?"

**Exercício 1: Qual degrau?**

Objetivo: escolher entre à mão, agendador e orquestrador pelo sinal, não pela ferramenta.

Contexto: cinco cargas da rede de lojas.

1. Um relatório pedido uma vez, para a reunião de amanhã.
2. Descobrir de onde vem cada número do ERP, pelo monitor de consultas do sistema.
3. A cópia noturna de um arquivo para uma pasta, um passo só, sem ninguém esperando por ela.
4. Réplica, bronze, silver, gold e registro de carga, todo dia, com o número na mesa da diretoria.
5. O painel da operação, atualizado várias vezes por hora, com três passos encadeados.

Entregável: uma tabela com a carga, o degrau e o sinal que decidiu.

**Gabarito comentado**

| Carga | Degrau | Sinal que decidiu |
|---|---|---|
| 1 | À mão | Entrega eventual. |
| 2 | À mão | Você ainda está descobrindo de onde vem o número. |
| 3 | Agendador | Tem hora, mas é um passo só e nada depende dele. |
| 4 | Orquestrador | Passos dependentes, entrega recorrente e alguém precisa saber quando falha. |
| 5 | Orquestrador | Frequência alta e passos encadeados. |

A carga 4 é o caso do mentorado. Começar à mão continua valendo, e o sinal de subir é a entrega virar rotina. Esses sinais são critério da mentoria, do capítulo 4. O equívoco comum é subir por catálogo, porque a ferramenta apareceu numa lista.

**Exercício 2: Quem faz o quê no desenho**

Objetivo: separar orquestração, captura de mudanças (CDC) e organização de SQL.

Contexto: um desenho do tipo que a pesquisa com IA devolve a quem monta a primeira arquitetura. ERP, depois AWS DMS, depois o banco de análise, depois dbt, depois o painel. O Airflow aparece "em cima de tudo".

Entregável: uma frase por peça, dizendo se ela copia, transforma ou decide quando e em que ordem.

**Gabarito comentado**

- **DMS copia.** Lê as mudanças no log de transações da origem e as leva de forma contínua. A AWS avisa que não é replicação em tempo real. O Debezium cumpre o mesmo papel.
- **dbt transforma.** Você escreve `SELECT`, e ele cria tabelas e visões (views) na ordem certa entre os modelos.
- **Airflow decide quando e em que ordem, e guarda o estado.** Com o DMS, tem operadores para criar, iniciar, parar e apagar a tarefa de replicação e um sensor que espera por ela; quem copia continua sendo o DMS. Com o dbt, a execução vira um passo do fluxo.

Um equívoco possível é achar que são o mesmo grafo, porque os dois usam a palavra DAG. O dbt tem um DAG próprio, entre os modelos dele. A Dag do Airflow encadeia o dbt com o que está fora dele, como a carga da réplica.

##### 14.2 Nível cenário

"Rodou verde e o número está errado. Por onde eu começo?"

Os quatro cenários aconteceram no laboratório, com dados sintéticos. A pergunta é sempre a mesma: o que o orquestrador fez, e o que ele não tinha como saber.

**Exercício 3: Verde com painel vazio**

Objetivo: reconhecer uma falha silenciosa.

Contexto: a Dag da loja roda às 06h de Brasília. As quatro tarefas terminaram em sucesso, e o painel mostra o dia 28 vazio. O registro de carga:

```text
 id |     executor      | dia_referencia | linhas_bronze | linhas_silver | receita_paga
----+-------------------+----------------+---------------+---------------+--------------
 11 | airflow:scheduled | 2026-10-28     |             0 |             0 |         0.00
```

Entregável: o que aconteceu, por que ficou verde e o que muda na Dag, em três linhas.

**Gabarito comentado**

Falha silenciosa: o SQL rodou sem erro e não trouxe linha. Verde só quer dizer que o código não lançou exceção. No teste feito para esta apostila (seção 9.1), um dia sem dado novo passou como sucesso no cron, com `bronze=0`, e no Airflow. Sem checagem explícita, nenhum dos dois sabe que zero é problema.

Confira a origem antes de mexer na Dag. Na origem sintética, não houve venda no dia 28, e mesmo assim alguém precisava saber. A mudança está no Exercício 8.

**Exercício 4: O reprocesso que dobrou a semana**

Objetivo: ligar a duplicação à carga, não ao orquestrador.

Contexto: os três dias entraram na gold por um reprocessamento de datas passadas (backfill), que foi a primeira carga deles. Depois de corrigir a silver, alguém rodou o mesmo reprocesso de novo. Tudo terminou em sucesso. A gold:

| Dia | Depois da primeira carga | Depois do reprocesso |
|---|---|---|
| 2026-10-20 | 4 pedidos, 430,90 | 8 pedidos, 861,80 |
| 2026-10-21 | 3 pedidos, 111,90 | 6 pedidos, 223,80 |
| 2026-10-22 | 3 pedidos, 293,30 | 6 pedidos, 586,60 |

Entregável: a causa, a correção antes do próximo reprocesso e o conserto dos dias dobrados.

**Gabarito comentado**

O bronze ingênuo só faz `INSERT`, sem chave. Cada execução acrescenta o dia de novo, e a silver e a gold herdam a cópia. O reprocesso fez o que pedimos: rodou o dia outra vez.

A nova tentativa tem o mesmo efeito. No laboratório, a tarefa gravou, caiu depois do commit e, na nova tentativa, gravou de novo: sucesso, e a gold em 8 pedidos e 861,80. A queda foi simulada, só para o teste.

A correção é o bronze idempotente, do Exercício 7. Ele manteve 4 linhas e 430,90 em duas reexecuções à mão e em dois reprocessos, e consertou um dia já duplicado. Rode-o sobre os dias dobrados.

**Exercício 5: O dia 28 na partição 29**

Objetivo: prever em que partição a carga grava.

Contexto: a loja fecha às 22h. Uma Dag com agenda em cron, sem `interval`, dispara às 22h de Brasília e grava em `dt={{ ds }}`. As vendas do dia 28 aparecem em `dt=2026-10-29`.

Entregável: a explicação em uma frase e a correção.

**Gabarito comentado**

`ds` é a data lógica no formato AAAA-MM-DD, tirada do valor em UTC. O Airflow trabalha em UTC, três horas à frente de Brasília: 22h do dia 28 é 01h do dia 29. Saída do laboratório:

```text
DATAS logical_date=2026-10-29T01:00:00+00:00 (Brasilia 28/10 22:00)
DATAS ds=2026-10-29
```

Corrija calculando o dia do negócio no fuso da loja, a partir da janela convertida para Brasília, como no capítulo 8. O equívoco comum é ler `ds` como "hoje no Brasil".

**Exercício 6: A nova tentativa que escondeu o erro**

Objetivo: ler o grafo que você declarou, não o que imaginou.

Contexto: primeira versão da Dag `registro_de_carga`.

```python
criar_tabelas >> carregar >> checar_repeticao(registrar_carga())
```

Na execução agendada, `registrar_carga` falhou na primeira tentativa com `UndefinedTable`, e a nova tentativa passou. Na carga seguinte, com dois pedidos novos, o registro gravou 5 linhas em vez de 7, e o alerta disparou.

Entregável: o grafo que rodou de fato, a linha corrigida e por que a nova tentativa enganou.

**Gabarito comentado**

Nada põe `registrar_carga` depois da carga. Sem tarefa anterior, ela começou junto com `criar_tabelas` e contou uma tabela que não existia. O orquestrador executa exatamente o grafo declarado.

A nova tentativa passou porque, na hora dela, a tabela já existia. Foi sorte de tempo. Na carga seguinte, a contagem veio antes da carga, repetiu o 5 e gerou um alerta falso. A versão corrigida, com a variável da carga renomeada:

```python
linhas = registrar_carga()
criar_tabelas >> carregar_pedidos_tratados >> linhas
checar_repeticao(linhas)
```

Esta falha é real, não simulada. Tarefa que passa na segunda tentativa merece a leitura do log da primeira.

##### 14.3 Nível prático

"Como eu provo que a carga aguenta rodar de novo?"

Os dois exercícios usam o laboratório do capítulo 13, o mesmo dos Labs 1 e 4.

**Exercício 7: Bronze idempotente, provado duas vezes**

Objetivo: tornar o bronze idempotente, em que rodar de novo dá o mesmo resultado de rodar uma vez.

Contexto: o arquivo `bronze_pedidos_ingenuo.sql`.

```sql
-- Naive load: every rerun of the same day appends the same rows again.
INSERT INTO bronze.pedidos
    (id, cliente, valor, valor_texto, status, criado_em, atualizado_em, _dia_referencia)
SELECT id, cliente, valor, valor_texto, status, criado_em, atualizado_em, %(dia)s::date
FROM replica.pedidos
WHERE criado_em >= %(dia)s::date
  AND criado_em < %(dia)s::date + 1;
```

Entregável: o SQL novo, duas reexecuções do mesmo dia com a saída e a contagem de cópias por pedido.

**Gabarito comentado**

O dia é a unidade que a execução controla. A carga apaga o dia e insere de novo:

```sql
-- Idempotent load: replace the whole day, the caller commits both statements together.
DELETE FROM bronze.pedidos
WHERE _dia_referencia = %(dia)s::date;

INSERT INTO bronze.pedidos
    (id, cliente, valor, valor_texto, status, criado_em, atualizado_em, _dia_referencia)
SELECT id, cliente, valor, valor_texto, status, criado_em, atualizado_em, %(dia)s::date
FROM replica.pedidos
WHERE criado_em >= %(dia)s::date
  AND criado_em < %(dia)s::date + 1;
```

Os dois comandos ficam na mesma transação. O script do laboratório confirma tudo no fim ou desfaz tudo no erro, então uma queda no meio não deixa o dia vazio. A prova, rodada duas vezes:

```bash
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20 2>&1 | grep resultado
```

```text
  resultado: bronze=4 silver=4 receita_paga=430.90
  resultado: bronze=4 silver=4 receita_paga=430.90
```

Na versão ingênua, sobre o dia já carregado, as duas rodadas deram 8 e 12 linhas. As cópias por pedido:

```sql
SELECT id, count(*) AS copias FROM bronze.pedidos
WHERE _dia_referencia = '2026-10-20' GROUP BY id ORDER BY id;
```

Na ingênua, cada pedido saiu com 3 cópias. Na idempotente, com uma.

O outro caminho é o UPSERT, inserir ou atualizar pela chave. No laboratório, a carga repetida deu 6 linhas sem chave, falhou com `duplicate key value violates unique constraint` com chave primária e ficou em 3 com `ON CONFLICT DO UPDATE`.

**Exercício 8: Uma checagem que pega carga vazia**

Objetivo: fazer o dia vazio do Exercício 3 virar falha.

Contexto: o arquivo `pipeline_loja.py`, que monta as Dags `loja_ingenua` e `loja_idempotente`, com `bronze(DIA) >> silver >> gold >> registrar`.

Entregável: uma tarefa entre o bronze e a silver que falha com o dia vazio, e quem recebe o aviso.

**Gabarito comentado**

As boas práticas do Airflow mandam pôr checagens dentro da Dag. O `SQLThresholdCheckOperator`, do provider common-sql, confere se um valor fica entre um mínimo e um máximo, cada um número ou consulta SQL. O import vai no topo do arquivo; o resto entra dentro da função que monta a Dag, aqui sem a indentação dela:

```python
from airflow.providers.common.sql.operators.sql import SQLThresholdCheckOperator

checar_bronze = SQLThresholdCheckOperator(
    task_id="checar_bronze",
    conn_id=CONN_ID,
    sql=f"SELECT count(*) FROM bronze.pedidos WHERE _dia_referencia = '{DIA}'::date",
    # At least one row catches the empty load; the source count catches duplicates.
    min_threshold=1,
    max_threshold=(
        "SELECT count(*) FROM replica.pedidos "
        f"WHERE criado_em >= '{DIA}'::date AND criado_em < '{DIA}'::date + 1"
    ),
)

bronze(DIA) >> checar_bronze >> silver >> gold >> registrar
```

Pela documentação do operador, o mínimo 1 faz o dia vazio falhar, e o máximo, tirado da origem, faz falhar também o dia dobrado do Exercício 4. A checagem fica em SQL; o Python só encadeia.

Esta checagem ficou no nível 2: a Dag carrega e as consultas saem com o dia certo, mas ela não rodou contra o banco do laboratório. Antes de confiar nela, ligue-a e repita os cenários dos Exercícios 3 e 4 para ver as duas falhas.

Para virar alerta, ligue um callback de falha, como no capítulo 9. Num dia sem venda, ela falha de verdade. Por isso o aviso chama uma pessoa, e a pessoa decide.

##### 14.4 Mini-desafio com solução

"Corrigi a silver. Como refaço três dias sem perder nenhum?"

**Enunciado**

Outra Dag diária da loja, diferente da das 06h dos exercícios anteriores, dispara à meia-noite de Brasília, com janela de um dia. Cada execução processa o dia local que acabou de terminar:

```python
CronTriggerTimetable("0 0 * * *", timezone="America/Sao_Paulo", interval=timedelta(days=1))
```

No laboratório, essa agenda é a da Dag `datas_dia_brasilia`, e é ela que aparece nos comandos. O bronze já é idempotente. Reprocesse os dias locais 23, 24 e 25 de outubro de 2026, que já rodaram.

Entregável: o comando e o ensaio que prova, antes de gravar, que entram exatamente os três dias.

**Dicas**

1. Ensaie com `--dry-run`. Ele lista as execuções e não grava nada.
2. Data sem hora vira 00:00 no fuso padrão do Airflow, que vem como UTC, qualquer que seja o fuso da Dag. O fim é inclusivo.
3. Nesta agenda, o filtro olha o disparo. A execução do dia 23 dispara à meia-noite do dia 24.
4. Dias que já rodaram pedem um comportamento de reprocesso que os refaça.

**Solução comentada**

A primeira tentativa costuma ser esta:

```bash
airflow backfill create --dag-id datas_dia_brasilia \
  --from-date 2026-10-23 --to-date 2026-10-25 --dry-run
```

Trecho da saída, sem o cabeçalho e os separadores da tabela:

```text
| 2026-10-22 03:00:00+00:00 |                 |                  |
| 2026-10-23 03:00:00+00:00 |                 |                  |
```

Vieram 22 e 23. Os limites ficaram em 00:00 UTC, e a meia-noite de Brasília é 03:00 UTC. Empurrar um dia, ainda sem hora, também falha: de 24 a 26 vieram 23 e 24. O disparo do dia 25 cai às 03:00 UTC do dia 26, depois do fim.

A solução põe hora explícita nos dois limites, no instante do disparo:

```bash
airflow backfill create --dag-id datas_dia_brasilia \
  --from-date 2026-10-24T03:00:00+00:00 --to-date 2026-10-26T03:00:00+00:00 \
  --reprocess-behavior completed --max-active-runs 1 --dry-run
```

Trecho da saída, com quatro dos parâmetros impressos e sem o cabeçalho e os separadores da tabela:

```text
    - from_date = 2026-10-24 03:00:00+00:00
    - to_date = 2026-10-26 03:00:00+00:00
    - max_active_runs = 1
    - reprocess_behavior = ReprocessBehavior.COMPLETED
| 2026-10-23 03:00:00+00:00 |                 |                  |
| 2026-10-24 03:00:00+00:00 |                 |                  |
| 2026-10-25 03:00:00+00:00 |                 |                  |
```

O porquê de cada escolha:

- **Hora nos limites.** O fim precisa de hora: o disparo do dia 25 cai às 03:00 UTC do dia 26 e, sem hora no fim, ficou de fora. No início, a hora deixa explícito o primeiro disparo; o ensaio de 24 a 26 sem hora já começou na data lógica 23. Com `2026-10-24T00:00:00-03:00` e `2026-10-26T00:00:00-03:00`, o mesmo instante escrito no horário de Brasília, saíram as mesmas três datas; a saída mostrou a primeira com `-03:00`.
- **`--reprocess-behavior completed`.** O padrão pula data que já tem execução.
- **`--max-active-runs 1`.** Um dia por vez contra a réplica.
- **Bronze idempotente antes.** Sem ele, o reprocesso dobra os três dias.

Confirmado o ensaio, rode o mesmo comando sem `--dry-run`.

**Interpretação**

Cada data lógica é o início da janela. 23/10 às 03:00 UTC é meia-noite do dia 23 em Brasília, e a janela vai até a meia-noite do dia 24. No laboratório, as execuções de datas lógicas 22 e 23 às 03:00 UTC cobriram exatamente os dias locais 22 e 23.

Depois, confira a gold e o registro de carga dos três dias. A diretoria vai perguntar se o número de sexta a domingo está certo. O ensaio responde antes de você gravar.

**Verificação do código deste capítulo**

- Código e saídas dos Exercícios 3 a 7 e janelas citadas na Interpretação: nível 3. Executados em 2026-10-29, em ambiente descartável, com a imagem `apache/airflow:3.3.2` (Python 3.13.15), LocalExecutor e Postgres `16.15-alpine`. Os dois SQL do bronze do Exercício 7 são os arquivos do laboratório, rodados pelo serviço `runner` (imagem `python:3.13.15-alpine3.24`) com `python scripts/pipeline.py --dia 2026-10-20` repetido, nos modos idempotente e ingênuo; a consulta de cópias rodou por `psql` logo depois. A primeira versão da dependência do Exercício 6 gerou as saídas da falha; a corrigida é a da Dag `registro_de_carga`, rodada por `airflow dags unpause` e `airflow dags trigger`, e passa em `ruff check --select AIR,E,F,W --preview` e `ruff format --check`, com ruff 0.12.12. Os demais comandos que provaram: `airflow dags trigger loja_ingenua` com a queda simulada; `airflow backfill create` nas Dags `loja_ingenua` e `loja_idempotente`, duas vezes cada; e os valores de data impressos pelas Dags das 22h e da meia-noite de Brasília.
- Agenda do mini-desafio: a da Dag `datas_dia_brasilia` do laboratório, nível 3, na mesma execução.
- Ensaios do mini-desafio: nível 3 no `--dry-run`. Executados em 2026-10-29 com Airflow 3.3.2 instalado por `uv` em Python 3.12.3, banco SQLite novo, sem execuções anteriores. Comando que provou: `airflow backfill create --dag-id datas_dia_brasilia ... --dry-run`, com as quatro janelas citadas. O reprocesso de verdade com esses limites não foi executado.
- Checagem do Exercício 8: nível 2, em 2026-10-29. A Dag da loja com a checagem ligada passou em `ruff check --select E,F,W,I,B,UP --line-length 120` e `ruff format --check --line-length 120`, com ruff 0.12.12, os mesmos do laboratório. Carregou sem erro de importação no Airflow 3.3.2, com providers postgres 7.0.2 e common-sql 2.1.1, e o grafo saiu com `checar_bronze` depois de `bronze` e antes de `silver`. Numa Dag mínima, só com a mesma checagem e a mesma agenda, que passou em `ruff check --select AIR,E,F,W --preview` e `ruff format --check`, o `airflow tasks render` mostrou as duas consultas com o dia 2026-10-20 para a data lógica 2026-10-21 às 09:00 UTC. Não rodou contra o banco.

#### 15. Rubrica de validação da aprendizagem

Como saber, na call, se o mentorado entendeu orquestração ou só decorou o vocabulário? A rubrica responde com evidência que dá para observar. Cada critério tem três níveis: insuficiente, suficiente e excelente. O mentor não pergunta "você entendeu?". O mentor pede para ver.

Vale uma regra de leitura. Suficiente já sustenta uma entrega real. Excelente é quem prova o que afirma, com saída na tela.

| Critério | Insuficiente | Suficiente | Excelente |
|---|---|---|---|
| Degrau: à mão, cron ou orquestrador | Automatiza tudo de saída ou nunca automatiza. | Cita os sinais que a mentoria usa: frequência, número de passos, necessidade de alerta e de nova tentativa, e entrega recorrente. | Mostra o custo e o risco do degrau seguinte. |
| Orquestração ou agendamento | Chama o cron de orquestrador. | Explica que o agendador dispara e o orquestrador guarda ordem, estado e histórico. | Mostra na Dag a dependência que o cron não resolveria. |
| Leitura da origem | Consulta a produção direto. | Lê a réplica só leitura. | Prova que o usuário de leitura, com GRANT só de SELECT, não grava nem depois de `BEGIN READ WRITE` (`permission denied`); sabe que ligar só o `default_transaction_read_only` não segura a escrita. |
| Dependência | Tarefas soltas, sem ordem declarada. | Declara a ordem e explica por que a carga espera a origem. | Derruba uma tarefa e mostra a seguinte em `upstream_failed`, ou acha no grafo uma dependência mal declarada que a nova tentativa escondeu. |
| Idempotência | Reexecuta e não confere o resultado. | Explica por que a carga sobrescreve em vez de acumular. | Prova com duas reexecuções que a contagem não muda. |
| Nova tentativa e alerta | Não sabe que, no padrão do Airflow 3.3.2, a nova tentativa vem desligada (zero novas tentativas: a tarefa roda uma vez e, se falhar, não repete). | Configura nova tentativa com espera e sabe quem recebe o aviso. | Separa falha que vale repetir de falha que precisa de gente. |
| Datas e fuso | Grava a carga pelo `ds` sem perceber que ele é a data em UTC (na agenda cron padrão, sem `interval`, a carga das 22h de Brasília cai na partição do dia seguinte). | Sabe que o fuso padrão do Airflow é UTC, três horas à frente de Brasília, e que data sem fuso é lida em UTC; por isso declara o fuso no `start_date`. | Reprocessa datas passadas com hora e fuso explícitos e mostra qual dia local cada execução leu; sabe que, sem `interval`, a janela de dados tem duração zero. |
| Registro de carga | Só olha se ficou verde. | Grava quando rodou, se foi agendada ou manual e quantas linhas. | Usa o registro para achar uma falha silenciosa e faz a carga falhar com alerta quando a contagem repete a do ciclo anterior. |

No critério do degrau, começar à mão é caminho válido. O insuficiente não é rodar à mão no começo, é não saber dizer quando subir de degrau.

##### 15.1 Como aplicar na call

Para o gestor, o critério de idempotência pesa mais. É ele que responde "posso mandar rodar de novo sem medo?".

Vamos ver como fica a evidência excelente de idempotência. No laboratório do capítulo 13, a versão idempotente da carga apaga o dia e insere de novo, na mesma transação. Rodada duas vezes à mão para o mesmo dia, ela gravou o mesmo resultado (trecho da saída):

```text
$ docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20 2>&1 | grep resultado
  resultado: bronze=4 silver=4 receita_paga=430.90
[saída: 0]
$ docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20 2>&1 | grep resultado
  resultado: bronze=4 silver=4 receita_paga=430.90
[saída: 0]
```

Nível 3, executado com saída capturada. Comando: o de cima, duas vezes. Versão: PostgreSQL 16.15 e Python 3.13.15 (imagem `python:3.13.15-alpine3.24`), sem Airflow neste degrau. Data: 2026-10-29. Dois backfills seguidos do mesmo período, no Airflow 3.3.2 (imagem `apache/airflow:3.3.2`, mesmo digest de `apache/airflow:3.3.2-python3.13`, a tag que a apostila fixa), também deixaram esse dia em 4 pedidos e 430,90 na tabela final.

O contraste é a versão ingênua, que só faz INSERT, sem chave. Com uma queda simulada logo depois de gravar, a nova tentativa gravou tudo de novo, a execução terminou verde e a tabela final dobrou (trecho da saída):

```text
$ docker compose --profile airflow exec -T airflow-scheduler airflow dags trigger loja_ingenua -l 2026-10-21T09:00:00+00:00 -r retry_ingenuo -c '{"simular_queda": true}' -o plain
$ docker compose exec -T postgres psql -U dw -d dw -c 'SELECT * FROM gold.vendas_por_dia;'
    dia     | pedidos | pedidos_pagos | receita_paga 
------------+---------+---------------+--------------
 2026-10-20 |       8 |             4 |       861.80
(1 row)
```

A data lógica 2026-10-21 às 09:00 UTC é a execução das 6h de Brasília, e a Dag da loja carrega o dia anterior; por isso a linha do gold é do dia 20.

Nível 3, executado com saída capturada. Comandos: os dois de cima, em sequência. Na execução, o `psql` levava um segundo `-c` com a consulta ao registro de carga, cortado aqui junto com a saída dele, e a saída do disparo foi omitida. Versão: Airflow 3.3.2, imagem `apache/airflow:3.3.2` (mesmo digest de `apache/airflow:3.3.2-python3.13`), Python 3.13.15, PostgreSQL 16.15. Data: 2026-10-29. Antes de disparar, as tabelas do laboratório foram esvaziadas, então os 8 pedidos são 4 gravados duas vezes.

O equívoco comum é aceitar o print de uma execução verde como prova. Verde mostra que rodou, não mostra que rodar de novo é seguro. Peça a segunda execução e a contagem.

#### 16. Erros comuns e como corrigir

"Deu erro. Por onde eu começo?" Pelo sintoma. Erro comum, aqui, é o que o laboratório
mostrou acontecer, com a mensagem copiada da tela, ou o que a documentação oficial aponta como armadilha;
a nota abaixo diz qual é qual. Cada tabela é um momento do fluxo da nossa rede de
lojas. Ache a linha pelo que você vê, leia a causa e corrija. E guarde uma regra: verde não é
certo.

> Verificação: mensagens e comandos no nível 3, observados em 2026-10-29 na imagem
> `apache/airflow:3.3.2-python3.13`, mesmo digest de `3.3.2`, em Linux e em Windows 11 com WSL2 e
> Docker Engine. A mensagem sai no idioma do sistema: `Permission denied` vira `Permissão negada`.
> O `.gitattributes` do repositório, com `*.sh text eol=lf`, está no nível 3 no Git 2.55.0 do Linux:
> num clone com `core.autocrlf=true`, o `.sh` ficou com LF e um `.txt` virou CRLF; no Git for
> Windows, não foi testado. Ficam no nível 1, conferidos na documentação: o `start_date` com `pendulum`
> (página de fuso, nas fontes), o aviso de versão da Dag, o sensor, o `dag_run.logical_date`, o
> callback e o health.

##### 16.1 Antes da primeira carga: subir o ambiente

"Nada sobe. É a minha máquina?" Muitas vezes é: nenhum destes erros é defeito do Airflow.

| Sintoma | Causa | Correção |
|---|---|---|
| `/usr/bin/env: “bash\r”`, saída 127, sem `.env` | Script com fim de linha do Windows (CRLF) | Clone de dentro do WSL, cujo Git não converte; no repositório, `*.sh text eol=lf` no `.gitattributes` |
| `/bin/sh^M: bad interpreter` no Postgres; depois, `Skipping initialization` e nada do banco `loja` | Script de inicialização em CRLF; com o volume criado, o Postgres não roda o script de novo | Converta para LF e apague o volume: `docker compose down --volumes --remove-orphans`. O `pg_isready` não pega esse caso |
| `Permission denied` ao criar ou editar Dag; `dags/` com dono `50000:0` | `AIRFLOW_UID` fixo em 50000, como num runbook antigo | Apague esse `.env`, rode o `preparar.sh`, que grava `AIRFLOW_UID=$(id -u)`, e suba de novo: o `airflow-init` devolve `dags/` e `logs/` ao seu usuário |
| `df -h` no WSL mostrando `205G` livres (cerca de 205 GiB) e o C: com pouco mais de 2 GB | O disco do WSL é o arquivo `ext4.vhdx`, no C:; o `df` mede o disco virtual, cujo tamanho máximo não depende do espaço que sobra no C: | Meça com `Get-PSDrive C` no PowerShell e libere espaço antes de baixar a imagem, que ocupa cerca de 2,3 GB em disco depois de extraída (capítulo 0) |
| Ler arquivo fica de 120 a 170 vezes mais lento | Projeto em `/mnt/c` (medido com a opção `metadata` ligada no `/mnt/c`, que não é o padrão; sem ela, o número não foi medido) | Clone no home do Linux; nas Dags pequenas do laboratório, o Airflow não mostrou diferença de tempo |

**O equívoco comum**

Copiar `AIRFLOW_UID=50000` porque a documentação cita o número. Ela cita
para outros sistemas. No Linux vale o seu usuário, e no teste o WSL se comportou como Linux.

##### 16.2 Ao escrever a Dag da loja

"Copiei um tutorial e deu erro antes de rodar."

| Sintoma | Causa | Correção |
|---|---|---|
| `TypeError: DAG.__init__() got an unexpected keyword argument 'schedule_interval'` | O Airflow 3 removeu `schedule_interval` | `schedule=`, como `schedule="0 6 * * *"` na Dag da loja |
| `ModuleNotFoundError` em `python_operator`, `bash_operator` ou `PostgresOperator` | Caminhos do Airflow 2 | `airflow.sdk` e providers (capítulo 12) |
| Dag processor avisa que a versão da Dag não para de crescer | `start_date=datetime.now()` muda a cada leitura | `pendulum.datetime(2026, 10, 15, tz="America/Sao_Paulo")` |
| Dag nova não aparece | Varredura de arquivo novo a cada 300 s | Espere até 5 minutos; o laboratório usa 30 s |
| `UndefinedTable` na primeira tentativa da contagem, sucesso na segunda, alerta falso com 5 linhas em vez de 7 | A contagem não dependia da carga | `carregar_pedidos_tratados >> linhas`, e leia o log de cada tentativa |

**O equívoco comum**

Achar que a nova tentativa resolveu. Esse erro de ordem foi real, e a
segunda tentativa o escondeu. O orquestrador executa o grafo que você declarou.

##### 16.3 Na carga do dia

"Ficou tudo verde. Por que a receita dobrou?" A Dag da loja roda às 6h de Brasília e carrega o
dia anterior. Nenhum destes erros fica vermelho na hora.

| Sintoma | Causa | Correção |
|---|---|---|
| Receita do dia de 430,90 para 861,80 | INSERT sem chave: a nova tentativa, ou a reexecução à mão, grava o dia de novo | Apague o dia e insira na mesma transação, ou UPSERT pela chave |
| Zero linhas no bronze | Falha silenciosa: ninguém confere a contagem | Registro de carga e tarefa que falha quando a contagem repete (capítulo 9); uma checagem de zero linhas segue a mesma ideia (não verificado: essa checagem não foi implementada no laboratório) |
| Sensor há dias segurando vaga de execução (slot) | O modo padrão, poke, ocupa a vaga; o tempo limite padrão é de 7 dias | `mode="reschedule"` e tempo limite explícito; a versão adiável exige o triggerer, que o compose leve não sobe |

O conserto da primeira linha é o bronze que apaga e regrava o dia, o mesmo SQL da seção 6.2.

> Verificação: nível 3, Postgres 16.15. `python scripts/pipeline.py --dia 2026-10-20` duas vezes
> deu 430,90 nas duas; só com INSERT, 861,80 e 1.292,70, com saída 0. Na Dag, a nova tentativa
> deixou uma cópia de cada pedido. A queda foi simulada de propósito, depois do commit.

**O equívoco comum**

Ligar a nova tentativa antes de a carga ser idempotente. Na 3.3.2, sem
configuração, ela vem desligada (`default_task_retries` 0). Ligue quando rodar duas vezes der o
mesmo número.

##### 16.4 Nas datas: o fechamento das 22h e o reprocesso à mão

"Por que o dia 28 foi parar no 29? E por que o disparo à mão quebrou?"

| Sintoma | Causa | Correção |
|---|---|---|
| Carga do dia 28 na partição `dt=2026-10-29` | `ds` é a data lógica em UTC; 22h do dia 28 em Brasília já é dia 29 em UTC | `CronTriggerTimetable("0 0 * * *", timezone="America/Sao_Paulo", interval=timedelta(days=1))` deu `ds=2026-10-28` (capítulo 8) |
| `UndefinedError: 'ds' is undefined` | Disparo sem data lógica (CLI sem `-l`, API com `logical_date: null`) não tem `ds` nem janela | `airflow dags trigger datas_cron_puro -l 2026-10-20T00:00:00+00:00` deu `ds=2026-10-20`. Com `-l`, o `ds` segue a data pedida, mas pela CLI o intervalo de dados continua ancorado no disparo; para reprocessar um dia, use backfill, ou leia `dag_run.logical_date` em vez do intervalo |

**O equívoco comum**

Testar só à mão e supor que a execução agendada recebe o mesmo contexto.

##### 16.5 Ao vigiar a carga

"Como sei que o alerta funciona e que o Airflow está vivo?"

| Sintoma | Causa | Correção |
|---|---|---|
| Marcou falha na interface e o alerta não chegou | Callback só roda quando o worker muda o estado | Teste com falha real; erro no callback vai para o log do Dag processor, fora da interface por padrão |
| `/api/v2/monitor/health` responde 200 com o scheduler doente | O 200 só diz que a chamada deu certo | Leia o `status` de cada componente; o scheduler fica `unhealthy` após 30 s sem sinal |
| `No alive jobs found`, saída 1, scheduler saudável | `$HOSTNAME` expande no bash da sua máquina | `docker compose exec airflow-scheduler bash -c 'airflow jobs check --job-type SchedulerJob --hostname "$HOSTNAME"'` |

**O equívoco comum**

Vigiar pelo código HTTP. Um 200 não é um scheduler vivo.

Na dúvida, volte ao registro de carga: quando rodou, se foi agendada ou manual, quantas linhas.
É nele que aparecem a contagem dobrada, o zero e a contagem fora de ordem, desde que alguém, ou
uma checagem, olhe para ele. A receita dobrada apareceu na consulta do gold.

#### 17. Plano de continuidade

"Terminei. E agora, estudo o quê?" O plano de continuidade é o próximo passo de cada perfil, ligado ao que vem depois na trilha.

##### 17.1 O próximo passo por perfil

| Se você | Próximo passo |
|---|---|
| quer só entender do que se trata | Guarde a frase guia: o orquestrador não é o código de limpeza, é quem roda o código. |
| gerencia e quer decidir | Leve ao time as perguntas do capítulo 11. |
| está começando na área | Refaça o laboratório sozinho. Se o medo é o SQL da silver, isso é Modelagem e transformação. |
| já trabalha com dados | Aprofunde o Airflow no laboratório desta apostila e, depois, no módulo da trilha dedicado a ele. Se o que falta é o SQL da silver, isso é Modelagem e transformação. |
| é engenheiro e mira o próximo nível | Produção e a versão 3.4, na seção 17.3. |

Para quem está começando: se o laboratório não subiu, volte à preparação do ambiente, no capítulo 13, antes de seguir. No Windows, o pré-requisito é espaço livre no disco físico onde mora o WSL ou o Docker Desktop, em geral o C:, e não o que o `df` do Linux mostra.

##### 17.2 O medo da silver é assunto de Modelagem e transformação

"E o SQL da silver, quem me ensina?" O gerente de TI do nosso caso tinha esse medo: nulos, colunas redundantes, datas, fuso, histórico do preço. Nada disso é orquestração. A Dag roda esse SQL na ordem, com a nova tentativa e o alerta que você configurar. Escrever o SQL, isso é Modelagem e transformação.

Guardar cada versão do preço, com início e fim de vigência, é a técnica chamada SCD tipo 2; o snapshot do dbt a implementa com `dbt_valid_from` e `dbt_valid_to`. Cabe à orquestração rodar a foto todo dia, no horário e no fuso certos, com alerta, porque o que mudou entre duas fotos não volta. O CDC, que lê o log do banco, é assunto de ingestão, não de orquestração.

O equívoco comum é achar que precisa dominar a silver antes de orquestrar. Escreva o SQL à mão. Quando a entrega virar recorrente, ele entra na Dag.

##### 17.3 Para o engenheiro: produção e a versão 3.4

"O laboratório vai para produção?" Não. O compose oficial serve para aprender, sem garantias de segurança de produção. Para produção, a documentação recomenda Kubernetes com o pacote oficial de instalação, o Helm chart.

A 3.4.0 está em versão candidata (release candidate) desde 2026-10-28, prevista para 2026-11-02. O que muda:

- Exige Python 3.11 ou mais. No Ubuntu 22.04, o `python3` padrão é o 3.10.6. Quem instala por pip ou uv num 22.04 sem trocar o Python fica na 3.3; pelo Docker, como no laboratório, o problema não existe.
- O psycopg3 vira o driver padrão do banco de metadados; o compose oficial troca `postgresql+psycopg2` por `postgresql+psycopg`. O `docker-compose.yaml` do laboratório (imagem 3.3.2) usa psycopg2. Por isso o compose tem de ser da mesma versão da imagem: ao subir para a 3.4, troque os dois juntos. Não verificado: o laboratório não foi testado na 3.4.
- Dag disparada por um dado (asset) cria uma execução por evento; `batch_asset_events=True` mantém o lote.
- Chega, experimental, a escrita da Dag inteira fora do Python, em TypeScript, Go, Java e YAML nativo; tarefas em Java e Go já existiam, experimentais, desde a 3.3.

O equívoco comum é trocar a tag da imagem e descobrir a mudança em produção. Leia as notas, teste num ambiente descartável e leve ao time a data da troca.

#### 18. Glossário

Leu um termo e travou? Volte aqui. Cada termo tem uma frase, na mesma grafia usada nos capítulos. Termo em inglês aparece na grafia usada nos capítulos e, quando o texto usa tradução, ela vem junto.

Um exemplo do formato: idempotência quer dizer que rodar de novo dá o mesmo resultado de rodar uma vez. Se a carga de ontem roda duas vezes e a contagem dobra, ela não é idempotente.

##### O que é orquestrar

- **Orquestração**: executar um fluxo definido de passos, na ordem, com estado, nova tentativa e histórico.
- **Orquestrador**: quem roda o código na ordem certa e guarda o estado; não é o código de limpeza.
- **Agendador**: ferramenta que dispara comandos por horário (alguns também por evento do sistema), como o cron e o Agendador de Tarefas do Windows; não guarda o estado do fluxo nem resolve a ordem entre passos.
- **cron**: agendador do Unix, uma lista de comandos com horários; dispara e esquece.

##### Peças do Airflow

- **Dag**: grafo dirigido sem ciclo de tarefas; no Airflow, a definição do fluxo.
- **Tarefa (task)**: um passo da Dag, criado a partir de um operador, de um sensor ou de uma função Python com `@task`.
- **Operador**: modelo de tarefa, como o que executa SQL num banco.
- **Sensor**: operador que só espera uma condição externa.
- **Dependência**: aresta do grafo; por padrão, uma tarefa só começa depois que todas as anteriores terminam com sucesso.
- **Pool**: limite de tarefas simultâneas contra um mesmo sistema.
- **Scheduler**: componente do Airflow que decide o que roda e quando, respeitando as dependências da Dag; não é o agendador do degrau 2.
- **Dag processor**: componente do Airflow 3 que lê os arquivos das Dags.
- **Executor**: o mecanismo que roda as tarefas, configurado no scheduler e rodando dentro do processo dele; o padrão, `LocalExecutor`, roda cada tarefa como subprocesso do scheduler.
- **Banco de metadados**: onde o orquestrador guarda execuções, estados e histórico.
- **XCom**: canal do Airflow para passar pouco dado entre tarefas; nunca a tabela inteira.
- **Connection**: credencial e endereço de um sistema externo, guardados fora do código da Dag.

##### Execução e tempo

- **Execução da Dag (Dag run)**: uma instância da Dag no tempo, com estado próprio.
- **Estado**: situação de cada tarefa numa execução, como na fila, rodando, sucesso, falha ou aguardando nova tentativa.
- **Disparo por horário**: execução criada pela agenda da Dag.
- **Disparo por evento**: execução criada quando uma tarefa atualiza um dado (asset) e termina com sucesso; desde o Airflow 3.0 também há disparo por evento externo.
- **Data lógica**: a data a que uma execução se refere; nem sempre igual ao momento em que roda.
- **Timetable**: a regra que transforma a agenda em execuções e, quando houver, janelas de dados.
- **Janela de dados**: o intervalo de tempo que uma execução deve processar; no Airflow 3, uma agenda em cron tem janela de duração zero, a menos que você declare `interval=` no timetable.
- **UTC**: tempo universal coordenado; fuso padrão do Airflow e três horas à frente de Brasília.
- **Catchup**: criar sozinho as execuções perdidas desde a data de início; desligado por padrão no Airflow 3.
- **Reprocessamento de datas passadas (backfill)**: criar execuções para dias que já passaram.

##### Quando dá errado

- **Nova tentativa (retry)**: rodar de novo uma tarefa que falhou; no Airflow 3.3.2, o padrão é zero tentativas, e você liga na Dag ou na tarefa.
- **Backoff**: esperar cada vez mais entre uma tentativa e outra.
- **Jitter**: um sorteio na espera entre tentativas, para elas não chegarem juntas.
- **Alerta**: aviso a uma pessoa quando algo falha; no Airflow, por callback ou notifier.
- **Callback**: função que o Airflow chama quando o estado de uma tarefa muda, como `on_failure_callback`.
- **Notifier**: notificador pronto que entra no lugar da função de callback.
- **Tarefa vigia (watcher)**: tarefa a jusante de todas as outras, com `TriggerRule.ONE_FAILED`, para a execução não terminar verde com uma falha no meio.
- **Trabalho penoso (toil)**: trabalho manual, repetitivo, automatizável, tático, sem valor duradouro e que cresce junto com o serviço.
- **Falha silenciosa**: carga que termina com sucesso e não traz dado, ou traz dado errado.
- **Idempotência**: rodar de novo dá o mesmo resultado de rodar uma vez.
- **UPSERT**: inserir ou atualizar pela chave, numa operação só.
- **Registro de carga**: tabela com cada carga, dizendo quando rodou, se foi agendada ou manual e quantas linhas trouxe.

##### Dado e banco

- **Réplica só leitura**: cópia do banco de produção que aceita consulta e não aceita escrita.
- **Bronze, silver e gold**: camadas da arquitetura medalhão, com dado cru, validado e enriquecido, pronto para o negócio; prática recomendada, não obrigatória.
- **CDC**: captura de mudanças; leva cada alteração da origem para outro lugar. Ferramentas de replicação como o AWS DMS e o Debezium fazem isso lendo o log de transações do banco de origem.
- **SCD tipo 1**: sobrescrever o valor e perder o histórico.
- **SCD tipo 2**: guardar cada versão de um valor com início e fim de vigência.

O equívoco comum é decorar o glossário antes de rodar a primeira Dag. Vamos pelo caminho inverso: rode, veja o termo na tela e volte aqui para fixar.

#### Referências

De onde veio cada afirmação desta apostila? Daqui. Referência é a documentação oficial que você abre para conferir o que leu. Memória não conta como fonte, nem a nossa.

O Airflow muda rápido. Um exemplo: no Airflow 3 o catchup vem desligado, e material escrito antes dizia que vinha ligado. Outro: o `schedule_interval` do Airflow 2 foi removido no 3. Por isso cada linha abaixo traz URL e data de consulta. Se a data ficou velha, confira de novo antes de repetir a afirmação.

Vamos ver como usar esta lista na prática:

1. Achou uma afirmação na apostila que parece estranha? Procure o tema abaixo.
2. Abra a URL e confira se a doc ainda diz o mesmo.
3. Mudou? Avise o mentor. Conteúdo errado publicado como certo é pior que conteúdo ausente.

O equívoco comum é confiar no primeiro tutorial que aparece na busca. Tutorial escrito para o Airflow 2 pode ensinar padrões que o 3 removeu, como `schedule_interval`, SubDAG, SLA e `execution_date`.

##### Documentação oficial principal

Todas consultadas em 2026-10-29: Airflow na versão 3.3.2 e PostgreSQL na 16.

- Apresentação do Airflow. https://airflow.apache.org/docs/apache-airflow/3.3.2/index.html
- Conceitos centrais. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- Referência de configuração. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- Execução da Dag (Dag run) e catchup. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dag-run.html
- Reprocessamento de datas passadas (backfill). https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/backfill.html
- Boas práticas. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- Fuso horário. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timezone.html
- Timetable. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timetable.html
- Migração para o Airflow 3. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/upgrading_to_airflow3.html
- Notas de versão. https://airflow.apache.org/docs/apache-airflow/3.3.2/release_notes.html
- Docker Compose oficial. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/docker-compose/index.html
- UPSERT no PostgreSQL. https://www.postgresql.org/docs/16/sql-insert.html

#### Fontes verificadas (2026-10-29)

Uma linha por afirmação factual que sustenta os capítulos, agrupadas por fonte. A data de consulta de todas é 2026-10-29.

##### Apache Airflow 3.3.2

- O Airflow é uma plataforma para orquestrar fluxos em lote, com início e fim claros, disparados por tempo ou por evento. https://airflow.apache.org/docs/apache-airflow/3.3.2/index.html
- Fluxo como código traz versionamento, trabalho em equipe e teste; pela interface se dispara Dag, lê log, faz backfill e roda de novo só as tarefas que falharam. https://airflow.apache.org/docs/apache-airflow/3.3.2/index.html
- A seção "Why not Airflow?" diz que, para quem prefere clicar a programar, ele talvez não seja a melhor escolha. https://airflow.apache.org/docs/apache-airflow/3.3.2/index.html
- A Dag não se importa com o que acontece dentro das tarefas, só com como executá-las: ordem, tentativas, tempo limite. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dags.html ; https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- O termo vem do grafo dirigido acíclico, mas o sentido no Airflow foi além da estrutura de dados, e por isso a documentação adotou "Dag". https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dags.html
- A Dag define as dependências e, com elas, a ordem; por padrão, uma tarefa espera todas as anteriores terminarem com sucesso. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- Operadores e sensores são modelos, e chamá-los numa Dag cria uma tarefa; `@task` empacota uma função Python como tarefa. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- Sensor é o operador que só espera um evento externo. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- Peças de uma instalação: scheduler, Dag processor, API server e banco de metadados; o executor é propriedade de configuração do scheduler e roda dentro do processo dele. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/overview.html
- Passar o retorno de uma tarefa para outra define a dependência e leva o valor por XCom; decorators e `DAG` vêm de `airflow.sdk`, e os operadores Python, do provider standard. https://airflow.apache.org/docs/apache-airflow/3.3.2/tutorial/taskflow.html
- Caminho ideal de uma instância de tarefa (`none`, `scheduled`, `queued`, `running`, `success`) e os estados `up_for_retry` e `upstream_failed`, entre outros. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/tasks.html
- `AirflowFailException` marca a tarefa como falha e ignora as tentativas restantes; as políticas de nova tentativa decidem entre RETRY, FAIL e DEFAULT e não passam do máximo configurado. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/tasks.html
- Dag run é uma instância da Dag no tempo; o estado da execução vem das tarefas folha, e uma folha com `all_done` pode deixar a execução em sucesso com falha antes dela. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dag-run.html
- Catchup cria uma execução por intervalo não executado; limpar uma tarefa a faz rodar de novo, pela interface ou por `airflow tasks clear`. A mesma página ainda explica datas pelo modelo de intervalo e manda disparar com `-e`, o que não vale para a 3.3.2. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dag-run.html
- XCom serve para pouco dado, nunca para a tabela inteira ou um dataframe; é limpo a cada nova tentativa e não guarda estado entre tentativas. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/xcoms.html
- O `LocalExecutor` roda as tarefas como subprocessos do scheduler, limitados pelo `parallelism`; em contêiner isso pode parecer memória alta do scheduler, e a documentação manda ajustar o `parallelism` ao limite do contêiner. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/executor/local.html
- Padrões de configuração: executor `LocalExecutor`, `parallelism` 32, `dags_are_paused_at_creation` True, `catchup_by_default` False e `default_timezone` UTC. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- O padrão do Airflow 3 é não tentar de novo (`default_task_retries` 0, ajustável na Dag ou na tarefa), e nenhuma tarefa tem tempo limite (`default_task_execution_timeout` vazio). https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- `create_cron_data_intervals` vem False, e a agenda cron vira `CronTriggerTimetable`. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- Sem limite, até 16 execuções da mesma Dag rodam juntas (`max_active_runs_per_dag`). https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- O Dag processor procura arquivos novos a cada 300 s (`refresh_interval`), e `min_file_process_interval` vale 30 s. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- O tempo limite padrão do sensor é de 604800 s, 7 dias (`[sensors] default_timeout`), e `[operators] default_deferrable` vem false. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- Desde a 3.2.0, `dag_version_inflation_check_level` vem em `warning` e avisa sobre versões infladas da Dag. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html
- A opção `rerun_with_latest_version` está na referência de configuração e chegou na 3.3.0. https://airflow.apache.org/docs/apache-airflow/3.3.2/configurations-ref.html ; https://airflow.apache.org/docs/apache-airflow/3.3.2/release_notes.html
- O Airflow guarda datas em UTC por dentro e no banco, e `default_timezone` vem `utc`, o recomendado; mesmo num fuso só, é boa prática guardar dado em UTC. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timezone.html
- Data sem fuso recebe o fuso padrão, e o `start_date` deve levar fuso, criado com `pendulum`; cron com fuso segue o horário local. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timezone.html
- Templates entregam datas com fuso, sem converter para o horário local, e cabe à Dag tratar isso; a página diz, em dois trechos, que a interface mostra UTC. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timezone.html
- O timetable de disparo não tem janela de dados, e início e fim são iguais; com `interval=`, a janela tem essa duração e termina no disparo; com catchup desligado, os dias do período pausado não rodam. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/timetable.html
- Na migração para o 3, quem depende de `data_interval_start` e `data_interval_end` pode ligar `create_cron_data_intervals=True` antes do upgrade ou declarar `interval=`; mudar a configuração depois de existirem execuções no 3 pula uma execução agendada; a janela do disparo manual depende do timetable e do caminho do disparo. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/upgrading_to_airflow3.html
- `ds` é a data lógica da execução no formato AAAA-MM-DD e só existe quando a execução tem data lógica. https://airflow.apache.org/docs/apache-airflow/3.3.2/templates-ref.html
- `start_date` dinâmico confunde o agendamento: no Airflow 3 ele gera versão nova da Dag a cada leitura do arquivo; a correção é data fixa. https://airflow.apache.org/docs/apache-airflow/3.3.2/faq.html
- O FAQ ainda explica `ds` pelo modelo de intervalo e diz que a agenda padrão é de um dia. https://airflow.apache.org/docs/apache-airflow/3.3.2/faq.html
- Uma Dag pode rodar quando uma tarefa atualiza um dado (asset), e o asset só é marcado como atualizado se a tarefa terminar com sucesso. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/asset-scheduling.html
- O disparo por evento externo existe desde a 3.0. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/event-scheduling.html
- Backfill cria execuções de datas passadas e não faz sentido sem agenda por tempo; com catchup ligado, o scheduler cria uma execução para cada intervalo não executado. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/backfill.html
- O backfill tem os comportamentos de reprocessamento `none`, `failed` e `completed`; execução ainda em running ou queued não ganha outra, qualquer que seja a opção; o `max_active_runs` do backfill vale à parte do da Dag. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/backfill.html
- O backfill tem ensaio com `--dry-run`, que imprime as datas consideradas. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/backfill.html
- Só um backfill fica aberto por Dag: um segundo pedido logo depois foi recusado com a mensagem "There can be only one running backfill per Dag". Executado em ambiente descartável, Airflow 3.3.2, 2026-10-29.
- `airflow backfill create` tem `--from-date` e `--to-date` como início e fim inclusivos, `--dry-run`, `--max-active-runs` e `--reprocess-behavior` com padrão `none`; `airflow dags trigger` aceita `-l/--logical-date`. https://airflow.apache.org/docs/apache-airflow/3.3.2/cli-and-env-variables-ref.html
- `airflow dags test` executa uma execução da Dag para uma data lógica. https://airflow.apache.org/docs/apache-airflow/3.3.2/cli-and-env-variables-ref.html
- Pacotes de Dag versionados (Git) e não versionados (local, S3, GCS); ao limpar, o padrão é rodar a versão original, e no backfill, a mais recente. https://airflow.apache.org/docs/apache-airflow/3.3.2/administration-and-deployment/dag-bundles.html
- A tarefa é tratada como transação, com o mesmo resultado a cada reexecução; INSERT numa reexecução pode duplicar linhas e dá lugar ao UPSERT. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- Gravar numa partição específica, com `data_interval_start` como partição, nunca o dado mais recente; `now()` fica fora de cálculo crítico. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- Não guardar arquivo no disco local entre tarefas, porque a seguinte pode rodar em outro servidor; dado grande vai para armazenamento remoto, com o caminho no XCom. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- Checagens dentro da própria Dag e tarefa vigia com `TriggerRule.ONE_FAILED`, a jusante de todas as outras. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- Nada de banco, rede ou cálculo pesado no topo do arquivo da Dag; `Variable.get` no topo e o template `{{ var.value.<nome> }}`; teste de carga com `python` e homologação parametrizada. https://airflow.apache.org/docs/apache-airflow/3.3.2/best-practices.html
- O alerta vem de cinco callbacks, que aceitam notifier no lugar da função; marcar estado pela interface ou pela linha de comando não dispara callback; erro de callback vai para o log do Dag processor, fora da interface por padrão. https://airflow.apache.org/docs/apache-airflow/3.3.2/administration-and-deployment/logging-monitoring/callbacks.html
- Deadline Alerts são novos na 3.1, devem ser tratados como experimentais e chamam um callback quando o prazo estoura. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/deadline-alerts.html
- O código HTTP de `/api/v2/monitor/health` não indica saúde; o campo `status` de cada componente indica, e o scheduler fica `unhealthy` depois de 30 s sem heartbeat. https://airflow.apache.org/docs/apache-airflow/3.3.2/administration-and-deployment/logging-monitoring/check-health.html
- Pool serve para limitar tarefas simultâneas contra um sistema frágil; o `default_pool` começa com 128 vagas. https://airflow.apache.org/docs/apache-airflow/3.3.2/administration-and-deployment/pools.html
- No modo poke o sensor ocupa a vaga o tempo todo; no reschedule, só enquanto confere. https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/sensors.html
- Tarefa adiada não ocupa vaga, e a instalação precisa de ao menos um processo triggerer. https://airflow.apache.org/docs/apache-airflow/3.3.2/authoring-and-scheduling/deferring.html
- Senha fica em Connection, fora do código da Dag, e a Connection pode vir por variável de ambiente `AIRFLOW_CONN_{CONN_ID}`. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/connection.html
- O mascaramento é acionado por Connection e Variable; XCom não é mascarado. https://airflow.apache.org/docs/apache-airflow/3.3.2/security/secrets/mask-sensitive-values.html
- O Airflow 3 removeu SubDAG, SLA e `execution_date`; o SLA foi substituído por Deadline Alerts. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/upgrading_to_airflow3.html
- O Dag processor precisa ser iniciado à parte, mesmo em ambiente local (`airflow dag-processor`), e o webserver virou API server (`airflow api-server`). https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/upgrading_to_airflow3.html
- Caminhos de import antigos estão marcados para remoção numa versão futura. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/upgrading_to_airflow3.html
- O Airflow 3.0 removeu `schedule_interval` e `timetable` em favor de `schedule`, cujo padrão passou a ser `None`, e `catchup_by_default` passou a False. https://airflow.apache.org/docs/apache-airflow/3.3.2/release_notes.html
- A partir da 3.0, execução manual ou disparo pela API sem data lógica fica com `logical_date=None` e sem janela de dados. https://airflow.apache.org/docs/apache-airflow/3.3.2/release_notes.html
- As políticas de nova tentativa chegaram no Airflow 3.3.0. https://airflow.apache.org/docs/apache-airflow/3.3.2/release_notes.html
- As notas da 3.3.2 registram que a 3.3.0 trouxe SDKs de tarefa em Java e Go, experimentais, com a Dag e o agendamento ainda em Python. https://raw.githubusercontent.com/apache/airflow/3.3.2/RELEASE_NOTES.rst
- A 3.3.2 é a versão estável, publicada no PyPI em 2026-09-17. https://pypi.org/pypi/apache-airflow/json
- A linha 3 está em manutenção, sem data de fim; a linha 2 está em fim de vida desde 2026-04-22, e versão em fim de vida não recebe correção nem suporte. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/supported-versions.html
- O Airflow recomenda no mínimo 4 GB de memória; no Windows roda só por WSL2 ou contêiner Linux; produção só é suportada em Linux. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/prerequisites.html
- No Windows é obrigatório usar o WSL2, com os arquivos na home do Linux, não na montagem do Windows. https://airflow.apache.org/docs/apache-airflow/3.3.2/start.html
- Na instalação por imagem Docker, montagem, banco, schema, monitoramento e dimensionamento ficam com o usuário; o serviço gerenciado é para quem prefere tê-lo gerenciado e aceita pagar por isso. https://airflow.apache.org/docs/apache-airflow/3.3.2/installation/index.html
- O SQLite nunca deve ser usado em produção. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/set-up-database.html
- O Docker Compose oficial é para aprendizado, sem garantias de segurança de produção; pede ao menos 4 GB de memória para o Docker, 8 GB o ideal, e Compose v2.14.0 ou mais novo; para produção, a recomendação é Kubernetes com o Helm chart oficial. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/docker-compose/index.html
- No Linux, `AIRFLOW_UID=$(id -u)` vai no `.env`, senão os arquivos ficam com dono root; o valor 50000 serve para outros sistemas. https://airflow.apache.org/docs/apache-airflow/3.3.2/howto/docker-compose/index.html
- O compose oficial da 3.3.2 avisa, sem bloquear, abaixo de 10 GB de disco livre, 4000 MiB de memória ou 2 CPUs; checa o servidor de API por `/api/v2/monitor/health`; e usa `postgresql+psycopg2` na conexão do banco de metadados. https://airflow.apache.org/docs/apache-airflow/3.3.2/docker-compose.yaml
- A página da imagem Docker do Airflow cita Python 3.12 como padrão. https://airflow.apache.org/docs/docker-stack/index.html
- Como `"0 0 * * *"`, `"@daily"`, `"@hourly"` e `timedelta` viram timetable na 3.3.2. https://github.com/apache/airflow/blob/3.3.2/task-sdk/src/airflow/sdk/definitions/dag.py
- Os rótulos da interface para o reprocessamento (Missing Runs para `none`, Missing and Errored Runs para `failed`, All Runs para `completed`), que a página de backfill não declara, estão no formulário de backfill da 3.3.2. https://github.com/apache/airflow/blob/3.3.2/airflow-core/src/airflow/ui/src/constants/reprocessBehaviourParams.ts
- O botão Acionar preenche a data lógica com o instante atual e oferece janela inferida ou manual; os rótulos em português "Acionar", "Inferido da Data Lógica e do Timetable" e "Especificar Manualmente" estão no arquivo de tradução. https://github.com/apache/airflow/blob/3.3.2/airflow-core/src/airflow/ui/src/components/TriggerDag/TriggerDAGForm.tsx ; https://github.com/apache/airflow/blob/3.3.2/airflow-core/src/airflow/ui/public/i18n/locales/pt/components.json
- A interface toma o fuso padrão do navegador e guarda a escolha no armazenamento local; o seletor junta UTC, o fuso detectado e a lista IANA. https://github.com/apache/airflow/blob/3.3.2/airflow-core/src/airflow/ui/src/context/timezone/TimezoneProvider.tsx ; https://github.com/apache/airflow/blob/3.3.2/airflow-core/src/airflow/ui/src/layouts/Nav/TimezoneSelector.tsx

##### Providers e Task SDK do Airflow

Pacotes com versão própria, separada da versão do Airflow.

- `catchup` desligado por padrão e o significado de `max_active_runs` no `DAG`. https://airflow.apache.org/docs/task-sdk/stable/api.html
- O `SQLExecuteQueryOperator` do provider common-sql é o caminho atual para rodar SQL a partir da Dag e aceita `parameters` e `split_statements`, desligado por padrão. https://airflow.apache.org/docs/apache-airflow-providers-common-sql/stable/operators.html ; https://airflow.apache.org/docs/apache-airflow-providers-postgres/stable/changelog.html
- `PostgresOperator` saiu no provider postgres 6.0.0, e `MsSqlOperator`, no microsoft-mssql 4.0.0, os dois com indicação do `SQLExecuteQueryOperator`. https://airflow.apache.org/docs/apache-airflow-providers-postgres/stable/changelog.html ; https://airflow.apache.org/docs/apache-airflow-providers-microsoft-mssql/stable/changelog.html
- `SQLColumnCheckOperator`, `SQLTableCheckOperator`, `SQLValueCheckOperator` e `SQLThresholdCheckOperator`, com limites que podem ser número ou consulta SQL; provider common-sql na versão 2.4.0. https://airflow.apache.org/docs/apache-airflow-providers-common-sql/stable/operators.html
- O provider Amazon tem operadores para criar, iniciar, parar e apagar tarefas do DMS e um sensor que espera a tarefa; provider na versão 9.39.0. https://airflow.apache.org/docs/apache-airflow-providers-amazon/stable/operators/dms.html

##### Apache Airflow 3.4.0, versão candidata

- A 3.4.0 teve rc1 publicada no PyPI em 2026-10-28, sem versão final publicada na data da consulta. https://pypi.org/pypi/apache-airflow/json
- As notas da rc1 datam a 3.4.0 em 2026-11-02, data prevista; exigem Python 3.11 ou mais; tornam o psycopg3 o driver padrão do banco de metadados; criam uma execução por evento em Dags disparadas por asset, com `batch_asset_events=True` para manter o lote. https://raw.githubusercontent.com/apache/airflow/3.4.0rc1/RELEASE_NOTES.rst
- As notas da rc1 trazem, experimentais, a escrita da Dag inteira fora do Python, pelos SDKs de TypeScript, Go e Java e pelo formato YAML nativo de Dag. https://raw.githubusercontent.com/apache/airflow/3.4.0rc1/RELEASE_NOTES.rst
- O compose oficial da rc1 usa `postgresql+psycopg` na conexão do banco de metadados. https://raw.githubusercontent.com/apache/airflow/3.4.0rc1/airflow-core/docs/howto/docker-compose/docker-compose.yaml

##### PostgreSQL 16

- `ON CONFLICT DO UPDATE` garante resultado atômico de inserir ou atualizar, mesmo com concorrência, desde que não haja erro independente; também chamado de UPSERT. https://www.postgresql.org/docs/16/sql-insert.html
- Conexões a um PostgreSQL em hot standby são estritamente só leitura; nem tabelas temporárias podem ser gravadas. https://www.postgresql.org/docs/16/hot-standby.html
- Servidor estrangeiro guarda os dados de conexão que o foreign-data wrapper usa para acessar um recurso externo. https://www.postgresql.org/docs/16/sql-createserver.html
- O `postgres_fdw` acessa dados guardados em servidores PostgreSQL externos e exige senha, ou credencial GSSAPI delegada, para usuário comum. https://www.postgresql.org/docs/16/postgres-fdw.html
- `AT TIME ZONE` sobre horário sem fuso interpreta o valor naquele fuso e devolve `timestamptz`. https://www.postgresql.org/docs/16/functions-datetime.html

##### Microsoft Learn

- Por padrão, a VM do WSL 2 recebe 50% da memória do Windows e swap de 25%, arredondado para o GB acima; `.wslconfig` fica em `%UserProfile%` e só vale depois que a VM para; `localhostForwarding` é `true` por padrão. https://learn.microsoft.com/en-us/windows/wsl/wsl-config
- No WSL, a distribuição desliga depois de 15 segundos ociosa, e o usuário padrão recebe UID 1000 na primeira instalação. https://learn.microsoft.com/en-us/windows/wsl/wsl-config
- O disco de cada distribuição do WSL 2 é um arquivo `ext4.vhdx` no disco do Windows, e o `df` dentro do Linux mostra o máximo alocado ao disco virtual, não o espaço livre do disco físico. https://learn.microsoft.com/en-us/windows/wsl/disk-space
- `wsl --install` roda em PowerShell de administrador, exige Windows 10 versão 2004 (build 19041) ou Windows 11, instala o Ubuntu em WSL 2 e pede reinício. https://learn.microsoft.com/en-us/windows/wsl/install
- Usuário e senha do Linux são criados no primeiro uso e não têm relação com o usuário do Windows. https://learn.microsoft.com/en-us/windows/wsl/setup/environment
- Para comandos Linux, guarde os arquivos no sistema de arquivos do WSL. https://learn.microsoft.com/en-us/windows/wsl/filesystems
- O Agendador de Tarefas do Windows dispara por horário e por evento, tenta de novo em falha com contagem e intervalo, e deixa desligada por padrão a execução de horário perdido, que vale só para tarefas por horário com fim definido ou repetição infinita. https://learn.microsoft.com/en-us/windows/win32/taskschd/task-triggers ; https://learn.microsoft.com/en-us/windows/win32/taskschd/taskschedulerschema-restartonfailure-settingstype-element ; https://learn.microsoft.com/en-us/windows/win32/taskschd/tasksettings-restartcount ; https://learn.microsoft.com/en-us/windows/win32/taskschd/tasksettings-startwhenavailable
- `schtasks /create /sc` é o equivalente de linha de comando ao cron. https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/schtasks-create
- O SQL Server Agent roda trabalhos de um ou mais passos, por agenda, alerta ou sob demanda, avisa por e-mail via Database Mail e vem desligado na instalação. https://learn.microsoft.com/en-us/ssms/agent/sql-server-agent
- O SQL Server Agent não existe na edição Express; grupos de disponibilidade Always On completos são da Enterprise, e os básicos, da Standard. https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2022 ; https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2025
- Na réplica legível do SQL Server, as consultas usam isolamento por snapshot, sem disputa entre leitura e escrita; não se grava nos bancos secundários, mas sim em outros bancos da mesma instância. https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/active-secondaries-readable-secondary-replicas-always-on-availability-groups
- O grupo de disponibilidade básico não permite leitura na réplica secundária. https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/basic-availability-groups-always-on-availability-groups
- A atualização agendada do Power BI permite oito por dia na capacidade compartilhada e até 48 em Premium, PPU ou Fabric; fonte na sua rede exige gateway; a falha vai por e-mail ao dono. https://learn.microsoft.com/en-us/power-bi/connect-data/refresh-data
- O Power BI desativa a agenda após quatro falhas seguidas e inicia a atualização em até 15 minutos do horário, com atraso possível de até uma hora. https://learn.microsoft.com/en-us/power-bi/connect-data/refresh-scheduled-refresh
- O Airflow do Azure Data Factory não cria instância nova desde 2026-01-01. https://learn.microsoft.com/en-us/azure/data-factory/concepts-workflow-orchestration-manager
- O Airflow do Fabric suporta só a versão 2.10.5 e não aceita rede privada nem rede virtual. https://learn.microsoft.com/en-us/fabric/data-factory/apache-airflow-jobs-concepts

##### Docker

- O `docker info` expõe `MemTotal`, o total de memória física disponível no host do Docker, em bytes. https://docs.docker.com/reference/cli/docker/system/info/ ; https://docs.docker.com/reference/api/engine/version/v1.51.yaml
- Requisitos do Docker Desktop no Windows com WSL 2: Windows 10 22H2 ou Windows 11 23H2 nas edições Enterprise, Pro ou Education, 8 GB de RAM e virtualização ligada. https://docs.docker.com/desktop/setup/install/windows-install/
- O Docker Desktop é grátis para empresas com menos de 250 funcionários e menos de 10 milhões de dólares de receita anual, entre outros usos; organização maior e governo exigem assinatura. https://docs.docker.com/subscription/desktop-license/
- Arquivos montados em contêiner rendem muito mais no sistema de arquivos do Linux, por isso evite `/mnt/c`; o WSL mínimo é o 2.1.5, e WSL antigo pode fazer o `vmmem.exe` consumir toda a memória. https://docs.docker.com/desktop/features/wsl/best-practices/
- Porta publicada pelo Docker Desktop pode ser restrita a `127.0.0.1`. https://docs.docker.com/desktop/features/networking/
- Nos perfis do Compose, serviço citado na linha de comando roda sem ativar o perfil. https://docs.docker.com/compose/how-tos/profiles/
- A imagem `apache/airflow:3.3.2-python3.13` está publicada e ativa no Docker Hub, e a `apache/airflow:3.3.2` tem o mesmo digest. https://hub.docker.com/v2/repositories/apache/airflow/tags/3.3.2-python3.13 ; https://hub.docker.com/v2/repositories/apache/airflow/tags?name=3.3.2

##### Git

- Com `core.autocrlf=true`, o Git converte LF em CRLF no checkout, e `.gitattributes` com `eol=lf` força LF; `*.sh text eol=lf` mantém LF na cópia de trabalho (Git 2.56.0). https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration ; https://git-scm.com/docs/gitattributes

##### SRE do Google

- O cron é uma lista de comandos com horários, sem dependência entre eles nem nova tentativa, e dispara e esquece. https://pubs.opengroup.org/onlinepubs/9799919799/utilities/crontab.html ; https://sre.google/sre-book/distributed-periodic-scheduling/
- Pular uma execução é preferível a dobrar, porque a pulada se recupera e a dobrada às vezes não; o dono deve acompanhar o efeito da rotina. https://sre.google/sre-book/distributed-periodic-scheduling/
- O pipeline periódico fica frágil quando o volume cresce, e com intervalo curto as execuções se empilham. https://sre.google/sre-book/data-processing-pipelines/
- Definição de toil. https://sre.google/sre-book/eliminating-toil/
- Não convém automatizar todo componente; automação sem critério cria tantos problemas quanto resolve. https://sre.google/sre-book/automation-at-google/
- Agendas legíveis concentram tarefas na hora cheia e à meia-noite; a correção foi um horário espalhado de forma determinística pelo hash do `dag_id`. https://shopify.engineering/lessons-learned-apache-airflow-scale ; https://sre.google/sre-book/distributed-periodic-scheduling/

##### RFC 9110

- Um método é idempotente quando várias requisições idênticas têm o mesmo efeito de uma só, e o cliente não deve repetir automaticamente uma requisição não idempotente. A RFC trata de HTTP; a aplicação a cargas de dados é extrapolação didática. https://www.rfc-editor.org/rfc/rfc9110.html#section-9.2.2

##### AWS

- O AWS DMS migra dados uma vez ou replica as mudanças contínuas para manter origem e destino em sincronia. https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html
- No DMS, replicação contínua e CDC são o mesmo processo, que lê os logs do banco de origem e não é replicação em tempo real. https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Task.CDC.html
- Novas tentativas são egoístas: pedem espera crescente (backoff) exponencial com teto, variação aleatória (jitter) e limite no número de tentativas; API com efeito colateral só é segura de repetir se for idempotente. Artigo de 2019-12-05. https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- O MWAA `mw1.micro` comporta até 25 Dags e 3 tarefas simultâneas, sem autoescala. https://docs.aws.amazon.com/mwaa/latest/userguide/environment-class.html
- O MWAA oferece até a 3.3.1, disponível desde 2026-09-01, e a 2.11.2, disponível desde julho de 2026; só troca versão menor; o suporte é de ao menos 12 meses por versão, com aviso de 180 dias. https://docs.aws.amazon.com/mwaa/latest/userguide/airflow-versions.html
- O MWAA Serverless cobra pelo tempo de tarefa, usa definição em YAML com operadores da AWS e não dá acesso direto à interface do Airflow; operador próprio pede o MWAA provisionado. https://docs.aws.amazon.com/mwaa/latest/mwaa-serverless-userguide/what-is-mwaa-serverless.html
- Preço de tabela público: a máquina de 8 GB e 2 vCPU do Lightsail, Linux com IPv4, custa US$ 0,05913 por hora em us-east-1 e sa-east-1. https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonLightsail/current/us-east-1/index.json ; https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonLightsail/current/sa-east-1/index.json
- Preço de tabela público: o MWAA `mw1.micro` custa US$ 0,29 por hora em us-east-1 e cerca de US$ 0,4986 em sa-east-1; o MWAA Serverless custa US$ 0,08 por hora de tarefa em us-east-1 e US$ 0,104 em sa-east-1. https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonMWAA/current/us-east-1/index.json ; https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonMWAA/current/sa-east-1/index.json

##### Google Cloud

- Em 2026-04-15, o Google anunciou que o Cloud Composer está se tornando o Managed Service for Apache Airflow. https://docs.cloud.google.com/composer/docs/release-notes
- A imagem mais nova traz o Airflow 3.3.1, e a imagem padrão é a 2.11.1. https://docs.cloud.google.com/composer/docs/composer-versions
- A geração 3 custa US$ 0,06 por DCU-hora em us-central1; a DCU (Data Compute Unit) é uma unidade abstrata de medida dos recursos de computação alocados ao ambiente. https://cloud.google.com/composer/pricing

##### dbt

- O dbt transforma dado que já está no banco a partir de consultas SELECT, cria tabelas e views e resolve a ordem entre os modelos, com um DAG próprio. https://docs.getdbt.com/docs/introduction
- Quem decide quando o dbt roda é a plataforma do próprio dbt ou uma ferramenta externa, como o Airflow. https://docs.getdbt.com/docs/deploy/deployments ; https://docs.getdbt.com/docs/deploy/deployment-tools
- Snapshots do dbt implementam SCD tipo 2 com `dbt_valid_from` e `dbt_valid_to`; a estratégia `check` usa o horário corrente sem `updated_at`; snapshots não podem ser reconstruídos, com sugestão de schema separado; rodam em agenda, entre de hora em hora e diariamente. https://docs.getdbt.com/docs/build/snapshots
- Snapshot é captura de mudanças em lote: a cada execução, o dbt compara a origem com o último snapshot e não recupera mudanças sobrescritas entre duas execuções. https://docs.getdbt.com/best-practices/how-we-handle-cdc/1-intro ; https://docs.getdbt.com/best-practices/how-we-handle-cdc/2-choosing-incremental-or-snapshots

##### Kimball

- SCD tipo 1 sobrescreve e perde o histórico. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-1/
- SCD tipo 2 guarda cada versão numa linha nova, com início e fim de vigência e indicador de linha atual. https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/type-2/

##### Debezium

- O Debezium grava as mudanças de linha de cada tabela num fluxo ordenado de eventos; documentação estável 3.7. https://debezium.io/documentation/reference/stable/index.html ; https://debezium.io/documentation/faq/
- CDC lê o log de transações do banco de origem e leva cada mudança adiante. https://debezium.io/documentation/reference/stable/index.html ; https://debezium.io/documentation/reference/stable/features.html

##### Outras fontes primárias

- Orquestrar é executar um fluxo definido: primeiro A, depois B, depois C; a frase aparece onde a documentação diz que o Kubernetes não é só um sistema de orquestração. https://kubernetes.io/docs/concepts/overview/
- Os cinco campos de horário do crontab são minuto, hora, dia do mês, mês e dia da semana, e a única reação a erro descrita é mandar por e-mail a saída não redirecionada. https://pubs.opengroup.org/onlinepubs/9799919799/utilities/crontab.html
- No cronie, `CRON_TZ` define o fuso da tabela. https://man7.org/linux/man-pages/man5/crontab.5.html
- No pacote `cron` do Debian, o daemon roda num fuso definido e não há fuso por usuário. https://manpages.debian.org/trixie/cron/crontab.5.en.html
- `flock -n` falha em vez de esperar pela trava, com saída 1 por padrão. https://man7.org/linux/man-pages/man1/flock.1.html
- O `pg_cron` agenda dentro do Postgres, uma instância de cada trabalho por vez, com fuso padrão GMT e histórico numa tabela. https://github.com/citusdata/pg_cron
- O `numfmt --to=iec` escala por potências de 1024, então o "G" da saída é GiB. https://www.gnu.org/software/coreutils/manual/html_node/numfmt-invocation.html
- O Brasil não tem horário de verão desde 2019: a última regra Brazil com mudança na base de fusos é de fevereiro de 2019, e `America/Sao_Paulo` fica em -3:00, três horas atrás de UTC. https://data.iana.org/time-zones/tzdb/southamerica ; https://data.iana.org/time-zones/tzdb/version
- O psycopg 3 não executa várias instruções com parâmetros num mesmo `execute()`. https://www.psycopg.org/psycopg3/docs/basic/from_pg2.html
- O `python3` padrão do Ubuntu 22.04 é o 3.10.6. https://launchpad.net/ubuntu/+source/python3-defaults
- Um grafo dirigido acíclico é um grafo dirigido sem ciclos dirigidos. https://en.wikipedia.org/wiki/Directed_acyclic_graph
- O Luigi cuida de resolução de dependências, gestão do fluxo, visualização e tratamento de falhas, e não substitui os motores de processamento. https://luigi.readthedocs.io/en/stable/
- O Prefect promete rastreamento de estado, tratamento de falha e monitoramento. https://docs.prefect.io/v3/get-started
- As etapas do ciclo de vida são gerar, armazenar, ingerir, transformar e servir, e orquestração está entre as seis correntes subjacentes. Texto de Joe Reis de 2026-07-27. https://joereis.substack.com/p/the-data-engineering-lifecycle-and
- Seguir a arquitetura medalhão é prática recomendada, não requisito; bronze recebe o dado cru, silver o validado, gold o enriquecido. https://docs.databricks.com/aws/en/lakehouse/medallion
- Padrões Fast Metadata Cleaner, Data Overwrite, Merger, Stateful Merger e Keyed Idempotency, no repositório de código do livro. https://github.com/bartosz25/data-engineering-design-patterns-book
- Backup com `pg_dump` 9.2 contra PostgreSQL 9.6, e-mails de erro do cron rejeitados por falta de DMARC e falha descoberta só na hora de restaurar. https://about.gitlab.com/blog/postmortem-of-database-outage-of-january-31/
- Na Astronomer, a versão do Airflow 3.3 tem manutenção até julho de 2028, e a do 2.11, até abril de 2027. https://www.astronomer.io/docs/runtime/runtime-version-lifecycle-policy

##### Saídas capturadas em ambiente descartável

Nível 3: executadas em 2026-10-29, com a saída capturada, em Linux nativo, salvo onde a linha diz
outra coisa. Versões: Airflow 3.3.2 nas imagens `apache/airflow:3.3.2` e
`apache/airflow:3.3.2-python3.13`, que têm o mesmo digest (Python 3.13.15); PostgreSQL 16.15
(`postgres:16.15-alpine`); Docker Engine 28.3.3 e Compose 2.39.1. Dados sintéticos. Os arquivos de
Dag e de compose passaram no validador (nível 2): `ruff check` e `ruff format --check`, com ruff
0.12.12, e `docker compose config -q`. O comportamento do backfill descrito nos capítulos, como as
execuções simultâneas e a recusa do segundo backfill, vem destas saídas, não da documentação.

- Máquina: `docker compose version` respondeu `Docker Compose version v2.39.1`, e o `numfmt` da
  memória do Docker deu `31G`; a imagem do Airflow ocupa 2,33 GB em disco e não traz o provider do
  SQL Server.
- Ambiente principal: saudável em cerca de 1 min 21 s a 1 min 27 s na primeira subida e 53 s nas
  seguintes; contêineres com cerca de 0,7 GiB ociosos e pico de 1,1 GiB; cenário completo sob teto
  rígido de 1,8 GiB, sem swap, e saudável em 91 s com duas CPUs.
- Windows 11 (versão 10.0.26200) com WSL 2.7.13.0 e Docker Engine dentro do Ubuntu: subida em 41 a
  42 s; registro de carga igual ao do Linux; contêineres somando de 1,1 a 1,3 GiB; VM do WSL em
  9,2 GB e memória livre do Windows perto de 2 GB no pior momento; `df` com cerca de 205 GiB livres
  no disco virtual enquanto o C: tinha cerca de 2,3 GiB; `AIRFLOW_UID` 50000 com
  `Permission denied`; leitura de arquivo de 120 a 170 vezes mais lenta em `/mnt/c`, com a opção
  `metadata` ligada; Dag nova gravada pelo caminho `\\wsl.localhost` visível em cerca de 29 s; `.sh`
  com LF no Git do Ubuntu; `Get-PSDrive` com o espaço livre do C:, em bytes.
- Fim de linha: `.sh` com CRLF falhou com `bash\r` e saída 127, sem criar o `.env`; o script de
  inicialização do Postgres com CRLF falhou com `bad interpreter`, e a subida seguinte deixou o
  Postgres pronto sem a base `loja`.
- Degraus lado a lado: script à mão com cerca de 3 s por dia, contando a subida do contêiner, e
  primeira tentativa desfeita por um comentário com ponto e vírgula; cron do busybox na imagem
  `python:3.13.15-alpine3.24`, na casa de 5 MiB, com o erro da réplica derrubada só num arquivo de
  log do contêiner, sem nova tentativa nem linha no registro de carga, e relógio em UTC (16:38 em
  UTC às 13:38 de Brasília); degraus 1 e 2 na casa de 34 MiB de memória, com imagem de 72,7 MB;
  Airflow com LocalExecutor subindo em 1 min 17 s, em quatro contêineres, na casa de 680 MiB logo
  depois de subir e de 0,86 GiB depois dos experimentos.
- `flock -n` com duas execuções sobrepostas: a segunda saiu com 1, e a terceira rodou depois de a
  trava ser liberada; util-linux 2.39.3.
- Réplica só leitura: o papel `replica_leitura`, criado pelo script de inicialização com a senha
  passada ao psql por `-v`, aceita `BEGIN READ WRITE` apesar do `default_transaction_read_only`, e
  só o GRANT apenas de SELECT barra a escrita, com `permission denied for table pedidos`; a imagem
  oficial deixa `127.0.0.1` entrar pela regra `trust`, e o `postgres_fdw` de usuário comum por esse
  endereço falha com "Non-superuser cannot connect if the server does not request a password or use
  GSSAPI with delegated credentials".
- Mesmo SQL, outro executor: o `silver_pedidos.sql` rodado à mão e pela Dag `loja_idempotente` deu
  4 pedidos e 430,90 no gold do dia 20; o registro de carga mostrou os mesmos números à mão e em
  dois reprocessos pela Dag, com o executor `airflow:backfill`.
- Airflow 3 na prática: `TypeError` com `schedule_interval`, `ModuleNotFoundError` nos imports
  antigos e o import de `airflow.decorators` ainda funcionando; Dags nascendo com `is_paused` em
  `True`; `No data found` em `airflow dags list-import-errors`; Dag mínima `ola_orquestracao` em
  `success`, com `Total do dia: 245.5` no log; `airflow dags test` da Dag mínima em cerca de 33 s,
  com SQLite; `docker compose down --volumes --remove-orphans` removendo o volume do banco e a rede
  do laboratório.
- Idempotência: a versão que apaga e regrava o dia ficou em 4 linhas e 430,90 a cada reexecução; o
  INSERT sem chave, sobre o dia já carregado, levou a 8 linhas e 861,80, depois a 12 e 1.292,70,
  com 3 cópias de cada pedido, sempre com sucesso, e a versão que apaga e regrava consertou o dia;
  na tabela de rascunho, sem chave, 3 linhas viraram 6, com chave primária a segunda carga falhou
  com `duplicate key value violates unique constraint`, e com `ON CONFLICT DO UPDATE` ficaram 3.
- Nova tentativa, reprocesso e limpeza, com a queda simulada de propósito: na versão ingênua, a
  nova tentativa deixou o gold em 8 pedidos e 861,80, com `attempt=1.log` e `attempt=2.log`; o
  reprocesso de três dias, rodado duas vezes, levou 430,90, 111,90 e 293,30 a 861,80, 223,80 e
  586,60; a limpeza da tarefa do bronze e das seguintes levou o dia de 111,90 a 223,80, com o
  efeito capturado e o comando transcrito à mão. Na versão idempotente, nova tentativa e
  reprocessos mantiveram os números.
- Datas: data lógica, janela e `ds` por timetable e por caminho de disparo (CLI, API e botão
  Acionar); partição gravada por disparo manual na CLI e na API; `UndefinedError` em `{{ ds }}` no
  disparo sem data lógica; ensaio com limites em 00:00 UTC listando só `2026-10-22 09:00:00+00:00`;
  três execuções do reprocesso começando com menos de 2 milissegundos de diferença numa Dag com
  `max_active_runs=1`, e o reprocesso registrado com limite 10; segundo reprocesso recusado com
  `AlreadyRunningBackfill` ("There can be only one running backfill per Dag"); despausar com
  catchup desligado criando só a execução mais recente; execução das 6h de Brasília com a data
  `2026-10-29T09:00:00+00:00`.
- Fuso: cron `"0 0 * * *"` sem fuso disparando às 21h de Brasília; `ds=2026-10-29` na execução das
  22h de Brasília do dia 28; janela diária em UTC lendo dois atendimentos do dia local anterior e
  perdendo o das 21h30; janela em Brasília lendo o dia local; pedido das 21h30 de 20/10 gravado
  como 00:30 UTC de 21/10 e contado no dia 20 da gold; interface com 29/10 no identificador e
  28/10 21:00 na coluna Executar Depois; `-03:00` para `America/Sao_Paulo` em janeiro e outubro de
  2026; `airflow config get-value core default_timezone` devolvendo `utc`.
- Registro de carga e alerta: 5, 7 e 7 linhas, com a terceira carga em falha em `checar_repeticao`
  e `ALERTA` no log; `run_type` gravado como `DagRunType.MANUAL` com `str()` e como `manual` com
  `.value`; dependência mal declarada com `UndefinedTable`, escondida pela nova tentativa, e alerta
  falso com 5 linhas em vez de 7; carga com zero linhas terminando em sucesso no cron e no
  Airflow; `/api/v2/version` com 200 sem token e `/api/v2/dags` com 401 no compose oficial;
  `No alive jobs found` quando o `$HOSTNAME` expande no shell da máquina.
- Mini-desafio, com o Airflow 3.3.2 instalado por `uv` em Python 3.12.3 e banco SQLite novo:
  limites sem hora impressos como 00:00 UTC e padrão de reprocesso `None`; ensaio de 23 a 25 sem
  hora listando as datas lógicas 22 e 23, e de 24 a 26 listando 23 e 24; limites com hora, em UTC
  ou com `-03:00`, listando 23, 24 e 25.
- Nível 2: a checagem do Exercício 8 carregou sem erro de importação, com os providers postgres
  7.0.2 e common-sql 2.1.1, e o `airflow tasks render` mostrou as duas consultas no dia anterior à
  data lógica, sem rodar contra o banco; o `docker-compose.yaml` do laboratório usa
  `postgresql+psycopg2`, conferido na leitura do arquivo.
- Laboratório do capítulo 13, em `engenharia_de_dados/orquestracao/airflow/lab/`: Lab 0 a Lab 5
  rodados em sequência num ambiente só, com a saída de cada lab em `saidas/`; Airflow saudável em
  46 s com o Postgres já no ar e em 54 s e 82 s partindo do zero; `python dags/pipeline_loja.py`
  sem saída e com código 0; `airflow dags test loja_idempotente 2026-10-22` em `success` em cerca
  de 15 s; contêineres somando cerca de 0,9 GiB no fim do Lab 5; o `down` final sem contêiner nem
  volume do projeto; `.gitattributes` com `*.sh text eol=lf` mantendo o `.sh` com LF num clone com
  `core.autocrlf=true`, no Git 2.55.0.

#### Reconferência na 3.4.0

A apostila foi escrita e conferida na 3.3.2. A 3.4.0 estava em versão candidata na data da
pesquisa, com a rc1 no PyPI em 2026-10-28 e a versão final prevista para 2026-11-02; as fontes
estão no grupo "Apache Airflow 3.4.0, versão candidata", acima.

Antes de publicar, confira de novo, na versão final:

- o ciclo de vida e as versões dos serviços gerenciados, no capítulo 11;
- as mudanças da 3.4 listadas no capítulo 17: Python 3.11 ou mais, psycopg3 como driver padrão do
  banco de metadados e uma execução por evento em Dags disparadas por asset;
- os padrões de configuração citados nos capítulos 5 a 9, que podem mudar de uma versão para
  outra.

Data da reconferência na 3.4.0: pendente. Até lá, vale a 3.3.2.
