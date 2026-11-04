-- TRIM without a list removes only spaces: a tab survives NULLIF, and TRY_CONVERT reads what is left as empty text.
PRINT N'== NULLIF(TRIM(x), N'''') cobre vazio e espaços, não cobre tab. TRIM com lista de caracteres cobre os três e mantém o valor real.';
SELECT caso,
       TRY_CONVERT(date, NULLIF(TRIM(texto), N''), 103) AS nullif_trim,
       TRY_CONVERT(date, NULLIF(TRIM(NCHAR(9) + NCHAR(160) + N' ' FROM texto), N''), 103) AS trim_com_lista
FROM (VALUES (1, N'vazio', N''),
             (2, N'espacos', N'   '),
             (3, N'tab', NCHAR(9)),
             (4, N'tab_e_espaco', NCHAR(9) + N' '),
             (5, N'espaco_duro', NCHAR(160)),
             (6, N'valor_real', N'20/10/2026'),
             (7, N'valor_real_com_tab', NCHAR(9) + N'20/10/2026' + NCHAR(160))) AS casos(ordem, caso, texto)
ORDER BY ordem;
GO
