PRINT N'== O que sobra na origem: só o preço de hoje. Não há como pedir o de ontem.';
SELECT id, preco, atualizado_em FROM replica.produtos WHERE id IN (30, 40) ORDER BY id;

PRINT N'== O pedido 102, do dia 20, vendeu o caderno a 20,50. A origem diz outra coisa agora.';
SELECT i.pedido_id, i.preco_unitario, p.preco AS preco_na_origem_hoje
FROM replica.itens_pedido i
JOIN replica.produtos p ON p.id = i.produto_id
WHERE i.pedido_id = 102 AND i.produto_id = 40;

PRINT N'== As fotos guardam os três dias.';
SELECT _dia_referencia, id, preco
FROM bronze.produtos_foto
WHERE id IN (30, 40)
ORDER BY id, _dia_referencia;

PRINT N'== SCD tipo 2 derivado das fotos, por vigência.';
SELECT produto_id, preco, valido_de, valido_ate
FROM silver.produtos_vigencia
ORDER BY produto_id, valido_de;

PRINT N'== Custo de cada caminho: linhas guardadas.';
SELECT (SELECT COUNT(*) FROM bronze.produtos_foto) AS linhas_nas_fotos,
       (SELECT COUNT(*) FROM silver.produtos_vigencia) AS linhas_no_tipo_2;

PRINT N'== Cada venda encontra uma versão só, sem fan-out.';
SELECT f.pedido_id, f.item_seq, f.data_id, p.produto_id, f.preco_unitario, f.preco_tabela,
       f.preco_unitario - f.preco_tabela AS desconto
FROM gold.fct_vendas f
JOIN gold.dim_produto p ON p.produto_sk = f.produto_sk
WHERE p.produto_id IN (30, 40)
ORDER BY f.pedido_id, f.item_seq;

PRINT N'== BETWEEN com limites fechados: a venda no dia da troca casa com duas versões.';
SELECT i.pedido_id, i.item_seq, o.dia_local, COUNT(*) AS versoes_casadas, SUM(i.valor_item) AS valor_somado
FROM silver.itens i
JOIN silver.pedidos o ON o.pedido_id = i.pedido_id
JOIN silver.produtos_vigencia v
  ON v.produto_id = i.produto_id
 AND o.dia_local BETWEEN v.valido_de AND COALESCE(v.valido_ate, CONVERT(date, '99991231', 112))
GROUP BY i.pedido_id, i.item_seq, o.dia_local
HAVING COUNT(*) > 1
ORDER BY i.pedido_id, i.item_seq;

PRINT N'== Venda anterior à primeira foto: o preço de tabela daquele dia não existe em lugar nenhum.';
SELECT v.produto_id, v.dia, d.preco_tabela
FROM (VALUES (10, CONVERT(date, '20261019', 112))) AS v(produto_id, dia)
LEFT JOIN gold.dim_produto d
  ON d.produto_id = v.produto_id
 AND v.dia >= d.valido_de
 AND (d.valido_ate IS NULL OR v.dia < d.valido_ate);
