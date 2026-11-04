-- The same reload, failing through THROW: the batch ends there and XACT_ABORT rolls everything back.
PRINT N'== THROW, com XACT_ABORT ON.';
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DELETE FROM silver.recarga_demo;
INSERT INTO silver.recarga_demo VALUES (1, 11.00);
;THROW 50000, N'validação falhou', 1;
INSERT INTO silver.recarga_demo VALUES (2, 22.00);
COMMIT;
GO
