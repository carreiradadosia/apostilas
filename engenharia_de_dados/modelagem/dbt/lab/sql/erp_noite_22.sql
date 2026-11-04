-- Second night: the job touches every row and two prices are overwritten in place.
UPDATE produtos SET atualizado_em = '2026-10-22 03:00';
UPDATE produtos SET preco = 20.00 WHERE id = 40;
UPDATE produtos SET preco = 17.00 WHERE id = 30;
SELECT id, preco, atualizado_em FROM produtos ORDER BY id;
