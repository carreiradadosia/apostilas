-- Same report, other literals: the three statements must collapse into the same normalized entries.
SELECT loja, faturamento FROM relatorios.faturamento_por_loja('2026-10-21', '2026-10-21');
SELECT dia, sum(valor_item) AS total FROM relatorios.vw_faturamento_itens WHERE dia >= DATE '2026-10-22' GROUP BY dia ORDER BY dia;
SELECT pedido_id, valor_item FROM relatorios.vw_faturamento_itens WHERE trim(cliente) = 'Cliente E';
