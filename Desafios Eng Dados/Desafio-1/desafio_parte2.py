"""
Desafio de Dados — Parte 2: Python
Análise de vendas com pandas e matplotlib.
"""

import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def main() -> None:
    # ------------------------------------------------------------------
    # 1. Ler o arquivo CSV
    # ------------------------------------------------------------------
    df = pd.read_csv("vendas_desafio.csv")
    print(f"✅ CSV carregado: {df.shape[0]:,} linhas × {df.shape[1]} colunas\n")

    # ------------------------------------------------------------------
    # 2. Criar coluna faturamento = quantidade * preco_unitario
    # ------------------------------------------------------------------
    df["faturamento"] = df["quantidade"] * df["preco_unitario"]

    # ------------------------------------------------------------------
    # 3. Agrupar faturamento por produto
    # ------------------------------------------------------------------
    fat_produto = (
        df.groupby("produto")["faturamento"]
        .sum()
        .sort_values(ascending=False)
    )
    print("📦 Faturamento por Produto:")
    print(fat_produto.apply(lambda x: f"R$ {x:,.2f}").to_string())
    print()

    # ------------------------------------------------------------------
    # 4. Agrupar faturamento por categoria
    # ------------------------------------------------------------------
    fat_categoria = (
        df.groupby("categoria")["faturamento"]
        .sum()
        .sort_values(ascending=False)
    )
    print("📂 Faturamento por Categoria:")
    print(fat_categoria.apply(lambda x: f"R$ {x:,.2f}").to_string())
    print()

    # ------------------------------------------------------------------
    # 5. Agrupar faturamento por cliente
    # ------------------------------------------------------------------
    fat_cliente = (
        df.groupby("cliente")["faturamento"]
        .sum()
        .sort_values(ascending=False)
    )
    print("👤 Top 10 Clientes por Faturamento:")
    print(fat_cliente.head(10).apply(lambda x: f"R$ {x:,.2f}").to_string())
    print()

    # ------------------------------------------------------------------
    # 6. Criar gráfico de faturamento por categoria
    # ------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(10, 6))
    cores = ["#2563EB", "#7C3AED", "#059669", "#D97706"]
    barras = ax.bar(fat_categoria.index, fat_categoria.values, color=cores)

    # Rótulos de valor nas barras
    for barra in barras:
        altura = barra.get_height()
        ax.text(
            barra.get_x() + barra.get_width() / 2.0,
            altura,
            f"R$ {altura:,.0f}",
            ha="center",
            va="bottom",
            fontsize=11,
            fontweight="bold",
        )

    ax.set_title("Faturamento por Categoria", fontsize=16, fontweight="bold")
    ax.set_xlabel("Categoria", fontsize=12)
    ax.set_ylabel("Faturamento (R$)", fontsize=12)
    ax.yaxis.set_major_formatter(
        plt.FuncFormatter(lambda x, _: f"R$ {x:,.0f}")
    )
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    plt.tight_layout()

    chart_path = "faturamento_categoria.png"
    fig.savefig(chart_path, dpi=150)
    plt.close(fig)
    print(f"📊 Gráfico salvo: {chart_path}")

    # ------------------------------------------------------------------
    # 7. Exportar resumo_vendas.csv
    # ------------------------------------------------------------------
    resumo = (
        df.groupby(["produto", "categoria"])
        .agg(
            quantidade_total=("quantidade", "sum"),
            faturamento_total=("faturamento", "sum"),
        )
        .reset_index()
        .sort_values("faturamento_total", ascending=False)
    )
    resumo["faturamento_total"] = resumo["faturamento_total"].round(2)

    csv_path = "resumo_vendas.csv"
    resumo.to_csv(csv_path, index=False)
    print(f"📄 Resumo exportado: {csv_path}")
    print()
    print(resumo.to_string(index=False))


if __name__ == "__main__":
    main()
