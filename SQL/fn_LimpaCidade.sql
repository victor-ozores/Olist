USE [OLIST]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_LimpaCidade]    Script Date: 08/05/2026 16:37:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*
 * Objetivo:    Normaliza o campo seller_city da fonte Olist,
 *              corrigindo erros de digitação, identificadores
 *              inválidos e formatos compostos (cidade/UF,
 *              cidade-UF, cidade rj, etc.).
 *
 * Retorna:     VARCHAR(200) — cidade limpa em lowercase.
 *              O Power Query aplica Text.Proper após consumir
 *              as views — NÃO aplicar title case aqui.
 *
 * Utilizada por:
 *   dbo.vw_dim_vendedor   — dimensão de vendedores
 *   dbo.vw_vendedores     — fact de desempenho por vendedor
 *
 * Motivação:   A lógica era idêntica e inline nos dois objetos,
 *              criando risco de divergência em manutenção futura.
 *              Centralizar em função elimina a duplicação.
 *
 * Correções aplicadas (v1 → v3, herdadas das views originais):
 *   v1:
 *   - "04482255"              → "desconhecido"  (CEP no lugar de cidade)
 *   - "bahia"                 → "desconhecido"  (estado no lugar de cidade)
 *   - "centro"                → "desconhecido"  (localização genérica)
 *   - "belo horizont"         → "belo horizonte"
 *   - "balenario camboriu"    → "balneario camboriu"
 *   - "cascavael"             → "cascavel"
 *   - "floranopolis"          → "florianopolis"
 *   - "ao bernardo do campo"  → "sao bernardo do campo"
 *   - Padrão "cidade / uf"    → remove sufixo
 *   - Padrão "cidade/ uf"     → remove sufixo
 *   - Padrão "cidade/uf"      → remove sufixo (2 letras)
 *   - Padrão "cidade-uf"      → remove sufixo
 *   - Padrão "cidade rj"      → remove sufixo
 *   - Padrão "cidade df"      → remove sufixo
 *   - Espaço duplo interno    → normaliza
 *   v2:
 *   - Padrão "cidade/estado completo" (ex: "maua/sao paulo")
 *     → remove sufixo após barra
 */

CREATE OR ALTER   FUNCTION [dbo].[fn_LimpaCidade]
(
    @cidade VARCHAR(200)
)
RETURNS VARCHAR(200)
AS
BEGIN
    RETURN RTRIM(LTRIM(
        CASE
            -- ----------------------------------------------------------------
            -- Identificação inválida: dado não representa uma cidade
            -- ----------------------------------------------------------------
            WHEN @cidade = '04482255'
                THEN 'desconhecido'

            WHEN @cidade = 'bahia'
                THEN 'desconhecido'

            WHEN @cidade = 'centro'
                THEN 'desconhecido'

            -- ----------------------------------------------------------------
            -- Typos com cidade identificável
            -- ----------------------------------------------------------------
            WHEN @cidade = 'belo horizont'
                THEN 'belo horizonte'

            WHEN @cidade = 'balenario camboriu'
                THEN 'balneario camboriu'

            WHEN @cidade = 'cascavael'
                THEN 'cascavel'

            WHEN @cidade = 'floranopolis'
                THEN 'florianopolis'

            WHEN @cidade = 'ao bernardo do campo'
                THEN 'sao bernardo do campo'

            -- ----------------------------------------------------------------
            -- Sufixo com barra + espaço: "cidade / uf" ou "cidade / estado"
            -- Ex: "carapicuiba / sao paulo", "cariacica / es"
            -- ----------------------------------------------------------------
            WHEN @cidade LIKE '% / %'
                THEN RTRIM(LEFT(@cidade, CHARINDEX(' / ', @cidade) - 1))

            -- ----------------------------------------------------------------
            -- Sufixo com barra sem espaço antes: "cidade/ uf" ou "cidade/ estado"
            -- Ex: "barbacena/ minas gerais"
            -- ----------------------------------------------------------------
            WHEN @cidade LIKE '%/ %'
                THEN RTRIM(LEFT(@cidade, CHARINDEX('/', @cidade) - 1))

            -- ----------------------------------------------------------------
            -- Sufixo com barra colada a estado por extenso ou sigla: "cidade/estado"
            -- Ex: "maua/sao paulo", "santo andre/sao paulo", "cidade/sp"
            -- Captura qualquer padrão "cidade/palavra" não coberto acima
            -- ----------------------------------------------------------------
            WHEN @cidade LIKE '%/%'
                THEN RTRIM(LEFT(@cidade, CHARINDEX('/', @cidade) - 1))

            -- ----------------------------------------------------------------
            -- Sufixo com hífen: "cidade-uf"
            -- Ex: "andira-pr"
            -- ----------------------------------------------------------------
            WHEN @cidade LIKE '%-[a-z][a-z]'
                THEN RTRIM(LEFT(@cidade, CHARINDEX('-', @cidade) - 1))

            -- ----------------------------------------------------------------
            -- Sufixo " rj" e " df"
            -- ----------------------------------------------------------------
            WHEN @cidade LIKE '% rj'
                THEN RTRIM(LEFT(@cidade, LEN(@cidade) - 3))

            WHEN @cidade LIKE '% df'
                THEN RTRIM(LEFT(@cidade, LEN(@cidade) - 3))

            -- ----------------------------------------------------------------
            -- Espaço duplo interno
            -- ----------------------------------------------------------------
            WHEN @cidade LIKE '%  %'
                THEN REPLACE(@cidade, '  ', ' ')

            ELSE @cidade
        END
    ));
END;

GO


