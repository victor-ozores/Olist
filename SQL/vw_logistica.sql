USE [OLIST]
GO

/****** Object:  View [dbo].[vw_logistica]    Script Date: 08/05/2026 16:25:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
 * Objetivo:    Visão de desempenho logístico por pedido entregue.
 *              Expõe frete, prazos e status de pontualidade para
 *              análise de SLA e performance de entrega.
 *
 * GRAIN (o que uma linha representa):
 *   Uma linha por PEDIDO entregue.
 *   Pedidos com múltiplos itens ou vendedores são consolidados
 *   nas CTEs itens_ranqueados e frete_por_pedido antes do SELECT final.
 *
 *   → frete = soma de todos os fretes dos itens do pedido.
 *   → vendedor_id / estado_vendedor_sigla = vendedor principal do pedido,
 *     definido como aquele com maior valor de frete individual.
 *     Em empate de frete, seller_id ASC garante determinismo.
 *
 * Filtros:     Apenas pedidos com status 'delivered' e data de
 *              entrega ao cliente preenchida. Pedidos em trânsito,
 *              cancelados ou sem data de entrega são excluídos.
 *              Pedidos anteriores a 2017 excluídos — 2016 contém apenas
 *              329 pedidos em 3 meses fragmentados (set/out/dez), sem
 *              valor analítico e distorcem comparativos de período.
 *
 * Depende de:  dbo.olist_orders_dataset
 *              dbo.olist_customers_dataset
 *              dbo.olist_order_items_dataset
 *              dbo.olist_sellers_dataset
 *
 * Valores monetários:
 *   Campos armazenados em CENTAVOS na fonte (ex: 1510 = R$ 15,10).
 *   A divisão por 100.0 converte para reais decimais.
 *   NÃO remover essa divisão.
 *
 * Limitações:  dias_diferenca negativo = entrega adiantada;
 *              positivo = entrega com atraso.
 *              Quando order_estimated_delivery_date é NULL,
 *              status_entrega recebe 'Prazo Indefinido' para evitar
 *              classificação silenciosa como 'Atrasado'.
 *
 * OBS sobre estado_vendedor_sigla:
 *   Expõe seller_state como sigla de 2 letras (ex: "SP", "RJ").
 *   Difere de vw_dim_vendedor.estado_vendedor, que expõe o nome
 *   completo via JOIN com vw_dim_estado. Nomes distintos para
 *   evitar ambiguidade no modelo do Power BI.
 *
 * Refatoração: subquery aninhada em dois níveis convertida em duas CTEs
 *              (itens_ranqueados + frete_por_pedido) para facilitar
 *              leitura e manutenção. Lógica e resultado idênticos.
 */

CREATE OR ALTER VIEW [dbo].[vw_logistica] AS

-- ============================================================
-- CTE: itens_ranqueados
-- Ranqueia os itens de cada pedido pelo frete individual (DESC).
-- rn = 1 identifica o item do vendedor principal do pedido.
-- Em empate de frete, seller_id ASC garante resultado determinístico.
-- ============================================================
WITH itens_ranqueados AS (

    SELECT
        ite.order_id,
        ite.seller_id,
        ite.freight_value,
        ROW_NUMBER() OVER (
            PARTITION BY ite.order_id
            ORDER BY ite.freight_value DESC, ite.seller_id ASC
        )                                           AS rn
    FROM dbo.olist_order_items_dataset              AS ite

),

-- ============================================================
-- CTE: frete_por_pedido
-- Consolida frete total e identifica vendedor principal por pedido.
-- SUM() OVER calcula o total de frete de TODOS os itens do pedido
-- antes do filtro rn = 1 — preserva a soma completa enquanto
-- mantém exatamente uma linha por pedido.
-- vendedor_id exposto para relacionamento com Dim_Vendedor no Power BI.
-- ============================================================
frete_por_pedido AS (

    SELECT
        ir.order_id,
        SUM(ir.freight_value / 100.0)
            OVER (PARTITION BY ir.order_id)         AS frete,
        ir.seller_id                                AS vendedor_id,
        vnd.seller_state                            AS estado_vendedor_sigla  -- sigla (ex: "SP"); distinto de vw_dim_vendedor.estado_vendedor (nome completo)
    FROM itens_ranqueados                           AS ir
    INNER JOIN dbo.olist_sellers_dataset            AS vnd  ON vnd.seller_id = ir.seller_id
    WHERE ir.rn = 1  -- mantém apenas o vendedor principal por pedido

)

-- ============================================================
-- SELECT FINAL
-- Combina pedido, cliente e dados logísticos consolidados.
-- CASE explícito para NULL em order_estimated_delivery_date:
-- evita classificação silenciosa de pedidos sem prazo como 'Atrasado'.
-- ============================================================
SELECT
    ped.order_id                                                          AS pedido_id,
    CAST(ped.order_purchase_timestamp AS DATE)                            AS data_pedido,
    cli.customer_state                                                    AS estado_cliente,
    fpp.estado_vendedor_sigla                                             AS estado_vendedor_sigla,
    fpp.vendedor_id                                                       AS vendedor_id,

    -- Frete em reais: fonte armazena em centavos (ex: 1510 = R$ 15,10).
    -- Soma de todos os itens do pedido consolidada na CTE frete_por_pedido.
    fpp.frete                                                             AS frete,

    DATEDIFF(
        DAY,
        ped.order_purchase_timestamp,
        ped.order_delivered_customer_date
    )                                                                     AS dias_entrega,

    DATEDIFF(
        DAY,
        ped.order_purchase_timestamp,
        ped.order_estimated_delivery_date
    )                                                                     AS dias_prazo_prometido,

    -- Tratamento explícito de NULL em order_estimated_delivery_date.
    -- Sem isso, o CASE cai silenciosamente no ELSE e marca como 'Atrasado'
    -- pedidos sem prazo prometido registrado — resultado enganoso.
    CASE
        WHEN ped.order_estimated_delivery_date IS NULL
            THEN 'Prazo Indefinido'
        WHEN ped.order_delivered_customer_date <= ped.order_estimated_delivery_date
            THEN 'No Prazo'
        ELSE
            'Atrasado'
    END                                                                   AS status_entrega,

    -- Negativo = entregue antes do prazo; positivo = atraso em dias.
    -- NULL quando order_estimated_delivery_date não está preenchido.
    DATEDIFF(
        DAY,
        ped.order_estimated_delivery_date,
        ped.order_delivered_customer_date
    )                                                                     AS dias_diferenca

FROM dbo.olist_orders_dataset               AS ped
INNER JOIN dbo.olist_customers_dataset      AS cli  ON cli.customer_id = ped.customer_id
INNER JOIN frete_por_pedido                 AS fpp  ON fpp.order_id    = ped.order_id
WHERE ped.order_status                    = 'delivered'
    AND ped.order_delivered_customer_date IS NOT NULL
    AND ped.order_purchase_timestamp      >= '2017-01-01';  -- remove 2016 fragmentado (329 pedidos em 3 meses)

GO