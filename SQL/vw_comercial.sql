USE [OLIST]
GO

/****** Object:  View [dbo].[vw_comercial]    Script Date: 08/05/2026 16:25:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
 * Objetivo:    Visão comercial consolidada por pedido entregue,
 *              unindo dados de cliente, produto, pagamento e
 *              valores financeiros. Base para análises de receita,
 *              mix de produtos e comportamento de pagamento.
 *
 * GRAIN (o que uma linha representa):
 *   Uma linha por combinação PEDIDO × ITEM.
 *   Pedidos com múltiplos itens geram múltiplas linhas.
 *
 *   → Para receita bruta total: SUM(valor_total) — soma todos os itens.
 *   → Para ticket médio por pedido: SUM(valor_total) / COUNT(DISTINCT pedido_id).
 *   → Para análise por categoria: SUM(preco) GROUP BY categoria.
 *   → Para métrica no nível de pedido único: sempre agrupar por pedido_id.
 *
 * Filtros:     Apenas pedidos com status 'delivered' E com data de entrega
 *              registrada (order_delivered_customer_date IS NOT NULL).
 *              Sem esse segundo filtro, 8 pedidos com status 'delivered'
 *              mas sem data de entrega real entravam na view gerando
 *              inconsistência com VW_LOGISTICA (que filtra pela data).
 *              Pagamentos tipo 'not_defined' excluídos da seleção
 *              principal; pedidos sem pagamento mapeado recebem 'Outros'.
 *              Pedidos anteriores a 2017 excluídos — 2016 contém apenas
 *              329 pedidos em 3 meses fragmentados (set/out/dez), sem
 *              valor analítico e distorcem comparativos de período.
 *
 * Depende de:  dbo.olist_orders_dataset
 *              dbo.olist_customers_dataset
 *              dbo.olist_order_items_dataset
 *              dbo.olist_products_dataset
 *              dbo.olist_order_payments_dataset
 *              dbo.fn_TitleCase  (função auxiliar — criar antes desta view)
 *
 * Valores monetários:
 *   Campos armazenados em CENTAVOS na fonte (ex: 5890 = R$ 58,90).
 *   A divisão por 100.0 converte para reais decimais.
 *   NÃO remover essa divisão.
 *
 * Limitações:  A forma de pagamento exibida é a de maior valor no
 *              pedido (critério de desempate: payment_value DESC).
 *              Pedidos com múltiplos pagamentos de mesmo valor máximo
 *              recebem um tipo de forma não determinística — aceitável
 *              para análise de mix, não para auditoria financeira.
 *
 * Correções aplicadas:
 *   - cidade_cliente: fn_TitleCase normaliza o lowercase da fonte
 *     ("sao paulo" → "Sao Paulo"). O Power Query não aplica transformação
 *     nesta coluna, portanto a normalização é feita aqui.
 */

CREATE OR ALTER VIEW [dbo].[vw_comercial] AS

-- ============================================================
-- CTE: pagamentos_ranqueados
-- Ranqueia os pagamentos de cada pedido por valor decrescente,
-- descartando o tipo 'not_defined' (dado incompleto na fonte).
-- Separada em CTE própria para facilitar leitura e debugging.
-- ============================================================
WITH pagamentos_ranqueados AS (

    SELECT
        order_id,
        payment_type,
        payment_installments,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY payment_value DESC
        )                   AS rn
    FROM dbo.olist_order_payments_dataset
    WHERE payment_type <> 'not_defined'  -- exclui registros sem tipo de pagamento definido

),

-- ============================================================
-- CTE: pagamento_principal
-- Filtra apenas o pagamento de maior valor por pedido (rn = 1),
-- garantindo exatamente uma linha por pedido para o JOIN final.
-- ============================================================
pagamento_principal AS (

    SELECT
        order_id,
        payment_type            AS forma_pagamento,
        payment_installments    AS parcelas
    FROM pagamentos_ranqueados
    WHERE rn = 1  -- mantém apenas o pagamento de maior valor por pedido

)

-- ============================================================
-- SELECT FINAL
-- Combina pedido, cliente, item, produto e pagamento.
-- LEFT JOIN em pagamento_principal preserva pedidos sem
-- pagamento mapeado (recebem 'Outros' via COALESCE).
-- Filtro duplo no WHERE: status 'delivered' + data de entrega
-- não nula — garante consistência com VW_LOGISTICA.
-- ============================================================
SELECT
    ped.order_id                                                            AS pedido_id,
    CAST(ped.order_purchase_timestamp AS DATE)                              AS data_pedido,
    cli.customer_state                                                      AS estado_cliente,

    -- Title Case aplicado aqui pois o Power Query não transforma esta coluna.
    -- Fonte original em lowercase: "sao paulo" → "Sao Paulo"
    dbo.fn_TitleCase(cli.customer_city)                                     AS cidade_cliente,

    COALESCE(prd.product_category_name, 'Sem Categoria')                    AS categoria,
    COALESCE(pg.forma_pagamento, 'Outros')                                  AS forma_pagamento,

    -- Parcelas: COALESCE para pedidos sem pagamento mapeado assumem 1 parcela.
    -- Decisão conservadora: melhor subestimar parcelamento do que registrar NULL.
    COALESCE(pg.parcelas, 1)                                                AS parcelas,

    -- Preço, frete e total em reais: fonte armazena em centavos (ex: 5890 = R$ 58,90).
    ite.price          / 100.0                                              AS preco,
    ite.freight_value  / 100.0                                              AS frete,
    (ite.price + ite.freight_value) / 100.0                                 AS valor_total

FROM dbo.olist_orders_dataset               AS ped
INNER JOIN dbo.olist_customers_dataset      AS cli  ON cli.customer_id = ped.customer_id
INNER JOIN dbo.olist_order_items_dataset    AS ite  ON ite.order_id    = ped.order_id
INNER JOIN dbo.olist_products_dataset       AS prd  ON prd.product_id  = ite.product_id
LEFT  JOIN pagamento_principal              AS pg   ON pg.order_id     = ped.order_id
WHERE ped.order_status                    = 'delivered'
    AND ped.order_delivered_customer_date IS NOT NULL    -- exclui 8 pedidos delivered sem data real de entrega
    AND ped.order_purchase_timestamp      >= '2017-01-01';  -- remove 2016 fragmentado (329 pedidos em 3 meses)

GO


