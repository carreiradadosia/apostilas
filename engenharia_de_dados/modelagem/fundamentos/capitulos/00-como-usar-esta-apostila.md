---
title: "0. Como usar esta apostila"
date: 2026-11-04
type: capitulo
status: draft
project: zambotto-mentoria
tags:
  - engenharia-de-dados
  - modelagem
  - apostila
  - mentoria
---

> Capítulo gerado a partir da [apostila completa](../apostila.md), que é a fonte. Não edite este arquivo: a correção entra na `apostila.md`, e os capítulos são gerados de novo.

[Índice](../README.md#capítulos) · [Próximo: 1. Objetivo pedagógico](01-objetivo-pedagogico.md)

## 0. Como usar esta apostila

### 0.1 Preciso ler tudo?

Não. Cada perfil de mentorado tem o seu caminho, e nem todo caminho passa pelo laboratório.

**Leitura linear ou revisão pontual**

Na primeira vez, leia em ordem: cada capítulo usa o vocabulário do anterior. Para revisar, vá direto
pelo sumário. Termo novo tem definição curta no glossário (25).

**Roteiro por perfil**

| Se você | Leia |
|---|---|
| quer só entender do que se trata | 3 e as aberturas do 4 e do 5 |
| gerencia e quer decidir | 2, 16, 18.1 e 19 |
| está começando na área | 1 a 15, em ordem, os Labs 0 a 6 do capítulo 20 e o exercício prático do 21 |
| já trabalha com dados e quer migrar para engenharia | 5 a 15, 17, 18, 20 e 21 |
| já é engenheiro e mira o próximo nível | 12, 14, 15, 16, 18 e 24 |

Some o que vale para o seu banco: se usa SQL Server, acrescente o 17 e o Lab 8 do capítulo 20.

Escreve SQL à mão hoje? É um bom ponto de partida, e esse é um critério da mentoria. O capítulo 19
mostra que sinal pede subir de degrau.

### 0.2 O que preciso ter antes do laboratório?

**Para ler**

SQL básico: ler e escrever um `SELECT`. O resto a apostila constrói, a partir de uma frase: antes do
SQL, decida o que uma linha significa.

**Versão de referência**

O dbt, ferramenta de transformação, só entra como exemplo. Ele aparece em trechos ao longo dos
capítulos, e o capítulo 15 monta o fluxo inteiro como projeto dbt. O laboratório fixa estas
versões, conferidas em 2026-11-03:

- `dbt-core` 1.12.6, estável, de 2026-10-14, com licença Apache-2.0.
- `dbt-postgres` 1.11.0, de 2026-07-16, o adaptador que liga o dbt ao banco. Exige `dbt-core` da
  1.8 até antes da 2.0, então Postgres com dbt hoje quer dizer dbt v1.
- PostgreSQL 16.15, na imagem `postgres:16.15-alpine`, com suporte até 2028-11-09.

Achou tutorial antigo? Confira a versão antes de copiar.

**Máquina**

O laboratório fica em `engenharia_de_dados/modelagem/dbt/lab/` no repositório clonado; os caminhos
`lab/...` desta apostila partem do módulo `modelagem/dbt/`.

Você precisa de Docker com Compose, terminal com bash e internet na primeira vez: as imagens são
baixadas, e a do dbt é construída na sua máquina. Do Lab 0 ao Lab 6 você não instala Python: o
Lab 0 constrói a imagem do dbt, e os Labs 5 e 6 rodam o dbt em contêiner. Confira:

```bash
docker --version
docker compose version
```

> Verificação: nível 3, em 2026-11-04, em Linux x86_64. Versões na máquina de teste: Docker 28.3.3
> e Compose v2.39.1. A sua será outra. Essas versões rodaram o
> laboratório; não testamos um mínimo. Saída em `lab/saidas/cap00_docker_versoes.txt`.

Quanto pesa? Medimos num Linux de 14 CPUs e 31 GB, que não representa a sua máquina. Sem Airflow,
são menos de 1 GB de imagens e centenas de MiB de memória. O Lab 7 acrescenta a imagem do Airflow
com dbt, de 2,65 GB, e um contêiner com pico entre 370 e 435 MiB. Os Labs 8 e 9 têm exigências
próprias, fora desta medição: veja o capítulo 20.

Serve em máquina comum? Nossa estimativa é que sim, e isso é inferência. Não testamos em máquina de
8 GB nem em Windows: tudo rodou em Linux.

> Verificação: nível 3, em 2026-11-03, com `docker image ls`, `docker stats` e o log de recursos do
> dbt. Saídas: `lab/saidas/recursos_medidos.txt` e `lab/saidas/lab0_subir_do_zero.txt`. As faixas
> variam por rodada; a saída guarda uma rodada do Airflow.

Com o caminho escolhido, vamos ao que você consegue fazer ao terminar e à pergunta de negócio que
puxa tudo isso.

---

[Índice](../README.md#capítulos) · [Próximo: 1. Objetivo pedagógico](01-objetivo-pedagogico.md)
