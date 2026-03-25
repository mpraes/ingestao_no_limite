# 01 — SQL Queries em Maestria

> **Por que este arquivo?**
> Resolver a query é nível júnior. Entender **por que** aquela query, quando usar alternativa e o que o banco de dados faz internamente — isso é nível sênior.

---

## Query 1 — Faturamento por Produto

```sql
SELECT produto,
       SUM(quantidade * preco_unitario) AS faturamento_total
FROM vendas
GROUP BY produto
ORDER BY faturamento_total DESC;
```

### Por que `SUM(quantidade * preco_unitario)`?
- **Nunca armazene faturamento pre-calculado** se os componentes (qty e preço) já existem. Calculá-lo na query evita inconsistências quando um valor é corrigido na fonte.
- `SUM(quantidade * preco_unitario)` é uma **aggregate expression** — o banco avalia `quantidade * preco_unitario` linha a linha *antes* de somar.

### Por que `GROUP BY produto`?
- SQL exige que toda coluna no `SELECT` que não seja agregada apareça no `GROUP BY`. `produto` é nossa dimensão de agrupamento, então está no `GROUP BY`. `SUM(...)` é uma função de agregação, então não precisa.
- **Anti-pattern comum**: colocar colunas no `GROUP BY` sem querer agrupá-las (resulta em cardinalidade errada).

### O que o SQLite faz internamente?
1. Full table scan de `vendas` (sem índice = O(n))
2. Hash table temporária: chave = produto, valor = soma acumulada
3. Ordenação do resultado por `faturamento_total DESC` (O(k log k) onde k = nº de produtos distintos)

### Alternativa PostgreSQL com Window Function:
```sql
SELECT DISTINCT produto,
       SUM(quantidade * preco_unitario) OVER (PARTITION BY produto) AS faturamento_total
FROM vendas
ORDER BY faturamento_total DESC;
```
> ⚠️ A versão com `GROUP BY` é preferível aqui; `OVER PARTITION BY` brilha quando você precisa da soma E de colunas não-agrupadas na mesma linha.

---

## Query 2 — Faturamento por Categoria

```sql
SELECT categoria,
       SUM(quantidade * preco_unitario) AS faturamento_total,
       COUNT(*) AS total_vendas
FROM vendas
GROUP BY categoria
ORDER BY faturamento_total DESC;
```

### Por que `COUNT(*)`?
- `COUNT(*)` conta todas as linhas do grupo, incluindo NULLs em qualquer coluna.
- `COUNT(coluna)` contaria apenas linhas onde aquela coluna não é NULL.
- Para contar transações (onde a linha inteira representa uma transação), `COUNT(*)` é semanticamente correto.

### Insight de negócio por trás dos números:
A diferença de faturamento entre Eletrônicos (~R$ 11,7M) e Livros (~R$ 0,7M) não significa que Livros performa mal. Significa que os **preços unitários** são ordens de magnitude diferentes. Para avaliar desempenho real, comparamos **margem**, não receita bruta.

---

## Query 3 — Ticket Médio por Produto

```sql
SELECT produto,
       ROUND(AVG(quantidade * preco_unitario), 2) AS ticket_medio
FROM vendas
GROUP BY produto
ORDER BY ticket_medio DESC;
```

### Por que `AVG()` e não `SUM()/COUNT()`?
Matematicamente idênticos para este caso (`AVG(x) = SUM(x)/COUNT(x)`), mas `AVG()` é mais legível e comunica intenção. Use `SUM()/COUNT()` quando quiser pesos diferentes ou filtros específicos no numerador.

### Por que `ROUND(..., 2)`?
Valores monetários devem ter precisão de centavos (2 casas decimais). Sem `ROUND`, SQLite pode retornar `1234.5999999998` (ponto flutuante). Em produção, armazene valores monetários em `INTEGER` (centavos) ou `NUMERIC/DECIMAL` — nunca em `FLOAT`.

---

## Query 4 — Top 5 Vendedores

```sql
SELECT vendedor,
       SUM(quantidade * preco_unitario) AS faturamento_total
FROM vendas
GROUP BY vendedor
ORDER BY faturamento_total DESC
LIMIT 5;
```

### Por que `LIMIT 5` e não uma subquery?
Para top-N simples, `ORDER BY ... LIMIT N` é mais eficiente. O banco ordena em memória e para ao atingir N linhas.

### Alternativa com RANK() (PostgreSQL/SQLite 3.25+):
```sql
SELECT vendedor, faturamento_total,
       RANK() OVER (ORDER BY faturamento_total DESC) AS rank
FROM (
  SELECT vendedor, SUM(quantidade * preco_unitario) AS faturamento_total
  FROM vendas GROUP BY vendedor
) sub
WHERE rank <= 5;
```
Use `RANK()` quando quiser tratar **empates** (dois vendedores com mesmo valor ficam na mesma posição).

