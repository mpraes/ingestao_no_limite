-- ============================================================
-- Desafio de Dados — Parte 1: SQL
-- Banco: SQLite
-- Dados: vendas_desafio.csv (10.000 registros)
-- ============================================================
--
-- COMO USAR:
--   1. Primeiro popule o banco:   python3 carregar_db.py
--   2. Depois execute as queries: sqlite3 desafio1.db < desafio_parte1.sql
--      (ou interativamente:        sqlite3 desafio1.db )
-- ============================================================

-- ============================================================
-- 1. Faturamento total por produto
-- ============================================================
SELECT
    produto,
    ROUND(SUM(quantidade * preco_unitario), 2) AS faturamento_total
FROM vendas
GROUP BY produto
ORDER BY faturamento_total DESC;

-- ============================================================
-- 2. Faturamento total por categoria
-- ============================================================
SELECT
    categoria,
    ROUND(SUM(quantidade * preco_unitario), 2) AS faturamento_total
FROM vendas
GROUP BY categoria
ORDER BY faturamento_total DESC;

-- ============================================================
-- 3. Ticket médio por cliente
-- ============================================================
SELECT
    cliente,
    ROUND(AVG(quantidade * preco_unitario), 2) AS ticket_medio
FROM vendas
GROUP BY cliente
ORDER BY ticket_medio DESC;

-- ============================================================
-- 4. Faturamento total por vendedor
-- ============================================================
SELECT
    vendedor,
    ROUND(SUM(quantidade * preco_unitario), 2) AS faturamento_total
FROM vendas
GROUP BY vendedor
ORDER BY faturamento_total DESC;

-- ============================================================
-- 5. Faturamento por mês
-- ============================================================
SELECT
    strftime('%Y-%m', data_venda) AS mes,
    ROUND(SUM(quantidade * preco_unitario), 2) AS faturamento_total
FROM vendas
GROUP BY mes
ORDER BY mes;

-- ============================================================
-- 6. Top 5 produtos mais vendidos (por quantidade)
-- ============================================================
SELECT
    produto,
    SUM(quantidade) AS quantidade_total
FROM vendas
GROUP BY produto
ORDER BY quantidade_total DESC
LIMIT 5;

-- ============================================================
-- 7. Cidade com maior faturamento
-- ============================================================
SELECT
    cidade,
    ROUND(SUM(quantidade * preco_unitario), 2) AS faturamento_total
FROM vendas
GROUP BY cidade
ORDER BY faturamento_total DESC
LIMIT 1;

-- ============================================================
-- 8. Cliente que mais comprou em valor
-- ============================================================
SELECT
    cliente,
    ROUND(SUM(quantidade * preco_unitario), 2) AS total_compras
FROM vendas
GROUP BY cliente
ORDER BY total_compras DESC
LIMIT 1;

-- ============================================================
-- Criar tabela resumo_vendas
-- ============================================================
CREATE TABLE IF NOT EXISTS resumo_vendas AS
SELECT
    produto,
    categoria,
    SUM(quantidade)                            AS quantidade_total,
    ROUND(SUM(quantidade * preco_unitario), 2) AS faturamento_total
FROM vendas
GROUP BY produto, categoria
ORDER BY faturamento_total DESC;

-- Verificar tabela criada
SELECT * FROM resumo_vendas;
