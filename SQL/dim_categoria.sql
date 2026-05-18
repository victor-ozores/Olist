USE [OLIST]
GO

/****** Object:  Table [dbo].[dim_categoria]    Script Date: 08/05/2026 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
 * Objetivo:    Dimensão de categorias de produto com mapeamento de
 *              snake_case (fonte Olist) para nomes em português
 *              formatados para exibição no dashboard.
 *
 * GRAIN (o que uma linha representa):
 *   Uma linha por categoria. 74 linhas no total:
 *   71 da translation table + 2 sem tradução (pc_gamer,
 *   portateis_cozinha_e_preparadores_de_alimentos) + 1 para
 *   produtos sem categoria mapeada na fonte (Sem Categoria).
 *
 * Filtros:     Nenhum — tabela de domínio completa.
 *
 * Depende de:  Nenhuma dependência de runtime.
 *              Populada via INSERT estático.
 *              Para adicionar nova categoria: INSERT de uma linha.
 *
 * Relacionamento no Power BI:
 *   dim_categoria[categoria_raw] → Comercial[categoria]   (ativo)
 *   dim_categoria[categoria_raw] → Vendedores[categoria]  (ativo)
 *
 * Limitações:  categoria_raw é a chave de JOIN com as views de fato.
 *              Deve corresponder exatamente ao valor retornado pelo
 *              COALESCE(prd.product_category_name, 'Sem Categoria')
 *              nas views vw_comercial e vw_vendedores.
 *
 * ⚠ AVISO — DROP TABLE:
 *   O bloco abaixo APAGA e RECRIA a tabela integralmente.
 *   - Na primeira carga: comportamento esperado.
 *   - Em reexecuções: todos os dados são destruídos antes do INSERT.
 *     Não há perda analítica (tabela de domínio estático), mas
 *     qualquer FK ou índice adicional criado manualmente será perdido.
 *   Reexecutar apenas quando necessário (nova categoria ou correção).
 *   Tabelas de domínio não suportam CREATE OR ALTER — DROP + CREATE
 *   é o padrão correto para este tipo de objeto no SQL Server.
 */

-- ⚠ DESTRÓI E RECRIA A TABELA — ver aviso no cabeçalho antes de executar
IF OBJECT_ID('dbo.dim_categoria', 'U') IS NOT NULL
    DROP TABLE dbo.dim_categoria;
GO

CREATE TABLE dbo.dim_categoria (
    categoria_id    INT             NOT NULL    IDENTITY(1, 1),
    categoria_raw   VARCHAR(100)    NOT NULL,   -- chave de JOIN com as views de fato (snake_case da fonte)
    categoria_nome  VARCHAR(150)    NOT NULL,   -- nome em português para exibição no dashboard
    CONSTRAINT pk_dim_categoria      PRIMARY KEY (categoria_id),
    CONSTRAINT uq_dim_categoria_raw  UNIQUE      (categoria_raw)
);
GO

