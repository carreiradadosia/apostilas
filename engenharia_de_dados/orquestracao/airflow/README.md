---
title: "Orquestracao com Apache Airflow"
date: 2026-07-30
type: modulo
status: rascunho
tags: [orquestracao, mentoria]
---

# Orquestracao com Apache Airflow

DAGs, dependencias, idempotencia e retries num pipeline real.

## Estado

Status na trilha: **rascunho**. A ordem recomendada vive em `trilha.yml`, na
raiz da trilha. Seu roteiro pode cursar este modulo em outra posicao.

## O que tem aqui

- `apostila.md`, o material de estudo do modulo
- `lab/`, o laboratório dos Labs 0 a 5 da apostila de Fundamentos de orquestração: um compose
  leve só, com Airflow 3.3.2, LocalExecutor e Postgres 16.15, o passo a passo no `lab/README.md`
  e a saída real de cada lab em `lab/saidas/`
- `lab.json`, o manifesto de verificação: artefatos no nível 2 e Labs 0 a 5 no nível 3, em
  2026-10-29
- `infrastructure/`, o ambiente anterior em Docker Compose, com Airflow 3.1.7 e Celery, mantido
  como legado até decisão; os runbooks dele ficam em `infrastructure/runbooks/`

## O que ainda nao existe

Diretorios opcionais ausentes neste modulo, declarados aqui de proposito:

- `scripts/` ausente
- `exercicios/` ausente
- `diagramas/` ausente

## Como rodar

A partir da raiz do repositório clonado:

```bash
cd engenharia_de_dados/orquestracao/airflow/lab
cat README.md
```
