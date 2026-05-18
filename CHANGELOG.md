# Changelog

Todas as mudanças relevantes deste projeto serão documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

---

---

## [1.0.0] - 2026-05-08

### Added
- Lançamento inicial do projeto
- Dashboard com 4 páginas: Visão Geral, Comercial, Logística, Vendedores
- Camada SQL intermediária com 10 objetos: 2 funções, 4 views de dimensão, 4 views de fato
- Filtros de qualidade centralizados nas views: `status = 'delivered'`, data de entrega não nula, exclusão de 2016
- `fn_LimpaCidade` — normaliza 18 padrões problemáticos em `seller_city` (typos, CEP no lugar de cidade, formatos compostos cidade/UF)
- `dim_categoria` — tabela física com mapeamento manual de 74 categorias do snake_case da fonte para português
- `vw_logistica` com CTEs internas para consolidar frete total por pedido e eleger vendedor principal em pedidos multi-seller
- `vw_comercial` com CTE de pagamentos ranqueados para resolver pedidos com múltiplos métodos de pagamento
- Star schema com 4 facts (grains distintos) e 5 dimensões
- `Dim_Calendario` em DAX com 26 colunas de contexto temporal — marcada como Date Table
- 12 relacionamentos no modelo: 11 ativos, 1 inativo ativado via `USERELATIONSHIP` nas medidas de logística por estado
- ~90 medidas DAX organizadas em display folders por domínio
- Medidas `Score Médio No Prazo` e `Score Médio Atrasados` via `TREATAS` — relacionamento virtual entre facts sem poluir o modelo
- Supressão automática de comparação YOY quando período anterior é insuficiente (`BaseInsuf`)
- Variação MoM da receita em % e variação MoM do SLA logístico em pontos percentuais
- 7 UDFs DAX (Preview): `fxFormatoMoeda`, `fxFormatoRotulo`, `fxEixoMax`, `fxEixoMin`, `fxSvgMontarCard`, `fxSvgMontarDonut`, `fxSvgMontarGauge`
- Cards KPI em SVG gerado por DAX com seta animada via CSS e subtexto contextual calculado — sem visuais de marketplace
- Format string dinâmico por magnitude via `formatStringDefinition` — escala automática entre R$, K e M conforme o valor filtrado
- Paleta de cores global via medidas `Cfg *` — alterar uma cor propaga para todos os SVGs do modelo