INSERT INTO dbo.dim_categoria (categoria_raw, categoria_nome)
VALUES
    ('agro_industria_e_comercio',                           'Agro Indústria e Comércio'),
    ('alimentos',                                           'Alimentos'),
    ('alimentos_bebidas',                                   'Alimentos e Bebidas'),
    ('artes',                                               'Artes'),
    ('artes_e_artesanato',                                  'Artes e Artesanato'),
    ('artigos_de_festas',                                   'Artigos de Festas'),
    ('artigos_de_natal',                                    'Artigos de Natal'),
    ('audio',                                               'Áudio'),
    ('automotivo',                                          'Automotivo'),
    ('bebes',                                               'Bebês'),
    ('bebidas',                                             'Bebidas'),
    ('beleza_saude',                                        'Beleza e Saúde'),
    ('brinquedos',                                          'Brinquedos'),
    ('cama_mesa_banho',                                     'Cama, Mesa e Banho'),
    ('casa_conforto',                                       'Casa e Conforto'),
    ('casa_conforto_2',                                     'Casa e Conforto II'),
    ('casa_construcao',                                     'Casa e Construção'),
    ('cds_dvds_musicais',                                   'CDs e DVDs Musicais'),
    ('cine_foto',                                           'Cine e Foto'),
    ('climatizacao',                                        'Climatização'),
    ('consoles_games',                                      'Consoles e Games'),
    ('construcao_ferramentas_construcao',                   'Ferramentas de Construção'),
    ('construcao_ferramentas_ferramentas',                  'Ferramentas'),
    ('construcao_ferramentas_iluminacao',                   'Iluminação'),
    ('construcao_ferramentas_jardim',                       'Ferramentas de Jardim'),
    ('construcao_ferramentas_seguranca',                    'Segurança Residencial'),
    ('cool_stuff',                                          'Produtos Diferenciados'),
    ('dvds_blu_ray',                                        'DVDs e Blu-Ray'),
    ('eletrodomesticos',                                    'Eletrodomésticos'),
    ('eletrodomesticos_2',                                  'Eletrodomésticos II'),
    ('eletronicos',                                         'Eletrônicos'),
    ('eletroportateis',                                     'Eletroportáteis'),
    ('esporte_lazer',                                       'Esporte e Lazer'),
    ('fashion_bolsas_e_acessorios',                         'Bolsas e Acessórios'),
    ('fashion_calcados',                                    'Calçados'),
    ('fashion_esporte',                                     'Moda Esportiva'),
    ('fashion_roupa_feminina',                              'Moda Feminina'),
    ('fashion_roupa_infanto_juvenil',                       'Moda Infanto-Juvenil'),
    ('fashion_roupa_masculina',                             'Moda Masculina'),
    ('fashion_underwear_e_moda_praia',                      'Moda Praia e Íntima'),
    ('ferramentas_jardim',                                  'Ferramentas de Jardim II'),
    ('flores',                                              'Flores'),
    ('fraldas_higiene',                                     'Fraldas e Higiene'),
    ('industria_comercio_e_negocios',                       'Indústria, Comércio e Negócios'),
    ('informatica_acessorios',                              'Informática e Acessórios'),
    ('instrumentos_musicais',                               'Instrumentos Musicais'),
    ('la_cuisine',                                          'La Cuisine'),
    ('livros_importados',                                   'Livros Importados'),
    ('livros_interesse_geral',                              'Livros de Interesse Geral'),
    ('livros_tecnicos',                                     'Livros Técnicos'),
    ('malas_acessorios',                                    'Malas e Acessórios'),
    ('market_place',                                        'Marketplace'),
    ('moveis_colchao_e_estofado',                           'Móveis, Colchão e Estofado'),
    ('moveis_cozinha_area_de_servico_jantar_e_jardim',      'Móveis de Cozinha e Área de Serviço'),
    ('moveis_decoracao',                                    'Móveis e Decoração'),
    ('moveis_escritorio',                                   'Móveis de Escritório'),
    ('moveis_quarto',                                       'Móveis de Quarto'),
    ('moveis_sala',                                         'Móveis de Sala'),
    ('musica',                                              'Música'),
    ('papelaria',                                           'Papelaria'),
    ('pc_gamer',                                            'PC Gamer'),
    ('pcs',                                                 'Computadores'),
    ('perfumaria',                                          'Perfumaria'),
    ('pet_shop',                                            'Pet Shop'),
    ('portateis_casa_forno_e_cafe',                         'Portáteis para Casa, Forno e Café'),
    ('portateis_cozinha_e_preparadores_de_alimentos',       'Portáteis para Cozinha e Preparadores'),
    ('relogios_presentes',                                  'Relógios e Presentes'),
    ('seguros_e_servicos',                                  'Seguros e Serviços'),
    ('sinalizacao_e_seguranca',                             'Sinalização e Segurança'),
    ('Sem Categoria',                                       'Sem Categoria'),    -- fallback do COALESCE(..., 'Sem Categoria') das views
    ('tablets_impressao_imagem',                            'Tablets, Impressão e Imagem'),
    ('telefonia',                                           'Telefonia'),
    ('telefonia_fixa',                                      'Telefonia Fixa'),
    ('utilidades_domesticas',                               'Utilidades Domésticas');
GO

-- Verificação: deve retornar 74
SELECT COUNT(*) AS total_categorias FROM dbo.dim_categoria;
GO