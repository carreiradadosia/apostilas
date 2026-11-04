-- The reload of 64d, failing through RAISERROR: it does not honor XACT_ABORT, so the batch goes on to the COMMIT.
PRINT N'== RAISERROR de severidade 16, com XACT_ABORT ON.';
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DELETE FROM silver.recarga_demo;
INSERT INTO silver.recarga_demo VALUES (1, 11.00);
RAISERROR (N'validação falhou', 16, 1);
INSERT INTO silver.recarga_demo VALUES (2, 22.00);
COMMIT;
GO
