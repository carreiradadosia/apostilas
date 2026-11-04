---
title: "Fundamentos de modelagem e transformação"
date: 2026-11-04
type: modulo
status: rascunho
tags: [modelagem, transformacao, mentoria]
---

# Fundamentos de modelagem e transformação

Antes do SQL, decida o que uma linha significa. Do dado cru ao número da diretoria: onde cada regra
mora, o grão de cada tabela, a silver com critério, a estrela, o fan-out que dobra a receita sem dar
erro, o preço que o `UPDATE` apaga, a chave que sobrevive a uma reconstrução, os testes que param a
carga e o mesmo SQL como projeto dbt, com o T-SQL ao lado para quem tem SQL Server.

## Estado

Status na trilha: **rascunho**, até a revisão do dono. A apostila foi escrita e conferida com
PostgreSQL 16.15, `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0, com SQL Server 2022 e 2025 no capítulo
17. A ordem recomendada vive em `trilha.yml`, na raiz da trilha. Seu roteiro pode incluir este módulo
em outra posição.

## O que tem aqui

- `apostila.md`, a apostila inteira num arquivo só, que é a fonte do texto
- `capitulos/`, a mesma apostila com um arquivo por capítulo, gerada a partir da `apostila.md`,
  com o índice logo abaixo
- `lab.json`, que liga os Labs 0 a 9 citados na apostila ao laboratório do módulo
  `modelagem/dbt`, onde ficam os comandos, as saídas e o nível de cada um

<!-- capitulos:inicio -->
## Capítulos

A apostila também está dividida em um arquivo por capítulo, na pasta `capitulos/`. Os capítulos são
gerados a partir da `apostila.md`, que continua inteira neste módulo e é a fonte: a correção entra
nela, e os capítulos são gerados de novo. Não edite um capítulo à mão.

- [0. Como usar esta apostila](capitulos/00-como-usar-esta-apostila.md)
- [1. Objetivo pedagógico](capitulos/01-objetivo-pedagogico.md)
- [2. Contexto de negócio](capitulos/02-contexto-de-negocio.md)
- [3. O que é modelar e transformar, e o que não é](capitulos/03-o-que-e-modelar-e-transformar-e-o-que-nao-e.md)
- [4. Camadas: onde cada regra mora](capitulos/04-camadas.md)
- [5. Grão: o que uma linha significa](capitulos/05-grao.md)
- [6. Silver: texto, coluna redundante e duplicata](capitulos/06-silver.md)
- [7. Silver: nulo com critério e CASE WHEN](capitulos/07-silver.md)
- [8. Silver: datas e fuso horário](capitulos/08-silver.md)
- [9. Fato, dimensão e esquema estrela](capitulos/09-fato-dimensao-e-esquema-estrela.md)
- [10. Fan-out: quando o JOIN dobra o número](capitulos/10-fan-out.md)
- [11. Histórico: o preço que o UPDATE apaga](capitulos/11-historico.md)
- [12. Chave substituta e a venda na versão certa](capitulos/12-chave-substituta-e-a-venda-na-versao-certa.md)
- [13. Testes de dado: consultas que precisam voltar vazias](capitulos/13-testes-de-dado.md)
- [14. Materialização, incremental e reprocesso](capitulos/14-materializacao-incremental-e-reprocesso.md)
- [15. O mesmo SQL como projeto dbt](capitulos/15-o-mesmo-sql-como-projeto-dbt.md)
- [16. dbt hoje: geração, licença, adaptador e preço](capitulos/16-dbt-hoje.md)
- [17. SQL Server: a silver e a gold em T-SQL](capitulos/17-sql-server.md)
- [18. De onde vem este número: definição e linhagem](capitulos/18-de-onde-vem-este-numero.md)
- [19. Onde a regra mora: a decisão de quem gerencia](capitulos/19-onde-a-regra-mora.md)
- [20. Laboratório](capitulos/20-laboratorio.md)
- [21. Exercícios, entregáveis e mini-desafio](capitulos/21-exercicios-entregaveis-e-mini-desafio.md)
- [22. Rubrica de validação da aprendizagem](capitulos/22-rubrica-de-validacao-da-aprendizagem.md)
- [23. Erros comuns e como corrigir](capitulos/23-erros-comuns-e-como-corrigir.md)
- [24. Plano de continuidade](capitulos/24-plano-de-continuidade.md)
- [25. Glossário](capitulos/25-glossario.md)
- [Referências e Fontes verificadas (2026-11-04)](capitulos/26-referencias.md)
<!-- capitulos:fim -->

## O que ainda não existe

Este módulo declara `lab: false` no `trilha.yml` e não tem pasta de laboratório própria. A
apostila descreve o laboratório no capítulo 20, com o nível de verificação de cada bloco. O
laboratório é o módulo `modelagem/dbt`, na pasta `engenharia_de_dados/modelagem/dbt/lab/`.

Diretórios opcionais ausentes, declarados aqui de propósito:

- `scripts/` ausente
- `exercicios/` ausente, os enunciados vivem dentro da apostila, no capítulo 21
- `diagramas/` ausente

## Como rodar

Este módulo não tem laboratório próprio. O estudo é feito pela apostila, e quem decide não precisa
instalar nada: o capítulo 0 traz o roteiro por perfil. Para a prática, a partir da raiz do
repositório clonado:

```bash
cd engenharia_de_dados/modelagem/dbt/lab
cat README.md
```

## Módulos vizinhos

O laboratório com o dbt é o módulo `modelagem/dbt`. O agendamento, a nova tentativa e o alerta são do
conceito de Orquestração, no módulo `orquestracao/fundamentos`: o Lab 7 roda o dbt numa Dag, sem
ensinar o orquestrador de novo. A captura de mudanças (CDC) é do conceito de Ingestão, que está em
revisão e fica fora desta versão da trilha.
