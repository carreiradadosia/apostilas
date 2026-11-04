# Laboratório de modelagem e transformação

Dados sintéticos de uma rede de lojas fictícia, em contêineres descartáveis. O passo a passo, com os
comandos e as saídas esperadas, está no capítulo 20 da apostila, em
`engenharia_de_dados/modelagem/fundamentos/capitulos/`. Rode tudo de dentro desta pasta, salvo quando
o Lab mandar entrar em subpasta.

## Antes de começar

Você precisa de Docker com Compose, terminal com bash e internet na primeira vez. Rodou em Linux; nada
foi testado em Windows.

```bash
./preparar.sh
docker compose up -d --wait postgres
```

O `preparar.sh` cria o `.env` com o seu id de usuário e senhas aleatórias. O compose para com uma
mensagem se o arquivo não existir. O `.env` fica fora do repositório, e não há senha escrita em nenhum
outro arquivo. O `sqlserver/` e o `linhagem/` têm `preparar.sh` próprio.

## O que há em cada pasta

| Pasta | O que é | Labs |
|---|---|---|
| `postgres-init/` | Cria os bancos `erp` e `dw`, os papéis e a réplica simulada | 0 |
| `sql/` | SQL à mão: bronze, silver, gold, as provas curtas e os enunciados dos exercícios | 1 a 4 |
| `projeto_dbt/` | O mesmo fluxo como projeto dbt | 5 e 6 |
| `runner/` | A imagem do dbt, com as versões travadas em `requirements.lock` | 0 e 5 |
| `orquestrador/` | A imagem do Airflow e a Dag que roda o dbt | 7 |
| `sqlserver/` | A silver e a gold em T-SQL, com licença a ler antes de subir | 8 |
| `linhagem/` | Que SQL um relatório roda, com licença a ler antes de subir | 9 |
| `alternativa_duckdb/` | Um projeto menor em DuckDB, que não reproduz os Labs | nenhum |
| `checagens/` | Conferências avulsas que os capítulos citam | nenhum |
| `saidas/` | A saída capturada de cada Lab e de cada prova curta | todos |

As capturas `saidas/lab9_*` reúnem as provas curtas citadas nos capítulos, cada uma com o estado do
banco no cabeçalho, montado pelos comandos de `saidas/lab9_preparo.txt`. O prefixo é só nome de
arquivo: o Lab 9 mora em `linhagem/`.

## Como deixar a máquina como estava

```bash
docker compose --profile dbt down -v
```

Isso remove contêiner, rede e volume deste projeto. Ficam as imagens, o `.env` e os arquivos da pasta.
Os Labs 8 e 9 derrubam o próprio projeto no fim do roteiro.
