-- A short session filtered by application name. The predicate drops other applications before any
-- action or target runs. No plan event: the event description warns about its overhead.
CREATE EVENT SESSION relatorio_lab ON SERVER
ADD EVENT sqlserver.sql_batch_completed (
    ACTION (sqlserver.client_app_name, sqlserver.server_principal_name, sqlserver.database_name)
    WHERE ([sqlserver].[client_app_name] = N'erp_relatorios')
),
ADD EVENT sqlserver.rpc_completed (
    ACTION (sqlserver.client_app_name, sqlserver.server_principal_name, sqlserver.database_name)
    WHERE ([sqlserver].[client_app_name] = N'erp_relatorios')
),
ADD EVENT sqlserver.sp_statement_completed (
    ACTION (sqlserver.client_app_name, sqlserver.server_principal_name, sqlserver.database_name)
    WHERE ([sqlserver].[client_app_name] = N'erp_relatorios')
)
ADD TARGET package0.event_file (
    SET filename = N'/var/opt/mssql/log/relatorio_lab.xel', max_file_size = 16, max_rollover_files = 2
),
ADD TARGET package0.ring_buffer (SET max_memory = 1024)
WITH (MAX_MEMORY = 4 MB, EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
      MAX_DISPATCH_LATENCY = 3 SECONDS, STARTUP_STATE = OFF);
GO
ALTER EVENT SESSION relatorio_lab ON SERVER STATE = START;
GO
SELECT name AS sessao, create_time FROM sys.dm_xe_sessions WHERE name = N'relatorio_lab';
GO
