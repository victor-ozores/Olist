USE [OLIST]
GO

/****** Object:  View [dbo].[vw_dim_vendedor]    Script Date: 08/05/2026 16:26:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*
 * Objetivo:    Dimensão de vendedores com localização para
 *              análise de performance por seller no dashboard.
 *
 * GRAIN (o que uma linha representa):
 *   Uma linha por vendedor único (seller_id).
 *
 * Filtros:     Nenhum — todos os vendedores cadastrados,
 *              independente de terem pedidos entregues.
 *
 * Depende de:  dbo.olist_sellers_dataset
 *              dbo.vw_dim_estado    ← join para nome completo do estado
 *              dbo.fn_LimpaCidade   ← normalização de cidade (criar antes desta view)
 *
 * Relacionamento no Power BI:
 *   Dim_Vendedor[vendedor_id] → Fact_Vendedores[vendedor_id] (ativo)
 *   Dim_Vendedor[vendedor_id] → Fact_Logistica[vendedor_id]  (ativo)
 *
 * OBS sobre cidade_vendedor:
 *   Normalização delegada a dbo.fn_LimpaCidade — mesma função
 *   usada em vw_vendedores. Qualquer correção futura de cidade
 *   precisa ser feita apenas na função.
 *   O Power Query aplica Text.Proper após esta view.
 *   Não aplicar title case aqui — seria duplicado.
 *
 * OBS sobre estado_vendedor:
 *   A fonte (olist_sellers_dataset) armazena seller_state como sigla
 *   (ex: "SP", "RJ"). Esta view expõe o nome completo do estado via
 *   LEFT JOIN em vw_dim_estado (ex: "São Paulo", "Rio de Janeiro").
 *   LEFT JOIN — e não INNER JOIN — por segurança: vendedores com sigla
 *   inválida retornam NULL em vez de serem excluídos da dimensão.
 *   Validado: todos os 27 estados na fonte existem em vw_dim_estado
 *   (0 órfãos em 2026-03-30).
 */

CREATE OR ALTER VIEW [dbo].[vw_dim_vendedor] AS

SELECT
    vnd.seller_id                       AS vendedor_id,

    -- Limpeza de cidade_vendedor delegada a fn_LimpaCidade.
    -- Centraliza a lógica — manutenção futura em um único lugar.
    dbo.fn_LimpaCidade(vnd.seller_city) AS cidade_vendedor,

    -- Nome completo do estado via vw_dim_estado.
    -- LEFT JOIN: vendedor com sigla inválida retorna NULL (não é excluído).
    est.estado_nome                     AS estado_vendedor

FROM dbo.olist_sellers_dataset      AS vnd
LEFT JOIN dbo.vw_dim_estado         AS est  ON est.estado_sigla = vnd.seller_state;


GO


