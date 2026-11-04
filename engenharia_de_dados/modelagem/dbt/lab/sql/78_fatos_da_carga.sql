-- Facts of the lab load that the chapters quote, read from the database instead of the init script. Run after Lab 1.
\pset border 1
\pset null '<nulo>'

\echo == A montagem: dois bancos no mesmo servidor, o dw lê o erp pelo postgres_fdw.
SELECT datname FROM pg_database WHERE datname IN ('erp', 'dw') ORDER BY 1;
SELECT extname FROM pg_extension WHERE extname IN ('postgres_fdw', 'unaccent') ORDER BY 1;
SELECT srvname, srvoptions FROM pg_foreign_server;
SELECT foreign_table_schema, count(*) AS tabelas_estrangeiras
FROM information_schema.foreign_tables GROUP BY 1;
SELECT rolname, rolconfig FROM pg_roles WHERE rolname = 'replica_leitura';

\echo == Onde mora cada coluna da receita paga por categoria, na réplica.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'replica'
  AND ((table_name = 'pedidos' AND column_name = 'status')
       OR (table_name = 'itens_pedido' AND column_name IN ('quantidade', 'preco_unitario'))
       OR (table_name = 'produtos' AND column_name = 'categoria'))
ORDER BY 1, 2;

\echo == Pedido 101: o item da camiseta.
SELECT i.pedido_id, i.item_seq, p.nome AS produto, i.quantidade, i.preco_unitario
FROM replica.itens_pedido i JOIN replica.produtos p ON p.id = i.produto_id
WHERE i.pedido_id = 101 ORDER BY i.item_seq;

\echo == Pedido 104 em três grãos: pedido, item e parcela.
SELECT 'pedidos' AS tabela, count(*) AS linhas, sum(valor) AS valor FROM replica.pedidos WHERE id = 104
UNION ALL SELECT 'itens_pedido', count(*), sum(quantidade * preco_unitario) FROM replica.itens_pedido WHERE pedido_id = 104
UNION ALL SELECT 'pagamentos', count(*), sum(valor) FROM replica.pagamentos WHERE pedido_id = 104;

\echo == Um INSERT, um instante: as linhas de cada INSERT da carga saem com o mesmo _carregado_em.
SELECT 'bronze.itens_pedido' AS tabela, count(*) AS linhas, count(DISTINCT _carregado_em) AS instantes FROM bronze.itens_pedido
UNION ALL SELECT 'bronze.pedidos', count(*), count(DISTINCT _carregado_em) FROM bronze.pedidos;

\echo == Os itens da fato com o produto, nos três dias (consulta do capítulo 10).
SELECT f.pedido_id, f.item_seq, f.data_id, f.status, f.valor_item, p.produto_id
FROM gold.fct_vendas f JOIN gold.dim_produto p USING (produto_sk)
ORDER BY 3, 1, 2;

\echo == Duas regras para receita paga sobre os mesmos itens: status igual a 'pago' e status normalizado.
SELECT sum(i.quantidade * i.preco_unitario) FILTER (WHERE p.status = 'pago') AS status_igual_pago,
       sum(i.quantidade * i.preco_unitario) FILTER (WHERE lower(trim(p.status)) = 'pago') AS status_normalizado
FROM replica.pedidos p JOIN replica.itens_pedido i ON i.pedido_id = p.id;
SELECT p.id AS pedido_id, '[' || p.status || ']' AS status_como_veio, sum(i.quantidade * i.preco_unitario) AS valor_itens
FROM replica.pedidos p JOIN replica.itens_pedido i ON i.pedido_id = p.id
WHERE lower(trim(p.status)) = 'pago' AND p.status <> 'pago'
GROUP BY 1, 2 ORDER BY 1;
