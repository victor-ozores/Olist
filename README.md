<img src="./assets/banner.png" width="100%" alt="Olist E-Commerce Analytics" />

<div align="center">

# 🛒 Olist E-Commerce — Analytics Dashboard

**Power BI · SQL Server · DAX · Power Query**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-victor--ozores-0077B5?style=flat&logo=linkedin)](https://linkedin.com/in/victor-ozores/)
[![Portfolio](https://img.shields.io/badge/Portfolio-xperiun-6C47FF?style=flat)](https://app.xperiun.com/in/victor-ozores)
[![GitHub](https://img.shields.io/badge/GitHub-victor--ozores-181717?style=flat&logo=github)](https://github.com/victor-ozores)

</div>

---

## 📌 Resumo

Projeto construído para praticar ETL em SQL usando o dataset público do Olist — o maior marketplace brasileiro — com 100 mil pedidos de 2017 a 2018.

A ideia foi criar uma camada SQL intermediária real antes dos dados chegarem ao Power BI: views com filtros de qualidade, funções de normalização, CTEs para resolver problemas da fonte e separação clara de grain por tabela de fato. O Power BI consome essas views e adiciona as métricas, comparativos YOY e os visuais customizados em SVG.

O resultado são quatro páginas que cobrem a operação de ponta a ponta: receita por categoria e estado, SLA logístico por região, performance por vendedor e satisfação dos clientes cruzada com pontualidade de entrega.

## 🔗 Ver Dashboard Online

[![Power BI](https://img.shields.io/badge/Power%20BI-Abrir%20Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)](https://app.powerbi.com/view?r=eyJrIjoiOTU5ZmQ0ZjgtMDk1NC00Yjc1LWIwOWItMTg2ZDRlNDcyMzBlIiwidCI6IjY1OWNlMmI4LTA3MTQtNDE5OC04YzM4LWRjOWI2MGFhYmI1NyJ9&pageName=b5340fed4ab16024cace)

---

## 💡 O Que Ele Responde

- Quais categorias e estados concentram a maior parte da receita?
- A operação logística melhorou ou piorou ao longo dos meses?
- Quais estados têm a maior taxa de atraso e o maior tempo médio de entrega?
- Pedidos atrasados recebem avaliações piores do que pedidos no prazo?
- Quais vendedores têm a maior receita média por pedido, e em quais cidades estão concentrados?

---

## 📊 Páginas do Dashboard

| Página | O que entrega |
|--------|---------------|
| **Visão Geral** | KPIs consolidados: receita, pedidos, ticket médio, % entregas no prazo, score médio — com variação YOY e distribuição de avaliações |
| **Comercial** | Evolução mensal da receita com variação MoM, ranking de categorias e participação por estado |
| **Logística** | SLA mensal em p.p., ranking de estados por taxa de atraso e tempo médio de entrega vs. média global |
| **Vendedores** | Receita total e média por estado e cidade, top categorias por receita média por vendedor |

---

## 📸 Preview

### Visão Geral
![Visão Geral](./assets/visao-geral.png)

### Comercial
![Comercial](./assets/comercial.png)

### Logística
![Logística](./assets/logistica.png)

### Vendedores
![Vendedores](./assets/vendedores.png)

---

<details>
<summary>⚙️ Detalhes Técnicos</summary>

<br>

### Arquitetura

```
Kaggle Dataset (8 CSVs)
  └── SQL Server — banco OLIST
        ├── fn_LimpaCidade         ← normaliza seller_city (typos, padrões compostos)
        ├── fn_TitleCase           ← title case para customer_city
        ├── vw_dim_estado          ← 27 estados com nome completo e região
        ├── vw_dim_forma_pagamento ← formas de pagamento com labels em português
        ├── vw_dim_vendedor        ← dimensão de vendedores com cidade e estado
        ├── dim_categoria          ← 74 categorias com mapeamento snake_case → português
        ├── vw_comercial           ← pedido × item: receita, categoria, cliente, pagamento
        ├── vw_logistica           ← pedido: frete total, prazos, status de entrega
        ├── vw_vendedores          ← pedido × item × vendedor: receita e pontualidade
        └── vw_avaliacoes          ← avaliações com score, latência e indicadores binários
              │
              ▼ Power Query (Import Mode)
              │
              ▼ Star Schema
        ├── Fact_Comercial
        ├── Fact_Logistica
        ├── Fact_Vendedores
        ├── Fact_Avaliacoes
        ├── Dim_Calendario (tabela DAX, 26 colunas)
        ├── Dim_Estado
        ├── Dim_Forma_Pagamento
        ├── Dim_Categoria
        └── Dim_Vendedor
              │
              ▼ ~90 medidas DAX · 7 UDFs
              │
              ▼ Report (4 páginas)
```

---

### Camada SQL — Por Que Existe

As 8 tabelas do Kaggle chegam brutas. A camada SQL resolve os problemas antes dos dados chegarem ao Power BI:

| Problema na fonte | Solução na view |
|-------------------|----------------|
| Pedidos cancelados, em trânsito ou sem data de entrega real distorcem métricas | Filtro `status = 'delivered'` + `order_delivered_customer_date IS NOT NULL` em todas as facts |
| 2016 tem só 267 pedidos em 3 meses não consecutivos — distorce YOY | Filtro `>= '2017-01-01'` centralizado em cada view |
| 2.961 pedidos com múltiplos métodos de pagamento — JOIN direto multiplicaria linhas | CTE com `ROW_NUMBER()` na `vw_comercial` elege o pagamento de maior valor por pedido |
| 1.278 pedidos com múltiplos vendedores — frete é por item, não por pedido | CTEs com `SUM() OVER` + `ROW_NUMBER()` na `vw_logistica` somam frete total e elegem vendedor principal |
| `seller_city` com typos, CEPs e padrões como `carapicuiba / sao paulo` | `fn_LimpaCidade` centraliza 18 correções usadas por duas views sem duplicar lógica |
| Translation table do Kaggle traduz categorias para inglês, não português | `dim_categoria` com mapeamento manual de 74 categorias para PT-BR |

---

### Modelagem — Decisões Relevantes

**4 facts com grains diferentes** — `vw_comercial` e `vw_vendedores` são pedido × item (109.872 linhas), `vw_logistica` é pedido (96.203) e `vw_avaliacoes` é avaliação (96.087). Grains diferentes exigem tabelas separadas — misturá-los geraria dupla contagem em qualquer métrica.

**`Dim_Estado` com relacionamento inativo em `Fact_Logistica`** — o modelo precisa filtrar logística por estado do cliente e por estado do vendedor. O relacionamento ativo usa `Estado Cliente`; as medidas de logística por estado ativam o segundo via `USERELATIONSHIP`, dando controle preciso sobre qual coluna está sendo filtrada em cada visual.

**`TREATAS` para cruzar avaliações com logística** — `Fact_Avaliacoes` e `Fact_Logistica` compartilham `pedido_id` mas facts não se relacionam entre si em star schema. `Score Médio No Prazo` e `Score Médio Atrasados` usam `TREATAS` para criar a relação em tempo de query sem adicionar relacionamentos entre fatos.

---

### DAX — Medidas e UDFs

**~90 medidas** organizadas em display folders por domínio:

| Pasta | Conteúdo |
|-------|----------|
| `Comercial\Calculos` | Receita, pedidos, ticket médio, itens vendidos, MoM, participação por categoria e estado |
| `Logistica\Calculos` | Total entregas, % no prazo, média de dias, atrasos por estado com `USERELATIONSHIP` |
| `Vendedores\Calculos` | Total vendedores, receita média, pedidos por vendedor |
| `Avaliacoes\Calculos` | Score médio, Score No Prazo e Score Atrasados via `TREATAS` |
| `*/Eixo` | Teto e piso dinâmicos de eixo Y via `fxEixoMax` / `fxEixoMin` |
| `*/Imagens` | Cards KPI e donut de distribuição de score em SVG gerado por DAX |
| `Config\Cores` | 12 medidas `Cfg *` com HEX — paleta global propagada para todos os SVGs |

**7 User Defined Functions (DAX Preview):**

| UDF | O que faz |
|-----|-----------|
| `fxFormatoMoeda(Valor)` | Escala automática por magnitude: `R$ 0` / `R$ 8.722` / `R$ 27,0K` / `R$ 1,2M` |
| `fxFormatoRotulo(Valor)` | Igual, sem prefixo `R$` — para rótulos de gráficos de linha |
| `fxEixoMax(Valor, Buffer)` | Teto do eixo Y arredondado com buffer percentual |
| `fxEixoMin(Valor, Buffer)` | Piso do eixo Y para valores negativos |
| `fxSvgMontarCard(...)` | Gera SVG de card KPI com ícone, seta animada via CSS e subtexto contextual |
| `fxSvgMontarDonut(...)` | Gera SVG de donut com até 5 segmentos e legenda animada |
| `fxSvgMontarGauge(...)` | Gera SVG de gauge semicircular com animação de crescimento |

Os cards KPI são implementados via `dataCategory = ImageUrl` com SVG gerado em DAX — permite seta animada, subtexto calculado e supressão automática de YOY quando o período anterior é insuficiente.

---

### Padrões Aplicados

| Padrão | Por quê |
|--------|---------|
| Nomenclatura SQLBI: `Fact_`, `Dim_`, `_Medidas` | Modelo autoexplicativo — qualquer analista entende a estrutura ao abrir |
| `VAR/RETURN` em todas as medidas não triviais | Evita calcular a mesma expressão duas vezes e facilita leitura |
| `DIVIDE()` onde denominador pode ser zero | Retorna BLANK em vez de erro — preserva a otimização de células vazias do VertiPaq |
| `FILTER(ALL())` em vez de `FILTER(table)` | Evita iteração desnecessária quando um predicado booleano já resolve |
| `USERELATIONSHIP` em vez de relacionamento bidirecional | Controle explícito de qual coluna está ativa em cada medida — sem efeitos colaterais no modelo |
| Date Table marcada + Auto date/time desabilitado | Garante que as funções de time intelligence funcionem e remove hierarquias automáticas que inflam o modelo |
| `Remove Other Columns` no Power Query | Protege o pipeline — se a fonte adicionar colunas, o refresh não quebra |

---

### Limitações Conhecidas

**Qualidade de `customer_city`** — o campo vem em lowercase na fonte com variações de grafia não tratadas (ex: `santa barbara d'oeste` e `santa barbara d oeste` como entradas distintas). `seller_city` foi normalizada via `fn_LimpaCidade` porque é chave de análise de performance por vendedor. `customer_city` é usado apenas como texto descritivo nos gráficos — o impacto analítico das inconsistências é mínimo e corrigir exigiria uma estrutura de de-para que não faz sentido para uma base estática.

</details>

---

<div align="center">

Feito por **Victor Ozores** · [linkedin.com/in/victor-ozores](https://linkedin.com/in/victor-ozores/) · [app.xperiun.com/in/victor-ozores](https://app.xperiun.com/in/victor-ozores)

</div>