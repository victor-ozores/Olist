USE [OLIST]
GO

/****** Object:  View [dbo].[vw_vendedores]    Script Date: 08/05/2026 16:25:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*
 * Objetivo:    Visão de desempenho por vendedor, expondo dados de
 *              pedido, categoria, preço, frete e pontualidade de
 *              entrega para análise comercial e de seller performance.
 *
 * GRAIN (o que uma linha representa):
 *   Uma linha por combinação PEDIDO × ITEM × VENDEDOR.
 *   Pedidos com múltiplos itens geram múltiplas linhas.
 *
 *   → Para KPIs por vendedor (receita total, pedidos únicos),
 *     agregar por vendedor_id na query consumidora.
 *   → Para receita por vendedor: SUM(preco) GROUP BY vendedor_id.
 *   → Para pedidos únicos por vendedor: COUNT(DISTINCT pedido_id)
 *     GROUP BY vendedor_id.
 *
 * Filtros:     Apenas pedidos com status 'delivered' e data de
 *              entrega ao cliente preenchida.
 *              Pedidos anteriores a 2017 excluídos — 2016 contém apenas
 *              329 pedidos em 3 meses fragmentados (set/out/dez), sem
 *              valor analítico e distorcem comparativos de período.
 *
 * Depende de:  dbo.olist_orders_dataset
 *              dbo.olist_order_items_dataset
 *              dbo.olist_sellers_dataset
 *              dbo.olist_products_dataset
 *              dbo.fn_LimpaCidade  (função auxiliar — criar antes desta view)
 *
 * Valores monetários:
 *   Campos armazenados em CENTAVOS na fonte (ex: 1890 = R$ 18,90).
 *   A divisão por 100.0 converte para reais decimais.
 *   NÃO remover essa divisão.
 *
 * Limitações:  Produtos sem categoria recebem 'Sem Categoria'.
 *              status_entrega recebe 'Prazo Indefinido' quando
 *              order_estimated_delivery_date é NULL.
 *
 * OBS sobre cidade_vendedor:
 *   Normalização delegada a dbo.fn_LimpaCidade — mesma função
 *   usada em vw_dim_vendedor. Qualquer correção futura de cidade
 *   precisa ser feita apenas na função.
 *   O Power Query aplica Text.Proper após esta view.
 *   Não aplicar title case aqui — seria duplicado.
 *
 * OBS sobre estado_vendedor_sigla:
 *   Expõe seller_state como sigla de 2 letras (ex: "SP", "RJ").
 *   Difere de vw_dim_vendedor.estado_vendedor, que expõe o nome
 *   completo via JOIN com vw_dim_estado. Nomes distintos para
 *   evitar ambiguidade no modelo do Power BI.
 */

CREATE OR ALTER VIEW [dbo].[vw_vendedores] AS

SELECT
    ite.seller_id                                                         AS vendedor_id,

    -- Limpeza de cidade_vendedor delegada a fn_LimpaCidade.
    -- Centraliza a lógica — manutenção futura em um único lugar.
    dbo.fn_LimpaCidade(vnd.seller_city)                                   AS cidade_vendedor,

    vnd.seller_state                                                      AS estado_vendedor_sigla,  -- sigla (ex: "SP"); distinto de vw_dim_vendedor.estado_vendedor (nome completo)
    ped.order_id                                                          AS pedido_id,
    CAST(ped.order_purchase_timestamp AS DATE)                            AS data_pedido,
    COALESCE(prd.product_category_name, 'Sem Categoria')                  AS categoria,

    -- Preço e frete em reais: fonte armazena em centavos (ex: 1890 = R$ 18,90).
    ite.price          / 100.0                                            AS preco,
    ite.freight_value  / 100.0                                            AS frete,

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
    END                                                                   AS status_entrega

FROM dbo.olist_orders_dataset               AS ped
INNER JOIN dbo.olist_order_items_dataset    AS ite  ON ite.order_id   = ped.order_id
INNER JOIN dbo.olist_sellers_dataset        AS vnd  ON vnd.seller_id  = ite.seller_id
INNER JOIN dbo.olist_products_dataset       AS prd  ON prd.product_id = ite.product_id
WHERE ped.order_status                    = 'delivered'
    AND ped.order_delivered_customer_date IS NOT NULL
    AND ped.order_purchase_timestamp      >= '2017-01-01';  -- remove 2016 fragmentado (329 pedidos em 3 meses)


GO