-- Idempotent load: replace the whole day, the caller commits both statements together.
DELETE FROM bronze.pedidos
WHERE _dia_referencia = %(dia)s::date;

INSERT INTO bronze.pedidos
    (id, cliente, valor, valor_texto, status, criado_em, atualizado_em, _dia_referencia)
SELECT id, cliente, valor, valor_texto, status, criado_em, atualizado_em, %(dia)s::date
FROM replica.pedidos
WHERE criado_em >= %(dia)s::date
  AND criado_em < %(dia)s::date + 1;
