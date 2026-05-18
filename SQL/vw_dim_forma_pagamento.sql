USE [OLIST]
GO

/****** Object:  View [dbo].[vw_dim_forma_pagamento]    Script Date: 08/05/2026 16:26:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
 * Objetivo:    Dimensão de formas de pagamento com labels em
 *              português para exibição no dashboard.
 *
 * GRAIN (o que uma linha representa):
 *   Uma linha por forma de pagamento. 6 linhas.
 *
 * Filtros:     Nenhum — domínio completo incluindo fallbacks.
 *
 * Depende de:  Nenhuma tabela de origem.
 *              Valores definidos inline na view.
 *
 * Limitações:  'not_defined' incluído para robustez, mesmo sendo
 *              excluído nas views de fato via WHERE payment_type <> 'not_defined'.
 *              'Outros' mapeia o COALESCE(pg.forma_pagamento, 'Outros')
 *              da vw_comercial para pedidos sem pagamento mapeado.
 *
 * Relacionamento no Power BI:
 *   Comercial[forma_pagamento] → [forma_pagamento_raw]  (ativo)
 */

CREATE OR ALTER VIEW [dbo].[vw_dim_forma_pagamento] AS

SELECT forma_pagamento_raw, forma_pagamento_nome
FROM (VALUES
    ('credit_card',  'Cartão de Crédito'),
    ('boleto',       'Boleto Bancário'),
    ('voucher',      'Voucher'),
    ('debit_card',   'Cartão de Débito'),
    ('not_defined',  'Não Definido'),
    ('Outros',       'Outros')
) AS pagamentos (forma_pagamento_raw, forma_pagamento_nome);

GO


