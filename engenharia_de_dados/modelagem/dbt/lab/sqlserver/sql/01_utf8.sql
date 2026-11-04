-- With the file in UTF-8, the accented letter has to reach the server as a single code point (227).
SET NOCOUNT ON;
SELECT UNICODE(N'ã') AS unicode_de_a_til, LEN(N'São') AS len_de_sao, N'São' AS texto;
