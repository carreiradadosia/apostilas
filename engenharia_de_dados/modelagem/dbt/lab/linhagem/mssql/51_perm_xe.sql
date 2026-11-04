-- Run as leitor_monitor: create, start, read, stop and drop a session of its own.
SET NOCOUNT ON;
GO
CREATE EVENT SESSION relatorio_lab_monitor ON SERVER
ADD EVENT sqlserver.sql_batch_completed (WHERE ([sqlserver].[client_app_name] = N'erp_relatorios'))
ADD TARGET package0.ring_buffer (SET max_memory = 1024)
WITH (MAX_DISPATCH_LATENCY = 3 SECONDS);
GO
ALTER EVENT SESSION relatorio_lab_monitor ON SERVER STATE = START;
GO
SELECT name AS sessao_ativa FROM sys.dm_xe_sessions WHERE name = N'relatorio_lab_monitor';
GO
ALTER EVENT SESSION relatorio_lab_monitor ON SERVER STATE = STOP;
GO
DROP EVENT SESSION relatorio_lab_monitor ON SERVER;
GO
SELECT COUNT(*) AS sessoes_definidas_restantes FROM sys.server_event_sessions WHERE name = N'relatorio_lab_monitor';
GO
