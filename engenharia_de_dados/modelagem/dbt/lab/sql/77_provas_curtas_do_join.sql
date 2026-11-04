-- Short proofs of chapter 10 on synthetic rows, in temporary tables that vanish with the session.
\pset border 1
\pset null '<nulo>'

CREATE TEMP TABLE itens (pedido_id int, item_seq int, produto_id int, valor numeric(10, 2));
CREATE TEMP TABLE pagamentos (pedido_id int, parcela int, valor numeric(10, 2));
CREATE TEMP TABLE produto_fornecedor (produto_id int, fornecedor text);
INSERT INTO itens VALUES (1, 1, 10, 50.00), (1, 2, 20, 30.00), (2, 1, 10, 50.00), (4, 1, 10, 50.00);
INSERT INTO pagamentos VALUES (1, 1, 40.00), (1, 2, 40.00), (2, 1, 50.00);
INSERT INTO produto_fornecedor VALUES (10, 'Fornecedor A'), (10, 'Fornecedor B'), (20, 'Fornecedor A');

\echo == 1. Fan-out: os itens dos pedidos 1 e 2 juntados com fornecedor, e os mesmos itens no grão do item.
SELECT count(*) AS linhas, sum(i.valor) AS receita
FROM itens i JOIN produto_fornecedor pf USING (produto_id) WHERE i.pedido_id IN (1, 2);
SELECT count(*) AS linhas, sum(valor) AS receita FROM itens WHERE pedido_id IN (1, 2);
SELECT produto_id, count(*) AS linhas FROM produto_fornecedor GROUP BY produto_id HAVING count(*) > 1;

\echo == 2. Dois lados muitos do mesmo pedido, SUM(DISTINCT) e cada lado no grão do pedido.
SELECT sum(i.valor) AS soma_itens, sum(p.valor) AS soma_pagamentos, sum(DISTINCT i.valor) AS soma_distinct_itens
FROM itens i JOIN pagamentos p USING (pedido_id) WHERE i.pedido_id IN (1, 2);
WITH it AS (SELECT pedido_id, sum(valor) AS total_itens FROM itens GROUP BY 1),
     pg AS (SELECT pedido_id, sum(valor) AS total_pago FROM pagamentos GROUP BY 1)
SELECT sum(total_itens) AS soma_itens, sum(total_pago) AS soma_pagamentos
FROM it JOIN pg USING (pedido_id) WHERE pedido_id IN (1, 2);

\echo == 3. DISTINCT sem a chave junta vendas legítimas: três itens do produto 10, uma linha.
SELECT count(*) AS itens_do_produto_10 FROM itens WHERE produto_id = 10;
SELECT DISTINCT produto_id, valor FROM itens WHERE produto_id = 10;

\echo == 4. DISTINCT não deduplica por chave: o pedido 2 chegou como pendente e depois como pago.
CREATE TEMP TABLE bronze_pedidos (pedido_id int, status text, valor numeric(10, 2), carregado_em timestamp);
INSERT INTO bronze_pedidos VALUES
    (1, 'pago', 80.00, '2026-10-21 03:00'), (1, 'pago', 80.00, '2026-10-21 03:00'),
    (2, 'pendente', 50.00, '2026-10-21 03:00'), (2, 'pago', 50.00, '2026-10-22 03:00');
SELECT DISTINCT pedido_id, status, valor FROM bronze_pedidos ORDER BY 1, 2;
SELECT pedido_id, status, valor FROM (
    SELECT b.*, row_number() OVER (PARTITION BY pedido_id ORDER BY carregado_em DESC, status) AS rn
    FROM bronze_pedidos b
) x WHERE rn = 1 ORDER BY 1;

\echo == 5. Pedido pago sem pagamento: o JOIN no grão do pedido o tira das duas somas; o LEFT JOIN mostra.
CREATE TEMP TABLE itens_pagos (pedido_id int, total_itens numeric(10, 2));
CREATE TEMP TABLE pagos (pedido_id int, total_pago numeric(10, 2));
INSERT INTO itens_pagos VALUES (1, 100.00), (2, 50.00), (3, 30.00);
INSERT INTO pagos VALUES (1, 100.00), (2, 50.00);
SELECT sum(total_itens) AS receita, sum(total_pago) AS pago, sum(total_itens) - sum(total_pago) AS diferenca
FROM itens_pagos JOIN pagos USING (pedido_id);
SELECT sum(total_itens) AS receita, sum(total_pago) AS pago,
       sum(total_itens) - coalesce(sum(total_pago), 0) AS diferenca,
       count(*) FILTER (WHERE total_pago IS NULL) AS pedidos_sem_pagamento
FROM itens_pagos LEFT JOIN pagos USING (pedido_id);
