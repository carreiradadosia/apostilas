-- What the ERP does at night, on the erp database: a job touches every row, no price changes.
UPDATE dbo.produtos SET atualizado_em = '2026-10-21 03:00';
SELECT id, preco, atualizado_em FROM dbo.produtos ORDER BY id;
