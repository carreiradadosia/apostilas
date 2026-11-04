---
title: "22. Rubrica de validação da aprendizagem"
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

[Índice](../README.md#capítulos) · [Anterior: 21. Exercícios, entregáveis e mini-desafio](21-exercicios-entregaveis-e-mini-desafio.md) · [Próximo: 23. Erros comuns e como corrigir](23-erros-comuns-e-como-corrigir.md)

## 22. Rubrica de validação da aprendizagem

"Como sei que aprendi, e não só que acompanhei?" A rubrica responde. Ela é o que o mentor usa na call. Sem ela, a avaliação vira impressão. Os níveis abaixo são critério da mentoria.

### 22.1 Como aplicar na call

**O que levar.** Leve o entregável do capítulo 21: a silver da tabela nova, com grão declarado, teste e registro do número. Leve também o mini-desafio resolvido.

**Como funciona na prática.** O mentor escolhe uma regra do seu entregável e pergunta por que ela está ali. Depois pede para você rodar a consulta que prova. Vale o que você mostra e explica, não o que você diz que sabe.

**Como ler o resultado.** Cada critério recebe um nível pela evidência vista na call. Insuficiente não é reprovação. Ele aponta o capítulo que você vai rever. Suficiente em todos os critérios já sustenta o trabalho do dia a dia. Excelente é o que se espera de quem revisa o SQL de outra pessoa.

### 22.2 Os critérios

Vamos ao exemplo que serve de régua. No critério "declara o grão", o insuficiente descreve a tabela pelo relatório: "é a tabela de faturamento". O suficiente escreve a frase antes do SQL: "uma linha é um item de pedido". O excelente prova com consulta e diz o que a frase impede: somar a uma fato de item um valor que está no grão do pedido.

| Critério | Insuficiente | Suficiente | Excelente |
|---|---|---|---|
| Declara o grão (cap. 5) | Descreve a tabela pelo relatório. | Escreve a frase antes do SQL. | Prova com consulta e diz o que a frase impede. |
| Usa critério no nulo e no `CASE` (cap. 7) | Troca todo nulo por zero. Escreve `CASE` sem `ELSE`. | Decide nulo por coluna, com motivo. O `ELSE` trata o valor novo. | Separa o nulo que deve alertar do que tem valor padrão, e escreve o teste que conta. |
| Converte fuso (cap. 8) | Lê o dado em UTC como hora local, ou converte sem saber a origem. | Converte de UTC para `America/Sao_Paulo` uma vez, num lugar só. | Usa um caso como o atendimento depois do fechamento para provar o sentido da conversão. |
| Deduplica por chave (cap. 6) | Esconde a duplicata com `DISTINCT`. | Define a chave e a regra de qual linha fica. | Mostra as duplicatas antes, conta as que saíram e explica de onde vieram. |
| Monta estrela sem fan-out (cap. 9 e 10) | Faz o JOIN e confia no resultado porque não deu erro. | Confere o grão de cada lado antes do JOIN e prova que o resultado não multiplicou linha. | Reconcilia o total da fato com a origem e acha a causa de um número dobrado. |
| Escolhe a forma do histórico (cap. 11 e 12) | Usa `UPDATE` sem perceber o que foi apagado. | Escolhe entre tipo 1 e tipo 2 pela pergunta do negócio, com um filtro de vigência que devolve uma versão só em qualquer dia. | Liga a venda à versão certa, conta o que caiu no membro desconhecido e explica o custo da chave escolhida. |
| Testa grão e chaves (cap. 13) | Não testa, ou olha o resultado a olho. | Tem teste de unicidade, de nulo e de relação, cada um procurando as linhas que desmentem a regra. | Mostra um teste falhando de propósito e diz quem é avisado quando ele falha. |
| Decide o degrau por um sinal (cap. 19) | Escolhe a ferramenta porque ouviu falar dela. | Cita um sinal observado no próprio cenário e decide manter ou subir. | Compara custo e risco dos dois degraus e diz o que faria mudar a decisão. |
| Registra o número (cap. 18) | O número só existe no relatório. | Escreve regra, grão e dono junto do SQL. | Refaz o caminho do número até a origem e explica uma divergência entre dois relatórios. |

**O equívoco comum.** Tratar a tabela como lista de ferramentas decoradas. Nenhum critério pede dbt. Você pode chegar a excelente com SQL à mão, se a evidência estiver lá.

**Como inspecionar.** Antes da call, percorra a tabela sozinho. Para cada critério, separe a consulta ou o trecho que mostra o nível. Onde nada aparecer, comece por lá.

Quando um critério ficar abaixo do esperado, o capítulo seguinte ajuda a achar o erro pelo sintoma.

---

[Índice](../README.md#capítulos) · [Anterior: 21. Exercícios, entregáveis e mini-desafio](21-exercicios-entregaveis-e-mini-desafio.md) · [Próximo: 23. Erros comuns e como corrigir](23-erros-comuns-e-como-corrigir.md)
