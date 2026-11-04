-- Session state and how many events the in-memory target holds at this moment.
SET NOCOUNT ON;
SELECT COUNT(*) AS sessoes_ativas FROM sys.dm_xe_sessions WHERE name = N'relatorio_lab';
SELECT t.target_name AS alvo,
       CASE WHEN t.target_name = N'ring_buffer'
            THEN CAST(CAST(t.target_data AS xml).value('(RingBufferTarget/@eventCount)[1]', 'int') AS nvarchar(20))
            ELSE N'(arquivo)' END AS eventos_em_memoria
FROM sys.dm_xe_session_targets AS t
JOIN sys.dm_xe_sessions AS s ON s.address = t.event_session_address
WHERE s.name = N'relatorio_lab';
GO
