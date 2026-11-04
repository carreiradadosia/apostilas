PRINT N'== DISTINCT ON, do Postgres, é erro de sintaxe.';
GO
SELECT DISTINCT ON (id) id, status FROM bronze.pedidos ORDER BY id, _carregado_em DESC;
GO
PRINT N'== QUALIFY: a doc restringe ao Fabric Data Warehouse. Aqui é erro.';
GO
SELECT id, status, ROW_NUMBER() OVER (PARTITION BY id ORDER BY _carregado_em DESC) AS ordem
FROM bronze.pedidos
QUALIFY ordem = 1;
GO
PRINT N'== ROW_NUMBER não pode ir direto no WHERE: erro 4108.';
GO
SELECT id, status FROM bronze.pedidos
WHERE ROW_NUMBER() OVER (PARTITION BY id ORDER BY _carregado_em DESC) = 1;
GO
PRINT N'== A forma que funciona: CTE numera, consulta de fora filtra.';
WITH ultima_carga AS (
    SELECT id, status, _carregado_em,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _carregado_em DESC) AS ordem
    FROM bronze.pedidos
)
SELECT id, status FROM ultima_carga WHERE ordem = 1 AND id = 103;
GO
PRINT N'== Carga dupla nos itens: 2 linhas a mais na bronze.';
GO
:r /sql/12_bronze_itens_carga_dupla.sql
GO
PRINT N'== A silver.itens não deduplica sozinha: a receita do pedido 104 dobra ao reconstruir sem cuidado.';
SELECT pedido_id, COUNT(*) AS linhas, SUM(quantidade * preco_unitario) AS soma
FROM bronze.itens_pedido
WHERE pedido_id = 104
GROUP BY pedido_id;
PRINT N'== Com ROW_NUMBER por chave de negócio e carga mais recente, o número volta.';
WITH ultima_carga AS (
    SELECT pedido_id, item_seq, quantidade, preco_unitario,
           ROW_NUMBER() OVER (PARTITION BY pedido_id, item_seq ORDER BY _carregado_em DESC) AS ordem
    FROM bronze.itens_pedido
)
SELECT pedido_id, COUNT(*) AS linhas, SUM(quantidade * preco_unitario) AS soma
FROM ultima_carga
WHERE ordem = 1 AND pedido_id = 104
GROUP BY pedido_id;
GO
PRINT N'== Desempate: _carregado_em repetido deixa ROW_NUMBER não determinístico. Sem coluna de desempate, a escolha não é garantida.';
SELECT pedido_id, item_seq, COUNT(*) AS cargas, COUNT(DISTINCT _carregado_em) AS instantes_distintos
FROM bronze.itens_pedido
WHERE pedido_id = 104
GROUP BY pedido_id, item_seq
ORDER BY item_seq;
GO
PRINT N'== Recoloca a bronze no estado certo para os próximos passos.';
GO
:r /sql/10_bronze_carga.sql
GO
