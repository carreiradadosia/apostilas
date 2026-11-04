-- Wait past MAX_DISPATCH_LATENCY, then read the file target. Duration and CPU fields are left out on purpose.
SET NOCOUNT ON;
WAITFOR DELAY '00:00:04';
;WITH eventos AS (
    SELECT CAST(event_data AS xml) AS x
    FROM sys.fn_xe_file_target_read_file(N'/var/opt/mssql/log/relatorio_lab*.xel', NULL, NULL, NULL)
)
SELECT x.value('(event/@name)[1]', 'nvarchar(30)') AS evento,
       x.value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(20)') AS aplicacao,
       x.value('(event/action[@name="server_principal_name"]/value)[1]', 'nvarchar(20)') AS login,
       x.value('(event/data[@name="object_name"]/value)[1]', 'nvarchar(30)') AS objeto,
       CAST(LEFT(REPLACE(REPLACE(COALESCE(x.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)'),
                                          x.value('(event/data[@name="batch_text"]/value)[1]', 'nvarchar(max)'),
                                          N'(sem texto)'),
                                 CHAR(10), ' '), CHAR(13), ' '), 200) AS nvarchar(200)) AS texto
FROM eventos;
GO
