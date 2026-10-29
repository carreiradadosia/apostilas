---
title: "Fundamentos de orquestração"
date: 2026-10-29
type: modulo
status: planejado
tags: [orquestracao, mentoria]
---

# Fundamentos de orquestração

O orquestrador não é o código de limpeza, é quem roda o código. Do script rodado à mão ao
agendador e à Dag, com o Apache Airflow 3.3.2 como exemplo: quando subir de degrau, como tornar
uma carga segura para rodar de novo, que dia cada execução processa e como saber que a carga
falhou, mesmo quando ela termina verde.

## Estado

Status na trilha: **planejado**. A apostila está em rascunho, escrita e conferida na versão 3.3.2
do Airflow, e ainda passa pela revisão do dono e pela reconferência na 3.4.0 antes de publicar. A
ordem recomendada vive em `trilha.yml`, na raiz da trilha. Seu roteiro pode cursar este módulo em
outra posição.

## O que tem aqui

- `apostila.md`, o material de estudo do módulo

## O que ainda não existe

Este módulo declara `lab: false` no `trilha.yml`, logo não tem `lab.json` nem `infrastructure/`.
A apostila descreve o laboratório no capítulo 13, com o nível de verificação de cada bloco. O
pacote do laboratório, um compose leve só com perfis para o fluxo à mão, o Airflow e o registro de
carga, está em preparação no módulo `orquestracao/airflow`.

Diretórios opcionais ausentes, declarados aqui de propósito:

- `scripts/` ausente
- `exercicios/` ausente, os enunciados vivem dentro da apostila, no capítulo 14
- `diagramas/` ausente

## Como rodar

Este módulo não tem laboratório próprio. O estudo é feito pela apostila, e quem decide não precisa
instalar nada: o capítulo 0 traz o roteiro por perfil.

## Módulos vizinhos

O Airflow como ferramenta, com o laboratório, é do módulo `orquestracao/airflow`. O SQL de
tratamento da camada silver e o histórico de valores com SCD tipo 2 são de Modelagem e
transformação. A captura de mudanças (CDC) é do bloco de Ingestão.
