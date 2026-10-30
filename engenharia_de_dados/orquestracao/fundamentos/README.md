---
title: "Fundamentos de orquestração"
date: 2026-10-30
type: modulo
status: publicado
tags: [orquestracao, mentoria]
---

# Fundamentos de orquestração

O orquestrador não é o código de limpeza, é quem roda o código. Do script rodado à mão ao
agendador e à Dag, com o Apache Airflow 3.3.2 como exemplo: quando subir de degrau, como tornar
uma carga segura para rodar de novo, que dia cada execução processa e como saber que a carga
falhou, mesmo quando ela termina verde.

## Estado

Status na trilha: **publicado**. A apostila foi escrita e conferida na versão 3.3.2 do Airflow,
que é a que vale; a reconferência na 3.4.0 fica registrada no último capítulo. A ordem
recomendada vive em `trilha.yml`, na raiz da trilha. Seu roteiro pode cursar este módulo em outra
posição.

## O que tem aqui

- `apostila.md`, a apostila inteira num arquivo só, que é a fonte do texto
- `capitulos/`, a mesma apostila com um arquivo por capítulo, gerada a partir da `apostila.md`,
  com o índice logo abaixo
- `lab.json`, que liga os Labs 0 a 5 citados na apostila ao laboratório do módulo
  `orquestracao/airflow`, onde ficam os comandos, as saídas e o nível de cada um

<!-- capitulos:inicio -->
## Capítulos

A apostila também está dividida em um arquivo por capítulo, na pasta `capitulos/`. Os capítulos são
gerados a partir da `apostila.md`, que continua inteira neste módulo e é a fonte: a correção entra
nela, e os capítulos são gerados de novo. Não edite um capítulo à mão.

- [0. Como usar esta apostila](capitulos/00-como-usar-esta-apostila.md)
- [1. Objetivo pedagógico](capitulos/01-objetivo-pedagogico.md)
- [2. Contexto de negócio](capitulos/02-contexto-de-negocio.md)
- [3. O que é orquestrar, e o que não é](capitulos/03-o-que-e-orquestrar-e-o-que-nao-e.md)
- [4. Os degraus: à mão, agendador, orquestrador](capitulos/04-os-degraus.md)
- [5. Vocabulário mínimo: Dag, tarefa, dependência, execução e estado](capitulos/05-vocabulario-minimo.md)
- [6. Nova tentativa e idempotência: o preço do orquestrador](capitulos/06-nova-tentativa-e-idempotencia.md)
- [7. Tempo: agendamento, data lógica, reprocesso e catchup](capitulos/07-tempo.md)
- [8. Fuso horário: o dia de quem?](capitulos/08-fuso-horario.md)
- [9. Saber que falhou: registro de carga, alerta e falha silenciosa](capitulos/09-saber-que-falhou.md)
- [10. Proteger a origem e guardar o que some](capitulos/10-proteger-a-origem-e-guardar-o-que-some.md)
- [11. Onde rodar e quanto custa: a decisão do gestor](capitulos/11-onde-rodar-e-quanto-custa.md)
- [12. Do script à Dag: o mesmo fluxo, muda quem roda](capitulos/12-do-script-a-dag.md)
- [13. Laboratório](capitulos/13-laboratorio.md)
- [14. Exercícios, entregáveis e mini-desafio](capitulos/14-exercicios-entregaveis-e-mini-desafio.md)
- [15. Rubrica de validação da aprendizagem](capitulos/15-rubrica-de-validacao-da-aprendizagem.md)
- [16. Erros comuns e como corrigir](capitulos/16-erros-comuns-e-como-corrigir.md)
- [17. Plano de continuidade](capitulos/17-plano-de-continuidade.md)
- [18. Glossário](capitulos/18-glossario.md)
- [Referências, Fontes verificadas (2026-10-29) e Reconferência na 3.4.0](capitulos/19-referencias.md)
<!-- capitulos:fim -->

## O que ainda não existe

Este módulo declara `lab: false` no `trilha.yml` e não tem pasta de laboratório própria. A
apostila descreve o laboratório no capítulo 13, com o nível de verificação de cada bloco. O
laboratório, um compose leve só com o fluxo à mão, o Airflow e o registro de carga, é o módulo
`orquestracao/airflow`, na pasta `engenharia_de_dados/orquestracao/airflow/lab/`.

Diretórios opcionais ausentes, declarados aqui de propósito:

- `scripts/` ausente
- `exercicios/` ausente, os enunciados vivem dentro da apostila, no capítulo 14
- `diagramas/` ausente

## Como rodar

Este módulo não tem laboratório próprio. O estudo é feito pela apostila, e quem decide não precisa
instalar nada: o capítulo 0 traz o roteiro por perfil. Para a prática, a partir da raiz do
repositório clonado:

```bash
cd engenharia_de_dados/orquestracao/airflow/lab
cat README.md
```

## Módulos vizinhos

O laboratório com o Airflow é o módulo `orquestracao/airflow`. O SQL de tratamento da camada
silver e o histórico de valores com SCD tipo 2 são do conceito de Modelagem e transformação, e a
captura de mudanças (CDC) é do conceito de Ingestão; os dois estão em revisão e ficam fora desta
versão da trilha.
