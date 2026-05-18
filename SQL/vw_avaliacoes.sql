USE [OLIST]
GO

/****** Object:  View [dbo].[vw_avaliacoes]    Script Date: 08/05/2026 16:24:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
 * Objetivo:    Visão de avaliações de pedidos entregues, expondo
 *              score, datas de criação e resposta para análise de
 *              satisfação do cliente e performance por período.
 *
 * GRAIN (o que uma linha representa):
 *   Uma linha por avaliação (review_id).
 *   Relação 1:1 com pedido — cada pedido tem no máximo
 *   uma avaliação neste dataset.
 *
 *   → Para score médio: AVG(score) na query consumidora.
 *   → Para distribuição: COUNT(*) GROUP BY score.
 *   → Para % satisfeitos: COUNT onde score >= 4 / COUNT(*).
 *
 * Filtros:     Apenas avaliações vinculadas a pedidos com status
 *              'delivered' e data de entrega ao cliente preenchida.
 *              Pedidos anteriores a 2017 excluídos — critério idêntico
 *              ao aplicado nas views vw_comercial, vw_logistica e
 *              vw_vendedores para garantir consistência de período.
 *
 * Depende de:  dbo.olist_order_reviews_dataset
 *              dbo.olist_orders_dataset
 *
 * Limitações:  review_comment_title e review_comment_message foram
 *              importados com nvarchar(50) e nvarchar(250) — campos
 *              de texto livre truncados na importação. Não usar para
 *              análise de conteúdo. Úteis apenas como indicador de
 *              presença de comentário (IS NOT NULL).
 *              score varia de 1 a 5: 1=péssimo, 5=ótimo.
 */

CREATE OR ALTER VIEW [dbo].[vw_avaliacoes] AS

SELECT
    rev.review_id                                                         AS avaliacao_id,
    rev.order_id                                                          AS pedido_id,
    CAST(ped.order_purchase_timestamp AS DATE)                            AS data_pedido,
    rev.review_score                                                      AS score,

    -- Classificação semântica do score para facilitar segmentação
    -- no dashboard sem necessidade de lógica DAX adicional.
    CASE rev.review_score
        WHEN 5 THEN 'Ótimo'
        WHEN 4 THEN 'Bom'
        WHEN 3 THEN 'Regular'
        WHEN 2 THEN 'Ruim'
        WHEN 1 THEN 'Péssimo'
        ELSE        'Não Informado'
    END                                                                   AS classificacao_score,

    -- Indicador binário: 1 = avaliação positiva (score >= 4)
    -- Facilita cálculo de % satisfação sem CALCULATE condicional no DAX.
    CASE WHEN rev.review_score >= 4 THEN 1 ELSE 0 END                    AS is_positivo,

    CAST(rev.review_creation_date AS DATE)                                AS data_avaliacao,
    CAST(rev.review_answer_timestamp AS DATE)                             AS data_resposta,

    -- Dias entre compra e avaliação — mede latência do feedback.
    DATEDIFF(
        DAY,
        ped.order_purchase_timestamp,
        rev.review_creation_date
    )                                                                     AS dias_ate_avaliacao,

    -- Indicador de presença de comentário (texto truncado na importação —
    -- não usar o conteúdo, apenas verificar se existe).
    CASE WHEN rev.review_comment_message IS NOT NULL THEN 1 ELSE 0 END   AS tem_comentario

FROM dbo.olist_order_reviews_dataset        AS rev
INNER JOIN dbo.olist_orders_dataset         AS ped  ON ped.order_id = rev.order_id
WHERE ped.order_status                    = 'delivered'
    AND ped.order_delivered_customer_date IS NOT NULL
    AND ped.order_purchase_timestamp      >= '2017-01-01';  -- remove 2016 fragmentado (329 pedidos em 3 meses)

GO


