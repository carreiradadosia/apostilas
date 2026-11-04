-- A TRY/CATCH that only logs: the error never reaches sqlcmd, so -b has nothing to act on.
PRINT N'== TRY/CATCH que engole o erro, com XACT_ABORT ON.';
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DELETE FROM silver.recarga_demo;
    INSERT INTO silver.recarga_demo VALUES (1, 11.00);
    INSERT INTO silver.recarga_demo VALUES (1, 99.00);
    COMMIT;
END TRY
BEGIN CATCH
    PRINT N'erro capturado, nada sobe para quem chamou';
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO
