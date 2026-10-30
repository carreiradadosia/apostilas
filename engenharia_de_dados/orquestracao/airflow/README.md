---
title: "Laboratório de orquestração com Apache Airflow"
date: 2026-10-30
type: modulo
status: publicado
tags: [orquestracao, airflow, mentoria]
---

# Laboratório de orquestração com Apache Airflow

O laboratório dos Labs 0 a 5 da apostila de Fundamentos de orquestração: o mesmo fluxo de uma
rede de lojas fictícia rodado à mão e como Dag, com réplica só leitura, camadas bronze, silver e
gold em SQL, registro de carga com alerta e o atendimento da meia-noite.

## Estado

Status na trilha: **publicado**. Este é um módulo só de laboratório: não tem apostila própria,
porque o conceito é ensinado pela apostila do módulo `orquestracao/fundamentos`, que cita este
laboratório no capítulo 13. A ordem recomendada vive em `trilha.yml`, na raiz da trilha. Seu
roteiro pode incluir este módulo em outra posição.

## O que tem aqui

- `lab/`, o laboratório: um compose leve só, com Airflow 3.3.2, LocalExecutor e Postgres 16.15,
  o passo a passo no `lab/README.md` e a saída real de cada lab em `lab/saidas/`
- `lab.json`, o manifesto de verificação: artefatos no nível 2 e Labs 0 a 5 no nível 3, em
  2026-10-29

## O que ainda não existe

Diretórios opcionais ausentes neste módulo, declarados aqui de propósito:

- `scripts/` ausente, os scripts do laboratório ficam dentro de `lab/`
- `exercicios/` ausente, os enunciados vivem na apostila de fundamentos, no capítulo 14
- `diagramas/` ausente

## Como rodar

A partir da raiz do repositório clonado:

```bash
cd engenharia_de_dados/orquestracao/airflow/lab
cat README.md
```
