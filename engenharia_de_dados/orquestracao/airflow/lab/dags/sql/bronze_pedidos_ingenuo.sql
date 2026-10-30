-- Naive load: every rerun of the same day appends the same rows again.
INSERT INTO bronze.pedidos
    (id, cliente, valor, valor_texto, status, criado_em, atualizado_em, _dia_referencia)
SELECT id, cliente, valor, valor_texto, status, criado_em, atualizado_em, %(dia)s::date
FROM replica.pedidos
WHERE criado_em >= %(dia)s::date
  AND criado_em < %(dia)s::date + 1;