---

## Query 5 — Faturamento por Mês

```sql
SELECT strftime('%Y-%m', data_venda) AS mes,
       SUM(quantidade * preco_unitario) AS faturamento_total,
       COUNT(*) AS total_vendas
FROM vendas
GROUP BY mes
ORDER BY mes;
```

### Por que `strftime('%Y-%m', data_venda)`?
- `strftime` é a função de formatação de data do SQLite.
- `'%Y-%m'` extrai ano e mês (ex: `2024-04`), criando um período mensal comparável e ordenável lexicograficamente (string `'2024-04' < '2024-12'` funciona corretamente).
- **Em PostgreSQL**: `DATE_TRUNC('month', data_venda)` ou `TO_CHAR(data_venda, 'YYYY-MM')`.

### Cuidado com fusos horários:
Se `data_venda` está em UTC e o negócio opera em GMT-3, uma venda às 23h00 UTC (22h00 BRT) seria atribuída ao dia seguinte. Em produção, sempre normalize para o fuso do negócio antes de agregar.

---

## Query 6 — Top 5 Produtos por Volume

```sql
SELECT produto,
       SUM(quantidade) AS unidades_vendidas
FROM vendas
GROUP BY produto
ORDER BY unidades_vendidas DESC
LIMIT 5;
```

### Volume ≠ Receita
Notebook tem o maior faturamento mas Monitor tem o maior volume. Isso indica:
- Notebooks têm preço unitário alto
- Monitores têm demanda alta mas preço menor

**Implicação de negócio**: estratégia de reposição de estoque deve priorizar Monitor, mas estratégia de receita deve proteger Notebook.

---

## Query 7 — Análise por Cidade

```sql
SELECT cidade,
       SUM(quantidade * preco_unitario) AS faturamento_total,
       COUNT(DISTINCT cliente) AS clientes_unicos
FROM vendas
GROUP BY cidade
ORDER BY faturamento_total DESC;
```

### Por que `COUNT(DISTINCT cliente)`?
- `COUNT(*)` contaria transações por cidade, não clientes únicos.
- `COUNT(DISTINCT cliente)` deduplica: se "Ana" fez 10 compras em SP, conta como 1 cliente.
- Esta distinção é fundamental para calcular **LTV (Lifetime Value) por mercado**.

---

## Query 8 — Clientes Recorrentes

```sql
SELECT cliente,
       COUNT(*) AS total_compras,
       SUM(quantidade * preco_unitario) AS total_gasto
FROM vendas
GROUP BY cliente
HAVING COUNT(*) > 1
ORDER BY total_compras DESC;
```

### Por que `HAVING` e não `WHERE`?
- `WHERE` filtra **linhas** antes da agregação.
- `HAVING` filtra **grupos** depois da agregação.
- `COUNT(*) > 1` só faz sentido após agrupar — você precisa saber quantas linhas o grupo tem. Por isso: `HAVING`, nunca `WHERE` aqui.

### Resultado: 100% de recorrência
Todos os 282 clientes compraram mais de uma vez. Isso pode indicar:
1. O dataset foi gerado/simulado com essa característica
2. O negócio tem produto de consumo recorrente
3. O período de análise (1 ano) é longo suficiente para capturar múltiplas compras

---

## Tabela resumo_vendas

```sql
CREATE TABLE IF NOT EXISTS resumo_vendas AS
SELECT produto,
       SUM(quantidade) AS total_unidades,
       SUM(quantidade * preco_unitario) AS faturamento_total,
       ROUND(AVG(quantidade * preco_unitario), 2) AS ticket_medio
FROM vendas
GROUP BY produto;
```

### Por que `CREATE TABLE AS SELECT`?
Isso cria uma **View Materializada** manual — o resultado da query é persistido como tabela. Útil quando:
- A query é cara e executada com frequência
- Sistemas legados que não suportam `CREATE VIEW`

**Em PostgreSQL**: use `CREATE MATERIALIZED VIEW` com `REFRESH MATERIALIZED VIEW` para atualizar.

### Índice recomendado para produção:
```sql
CREATE INDEX idx_vendas_produto ON vendas(produto);
CREATE INDEX idx_vendas_categoria ON vendas(categoria);
CREATE INDEX idx_vendas_data ON vendas(data_venda);
```
Com ~10.000 linhas, o impacto é pequeno. Com 10M+ linhas, a diferença é de segundos vs milissegundos.
