USE [OLIST]
GO

/*
 * ============================================================
 * OLIST — SCRIPT DE DEPLOYMENT COMPLETO
 * ============================================================
 *
 * Objetivo:    Criar todos os objetos do banco na ordem correta
 *              de dependência. Executar este script em um banco
 *              OLIST já populado com as tabelas-fonte do Kaggle.
 *
 * Pré-requisito:
 *   As tabelas-fonte abaixo devem existir antes de rodar este script.
 *   Baixar o dataset em: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
 *   Importar os CSVs para o banco OLIST com os nomes exatos:
 *
 *     olist_customers_dataset
 *     olist_order_items_dataset
 *     olist_order_payments_dataset
 *     olist_order_reviews_dataset
 *     olist_orders_dataset
 *     olist_products_dataset
 *     olist_sellers_dataset
 *     product_category_name_translation
 *
 *   ATENÇÃO — importação dos valores monetários:
 *   Os campos price e freight_value devem ser importados como
 *   inteiros (sem casas decimais). O script divide por 100.0
 *   para converter centavos em reais. Se a importação preservar
 *   o decimal original do CSV (ex: 58.90), remover o / 100.0
 *   nas views vw_comercial, vw_logistica e vw_vendedores.
 *
 * Ordem de execução:
 *   1. fn_LimpaCidade          — sem dependências
 *   2. fn_TitleCase            — sem dependências
 *   3. vw_dim_estado           — sem dependências
 *   4. vw_dim_forma_pagamento  — sem dependências
 *   5. dim_categoria           — sem dependências (⚠ DROP + CREATE — ver aviso)
 *   6. vw_dim_vendedor         — depende de: fn_LimpaCidade, vw_dim_estado
 *   7. vw_avaliacoes           — depende de: olist_order_reviews_dataset, olist_orders_dataset
 *   8. vw_comercial            — depende de: fn_TitleCase, tabelas-fonte
 *   9. vw_logistica            — depende de: tabelas-fonte
 *  10. vw_vendedores           — depende de: fn_LimpaCidade, tabelas-fonte
 *
 * Reexecução:
 *   Todos os objetos usam CREATE OR ALTER — podem ser reexecutados
 *   sem erro em qualquer momento, exceto dim_categoria (ver item 5).
 *
 * ============================================================
 */


-- ============================================================
-- 1. fn_LimpaCidade
-- Normaliza seller_city: remove sufixos de UF, corrige typos.
-- Sem dependências — deve ser o primeiro objeto criado.
-- ============================================================
:r fn_LimpaCidade.sql


-- ============================================================
-- 2. fn_TitleCase
-- Converte string para Title Case (equivalente ao Text.Proper).
-- Sem dependências — deve preceder vw_comercial.
-- ============================================================
:r fn_TitleCase.sql


-- ============================================================
-- 3. vw_dim_estado
-- Dimensão inline dos 27 estados brasileiros com nome e região.
-- Sem dependências — deve preceder vw_dim_vendedor.
-- ============================================================
:r vw_dim_estado.sql


-- ============================================================
-- 4. vw_dim_forma_pagamento
-- Dimensão inline das formas de pagamento com labels em português.
-- Sem dependências.
-- ============================================================
:r vw_dim_forma_pagamento.sql


-- ============================================================
-- 5. dim_categoria
-- Dimensão de categorias com mapeamento snake_case → português.
-- ⚠ ATENÇÃO: executa DROP TABLE + CREATE TABLE.
--   - Na primeira carga: comportamento esperado.
--   - Em reexecuções: APAGA E RECRIA a tabela integralmente.
--     Não há perda de dado analítico (tabela de domínio estático),
--     mas qualquer FK ou índice adicional criado manualmente
--     será destruído. Reexecutar apenas quando necessário.
-- ============================================================
:r dim_categoria.sql


-- ============================================================
-- 6. vw_dim_vendedor
-- Dimensão de vendedores com cidade normalizada e estado por extenso.
-- Depende de: fn_LimpaCidade (passo 1), vw_dim_estado (passo 3).
-- ============================================================
:r vw_dim_vendedor.sql


-- ============================================================
-- 7. vw_avaliacoes
-- Avaliações de pedidos entregues com score e métricas de latência.
-- Depende de: olist_order_reviews_dataset, olist_orders_dataset.
-- ============================================================
:r vw_avaliacoes.sql


-- ============================================================
-- 8. vw_comercial
-- Visão comercial por pedido × item com dados de cliente,
-- produto, pagamento e valores em reais.
-- Depende de: fn_TitleCase (passo 2), tabelas-fonte.
-- ============================================================
:r vw_comercial.sql


-- ============================================================
-- 9. vw_logistica
-- Desempenho logístico por pedido: frete, prazos, pontualidade.
-- Depende de: tabelas-fonte.
-- ============================================================
:r vw_logistica.sql


-- ============================================================
-- 10. vw_vendedores
-- Desempenho por vendedor × item: receita, frete, pontualidade.
-- Depende de: fn_LimpaCidade (passo 1), tabelas-fonte.
-- ============================================================
:r vw_vendedores.sql


-- ============================================================
-- VERIFICAÇÃO FINAL
-- Executar após o deployment para confirmar contagens esperadas.
-- ============================================================
SELECT 'vw_comercial'          AS objeto, COUNT(*) AS total_linhas FROM dbo.vw_comercial          UNION ALL
SELECT 'vw_logistica',                    COUNT(*)                 FROM dbo.vw_logistica           UNION ALL
SELECT 'vw_vendedores',                   COUNT(*)                 FROM dbo.vw_vendedores          UNION ALL
SELECT 'vw_avaliacoes',                   COUNT(*)                 FROM dbo.vw_avaliacoes          UNION ALL
SELECT 'vw_dim_vendedor',                 COUNT(*)                 FROM dbo.vw_dim_vendedor        UNION ALL
SELECT 'vw_dim_estado',                   COUNT(*)                 FROM dbo.vw_dim_estado          UNION ALL
SELECT 'vw_dim_forma_pagamento',          COUNT(*)                 FROM dbo.vw_dim_forma_pagamento UNION ALL
SELECT 'dim_categoria',                   COUNT(*)                 FROM dbo.dim_categoria;

/*
 * Contagens esperadas após deployment com dataset Olist completo:
 *
 *   vw_comercial         → 109.872
 *   vw_logistica         →  96.203
 *   vw_vendedores        → 109.872
 *   vw_avaliacoes        →  96.087
 *   vw_dim_vendedor      →   3.095
 *   vw_dim_estado        →      27
 *   vw_dim_forma_pagamento →     6
 *   dim_categoria        →      74
 *
 * Qualquer divergência indica problema na importação dos CSVs.
 */
