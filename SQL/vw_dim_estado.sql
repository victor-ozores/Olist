USE [OLIST]
GO

/****** Object:  View [dbo].[vw_dim_estado]    Script Date: 08/05/2026 16:26:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
 * Objetivo:    Dimensão de estados brasileiros com nome completo
 *              e região geográfica para enriquecimento de análises
 *              por localidade no dashboard.
 *
 * GRAIN (o que uma linha representa):
 *   Uma linha por estado (27 linhas — 26 estados + DF).
 *
 * Filtros:     Nenhum — domínio completo dos 27 estados brasileiros.
 *
 * Depende de:  Nenhuma tabela de origem.
 *              Valores definidos inline na view.
 *
 * Relacionamento no Power BI:
 *   vw_dim_vendedor usa LEFT JOIN nesta view para resolver
 *   seller_state (sigla) → estado_nome (nome completo).
 */

CREATE OR ALTER VIEW [dbo].[vw_dim_estado] AS

SELECT estado_sigla, estado_nome, regiao
FROM (VALUES
    ('AC', 'Acre',                  'Norte'),
    ('AL', 'Alagoas',               'Nordeste'),
    ('AM', 'Amazonas',              'Norte'),
    ('AP', 'Amapá',                 'Norte'),
    ('BA', 'Bahia',                 'Nordeste'),
    ('CE', 'Ceará',                 'Nordeste'),
    ('DF', 'Distrito Federal',      'Centro-Oeste'),
    ('ES', 'Espírito Santo',        'Sudeste'),
    ('GO', 'Goiás',                 'Centro-Oeste'),
    ('MA', 'Maranhão',              'Nordeste'),
    ('MG', 'Minas Gerais',          'Sudeste'),
    ('MS', 'Mato Grosso do Sul',    'Centro-Oeste'),
    ('MT', 'Mato Grosso',           'Centro-Oeste'),
    ('PA', 'Pará',                  'Norte'),
    ('PB', 'Paraíba',               'Nordeste'),
    ('PE', 'Pernambuco',            'Nordeste'),
    ('PI', 'Piauí',                 'Nordeste'),
    ('PR', 'Paraná',                'Sul'),
    ('RJ', 'Rio de Janeiro',        'Sudeste'),
    ('RN', 'Rio Grande do Norte',   'Nordeste'),
    ('RO', 'Rondônia',              'Norte'),
    ('RR', 'Roraima',               'Norte'),
    ('RS', 'Rio Grande do Sul',     'Sul'),
    ('SC', 'Santa Catarina',        'Sul'),
    ('SE', 'Sergipe',               'Nordeste'),
    ('SP', 'São Paulo',             'Sudeste'),
    ('TO', 'Tocantins',             'Norte')
) AS estados (estado_sigla, estado_nome, regiao);

GO


