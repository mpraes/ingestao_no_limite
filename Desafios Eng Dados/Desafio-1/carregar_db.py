"""
Script auxiliar: carrega o CSV no banco SQLite e executa desafio_parte1.sql.
Uso: python3 carregar_db.py
"""

import csv
import sqlite3

DB_PATH = "desafio1.db"
CSV_PATH = "vendas_desafio.csv"


def main() -> None:
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Recriar tabela vendas
    cur.execute("DROP TABLE IF EXISTS vendas")
    cur.execute("""
        CREATE TABLE vendas (
            id_venda       INTEGER PRIMARY KEY,
            data_venda     TEXT,
            cliente        TEXT,
            produto        TEXT,
            categoria      TEXT,
            quantidade     INTEGER,
            preco_unitario REAL,
            vendedor       TEXT,
            cidade         TEXT,
            estado         TEXT
        )
    """)

    # Carregar CSV
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = [
            (
                int(r["id_venda"]),
                r["data_venda"],
                r["cliente"],
                r["produto"],
                r["categoria"],
                int(r["quantidade"]),
                float(r["preco_unitario"]),
                r["vendedor"],
                r["cidade"],
                r["estado"],
            )
            for r in reader
        ]

    cur.executemany(
        "INSERT INTO vendas VALUES (?,?,?,?,?,?,?,?,?,?)", rows
    )
    conn.commit()
    print(f"✅ {len(rows):,} registros carregados em '{DB_PATH}'")

    # Criar tabela resumo_vendas
    cur.execute("DROP TABLE IF EXISTS resumo_vendas")
    cur.execute("""
        CREATE TABLE resumo_vendas AS
        SELECT
            produto,
            categoria,
            SUM(quantidade)                            AS quantidade_total,
            ROUND(SUM(quantidade * preco_unitario), 2) AS faturamento_total
        FROM vendas
        GROUP BY produto, categoria
        ORDER BY faturamento_total DESC
    """)
    conn.commit()
    print("✅ Tabela 'resumo_vendas' criada")

    # Verificar
    cur.execute("SELECT * FROM resumo_vendas")
    print("\n📋 resumo_vendas:")
    print(f"{'Produto':<15} {'Categoria':<15} {'Qtd':>8} {'Faturamento':>15}")
    print("-" * 55)
    for row in cur.fetchall():
        print(f"{row[0]:<15} {row[1]:<15} {row[2]:>8,} R$ {row[3]:>12,.2f}")

    conn.close()
    print(f"\n✅ Banco '{DB_PATH}' pronto. Execute as queries com:")
    print(f"   sqlite3 {DB_PATH}")


if __name__ == "__main__":
    main()
