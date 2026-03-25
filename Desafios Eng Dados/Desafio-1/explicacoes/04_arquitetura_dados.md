# 04 — Arquitetura de Dados em Maestria

> **Por que este arquivo?**
> Este desafio usa CSV + SQLite + Python. Em produção, a mesma lógica rodaria em S3 + BigQuery + dbt. Entender como escalar é o que diferencia um analista de dados de um **engenheiro de dados**.

---

## Por que SQLite aqui e não PostgreSQL?

### Trade-offs por contexto:

| Critério | SQLite | PostgreSQL |
|----------|--------|------------|
| Setup | Zero — embedded na biblioteca | Servidor separado + config |
| Concorrência | 1 writer por vez | Múltiplos readers + writers |
| Escalabilidade | Até ~1GB confortável | Terabytes |
| Certo para | Análises locais, protótipos | Produção, multi-usuário |

**Regra prática**: se o dado cabe em memória e uma pessoa usa, SQLite é a escolha correta. Não existe "banco de dados errado" — existe "banco de dados inadequado para o contexto".

---

## ETL vs ELT — onde este desafio se encaixa

### ETL (Extract → Transform → Load)
```
CSV → [Python limpa dados] → [Banco já recebe limpo]
```
Era o padrão quando bancos de dados eram caros e lentos para transformar.

### ELT (Extract → Load → Transform)
```
CSV → [Carrega RAW no banco] → [SQL transforma dentro do banco]
```
É o padrão moderno (BigQuery, Snowflake, dbt) porque:
- Computação no banco é otimizada (columnar, vetorizada)
- Os dados brutos são preservados como fonte da verdade
- Transformações são auditáveis como código (dbt models)

### Este desafio usa ELT:
1. `carregar_db.py` → carrega o CSV raw no SQLite (`vendas`)
2. `desafio_parte1.sql` → transforma dentro do banco (SELECT, GROUP BY)
3. `resumo_vendas` → tabela materializada = resultado de transformação

---

## Como o desafio escalaria para produção?

### Arquitetura Moderna de Dados (Data Lakehouse)

```
                    ┌─────────────────┐
  CSV/API/ERP  ──►  │   Data Lake     │  S3 / GCS
                    │   (RAW zone)    │  Parquet, Avro
                    └────────┬────────┘
                             │ dbt / Spark
                    ┌────────▼────────┐
                    │  Data Warehouse │  BigQuery / Snowflake
                    │  (curated zone) │  Dimensional models
                    └────────┬────────┘
                             │ SQL / BI
                    ┌────────▼────────┐
                    │  Analytics Layer│  Looker / Metabase
                    │  (serving zone) │  ← ou nosso Dashboard
                    └─────────────────┘
```

### Equivalências deste desafio na arquitetura real:

| Nossa solução | Produção equivalente |
|---------------|---------------------|
| `vendas_desafio.csv` | S3 bucket `s3://empresa/raw/vendas/` |
| `carregar_db.py` | Apache Airflow DAG + AWS Glue job |
| `desafio1.db` (SQLite) | BigQuery dataset `vendas_raw` |
| `desafio_parte1.sql` | dbt model `mart_vendas_resumo.sql` |
| `resumo_vendas` (tabela) | dbt Materialized View |
| `faturamento_categoria.png` | Dashboard Looker Studio |
| `Desafio-2-Dashboard/` | **Frontend customizado** (este projeto) |

---

## O que é uma Fact Table vs Dimension Table?

### Kimball Dimensional Modeling (o padrão da indústria):

```sql
-- FACT TABLE: evento de negócio mensurável
CREATE TABLE fact_vendas (
    id_venda     INT PRIMARY KEY,
    id_cliente   INT REFERENCES dim_cliente(id),
    id_produto   INT REFERENCES dim_produto(id),
    id_vendedor  INT REFERENCES dim_vendedor(id),
    id_data      INT REFERENCES dim_data(id),
    quantidade   INT,
    preco_unit   DECIMAL(10,2),
    faturamento  DECIMAL(10,2)   -- armazenado aqui por convenção Kimball
);

-- DIMENSION TABLES: contexto do evento
CREATE TABLE dim_produto (
    id        INT PRIMARY KEY,
    produto   VARCHAR,
    categoria VARCHAR,
    marca     VARCHAR
);

CREATE TABLE dim_data (
    id    INT PRIMARY KEY,
    data  DATE,
    ano   INT, mes INT, dia INT,
    dia_semana VARCHAR, trimestre INT
);
```

### Onde `resumo_vendas` se encaixa?
É uma **aggregate table** ou **mart** — uma tabela pré-calculada que serve a camada de analytics. No dbt, seria um model `marts/`:

```sql
-- dbt: models/marts/mart_vendas_por_produto.sql
{{ config(materialized='table') }}

SELECT
    produto,
    SUM(quantidade)                       AS total_unidades,
    SUM(quantidade * preco_unitario)      AS faturamento_total,
    AVG(quantidade * preco_unitario)      AS ticket_medio,
    COUNT(DISTINCT cliente)               AS clientes_unicos
FROM {{ ref('stg_vendas') }}
GROUP BY produto
```

---

## Índices: a diferença entre 10ms e 10s

```sql
-- SEM índice: Full Table Scan = lê todas as 10.000 linhas
SELECT * FROM vendas WHERE categoria = 'Eletrônicos';

-- COM índice: Index Seek = lê apenas as linhas relevantes
CREATE INDEX idx_categoria ON vendas(categoria);
```

### Quando criar índices:
- Colunas usadas em `WHERE` frequentemente
- Colunas de JOIN (`id_cliente`, `id_produto`)
- Colunas de `ORDER BY` em queries de alta frequência

### Quando NÃO criar índices:
- Tabelas pequenas (< 10.000 linhas: full scan é rápido)
- Colunas com baixa cardinalidade e queries de escrita intensiva (índices custam em INSERT/UPDATE)
- Campos derivados (indexe o campo base, compute na query)

---

## Evolução do Stack: do CSV ao Data Mesh

### Nível 1 — Iniciante (este desafio)
```
CSV → SQLite → Python → matplotlib
```

### Nível 2 — Júnior
```
PostgreSQL → pandas + Jupyter → Tableau Public
```

### Nível 3 — Pleno
```
S3 (Parquet) → Airflow → dbt → Redshift → Metabase
```

### Nível 4 — Sênior
```
Kafka (streaming) → Spark → Delta Lake → dbt + Great Expectations →
BigQuery → dbt Exposures → Looker Studio / Frontend customizado
```

### Nível 5 — Data Mesh (arquitetura distribuída)
```
Domínios de negócio (produto, vendas, financeiro) como data products autônomos
com contrato de interface, SLAs de qualidade e descoberta via catálogo (DataHub)
```

---

## Por que o Dashboard HTML supera Looker/BI?

| Capabilidade | Looker Studio | Power BI | Nosso Dashboard |
|-------------|--------------|----------|-----------------|
| Customização visual | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Cross-filtering granular | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Deploy (sem conta/licença) | ❌ | ❌ | GitHub Pages |
| Performance com 10k rows | Lento | Médio | Imediato (in-memory) |
| Integração em produto | Difícil | Complexo | `<iframe>` ou direto |
| Custo | Grátis/Pago | Pago | **Zero** |

**O diferencial**: ferramentas de BI são produtos genéricos ajustados ao seu caso. Um dashboard customizado **é** o seu caso — desde o pixel até a lógica de negócio.
