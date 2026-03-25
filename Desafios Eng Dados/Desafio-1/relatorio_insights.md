# 📊 Relatório de Insights — Desafio de Dados E-commerce

> **Fonte:** `vendas_desafio.csv` · 10.000 registros · Período: Jan–Dez 2024
> **Faturamento Total:** R$ 17.468.902,43

---

## 1. Qual categoria vende mais?

| Categoria | Faturamento Total | Participação |
|-----------|------------------:|-------------:|
| **Eletrônicos** | R$ 11.741.663,09 | **67,2%** |
| Móveis | R$ 4.722.771,51 | 27,0% |
| Livros | R$ 544.090,92 | 3,1% |
| Acessórios | R$ 460.376,91 | 2,6% |

✅ **Eletrônicos domina** com 67% do faturamento total — mais que as 3 categorias restantes juntas.

---

## 2. Qual produto vende mais?

**Por faturamento:**
| Produto | Faturamento Total |
|---------|------------------:|
| **Notebook** | R$ 8.290.852,39 |
| Mesa | R$ 3.092.939,21 |
| Monitor | R$ 2.364.641,86 |

**Por quantidade:**
| Produto | Qtd Vendida |
|---------|------------:|
| **Monitor** | 2.613 unid |
| Mesa | 2.581 unid |
| Mouse | 2.581 unid |

✅ O **Notebook** é o campeão em receita (R$ 8,3 mi), mas o **Monitor** lidera em volume de unidades.

---

## 3. Qual vendedor vende mais?

| Vendedor | Faturamento Total |
|----------|------------------:|
| **Ana** | R$ 3.544.588,45 |
| Bruno | R$ 3.501.930,96 |
| Eduardo | R$ 3.477.302,18 |
| Carlos | R$ 3.476.724,22 |
| Daniela | R$ 3.468.356,62 |

✅ **Ana** lidera com R$ 3,54 mi. Os 5 vendedores têm performance muito próxima (variação < 2,3%), indicando equipe equilibrada.

---

## 4. Qual mês vende mais?

| Mês | Faturamento |
|-----|------------:|
| **Abril/2024** | **R$ 1.571.459,42** |
| Março/2024 | R$ 1.561.420,22 |
| Setembro/2024 | R$ 1.560.269,23 |
| Dezembro/2024 | R$ 1.223.728,66 ← menor |

✅ **Abril** é o melhor mês. Dezembro surpreende negativamente — possível ruptura de estoque ou sazonalidade atípica neste dataset.

---

## 5. Existe cliente que compra mais de uma vez?

✅ **Sim — 100% dos clientes são recorrentes.**

- Clientes únicos: **282**
- Todos compraram mais de 1 vez no período
- Campeão de frequência: **Alexandre** com **50 compras**

| Cliente | Nº de Compras |
|---------|-------------:|
| Alexandre | 50 |
| Benício | 49 |
| Luan | 49 |
| Allana | 48 |
| Arthur | 48 |

---

## 💡 Resumo Executivo

| Insight | Conclusão |
|---------|-----------|
| 🏆 Categoria Top | **Eletrônicos** (67% do faturamento) |
| 🏆 Produto Top (receita) | **Notebook** (R$ 8,3 mi) |
| 🏆 Produto Top (volume) | **Monitor** (2.613 unids) |
| 🏆 Vendedor Top | **Ana** (R$ 3,54 mi) |
| 🏆 Melhor Mês | **Abril/2024** (R$ 1,57 mi) |
| 🔄 Retenção | **100%** dos clientes são recorrentes |
| 📉 Atenção | **Dezembro** teve queda de 22% vs. pico |

**Recomendações:**
1. Concentrar portfolio em Eletrônicos e Notebooks — maior ROI
2. Investigar a queda de Dezembro (estoque? campanha?)
3. Base de clientes fidelizada é ativo estratégico — explorar cross-sell entre categorias
