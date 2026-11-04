-- Second night: the job touches every row and two prices are overwritten in place.
UPDATE dbo.produtos SET atualizado_em = '2026-10-22 03:00';
UPDATE dbo.produtos SET preco = 20.00 WHERE id = 40;
UPDATE dbo.produtos SET preco = 17.00 WHERE id = 30;
SELECT id, preco, atualizado_em FROM dbo.produtos ORDER BY id;
