USE [OLIST]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_TitleCase]    Script Date: 08/05/2026 16:36:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
 * Função auxiliar: dbo.fn_TitleCase
 *
 * Converte string para Title Case — primeira letra de cada palavra em maiúsculo,
 * restante em minúsculo. Equivalente ao Text.Proper do Power Query / Excel.
 *
 * Usada pela vw_comercial para normalizar cidade_cliente,
 * pois o Power Query não aplica transformação nessa coluna.
 *
 * Executar este bloco ANTES de criar a view.
 */
CREATE OR ALTER FUNCTION [dbo].[fn_TitleCase] (@input NVARCHAR(500))
RETURNS NVARCHAR(500)
AS
BEGIN
    IF @input IS NULL RETURN NULL
    IF LEN(LTRIM(RTRIM(@input))) = 0 RETURN @input

    DECLARE @result   NVARCHAR(500) = LOWER(LTRIM(RTRIM(@input)))
    DECLARE @pos      INT           = 1
    DECLARE @len      INT           = LEN(@result)
    DECLARE @prevChar NCHAR(1)      = ' '  -- inicia como espaço para capitalizar a 1ª letra

    WHILE @pos <= @len
    BEGIN
        IF @prevChar = ' '
            SET @result = STUFF(@result, @pos, 1, UPPER(SUBSTRING(@result, @pos, 1)))

        SET @prevChar = SUBSTRING(@result, @pos, 1)
        SET @pos      = @pos + 1
    END

    RETURN @result
END
GO