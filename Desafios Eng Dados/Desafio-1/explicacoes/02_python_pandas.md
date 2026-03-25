# 02 — Python + Pandas: Decisões Técnicas em Maestria

> **Por que este arquivo?**
> Qualquer pessoa copia código pandas da documentação. Entender **por que** cada decisão existe — performance, semântica, produção — é o que diferencia um engenheiro de dados de um script-monkey.

---

## Por que pandas e não loops Python puros?

```python
# ❌ Jeito ingênuo — O(n), lento, difícil de ler
total = 0
for row in data:
    total += row['preco'] * row['qtd']

# ✅ Pandas — vetorizado, C-backed, legível
total = (df['preco_unitario'] * df['quantidade']).sum()
```

**O que acontece internamente?**
- pandas usa NumPy por baixo, que executa operações em C via BLAS/LAPACK
- `df['a'] * df['b']` opera coluna inteira de uma vez (SIMD instructions no hardware)
- Para 10.000 linhas: loop Python ≈ 5ms, pandas ≈ 0.1ms — **50x mais rápido**
- Para 10M linhas: a diferença é de minutos vs milissegundos

---

## Criando a coluna `faturamento`

```python
df['faturamento'] = df['preco_unitario'] * df['quantidade']
```

### Por que não salvar no CSV original?
**Princípio de dados imutáveis**: o dado bruto (`preco_unitario`, `quantidade`) é a fonte da verdade. `faturamento` é derivado — recalculável. Salvar campos derivados cria risco de inconsistência se o dado fonte for corrigido.

### E se houvesse desconto?
```python
df['faturamento'] = df['preco_unitario'] * df['quantidade'] * (1 - df.get('desconto', 0))
```
Sempre derive a métrica de negócio dos campos primitivos.

---

## `groupby().agg()` vs `groupby().sum()`

```python
# ✅ Preferível — declara explicitamente o que você quer
resumo = df.groupby('produto').agg(
    total_unidades  = ('quantidade',    'sum'),
    faturamento_total = ('faturamento', 'sum'),
    ticket_medio    = ('faturamento',   'mean'),
    n_vendas        = ('id_venda',      'count'),
).round(2)

# Funciona, mas menos expressivo
resumo = df.groupby('produto')['faturamento'].sum()
```

**Quando usar cada um:**
| Situação | Usar |
|----------|------|
| Múltiplas métricas por grupo | `agg()` com dicionário |
| Uma métrica simples | `.sum()`, `.mean()` direto |
| Métricas customizadas | `agg(func=lambda x: ...)` |

**`named aggregation`** (sintaxe `nome=(coluna, func)`): introduzida no pandas 0.25. Produz nomes de colunas limpos automaticamente. Sem ela, você teria que renomear as colunas depois.

---

## `matplotlib.use("Agg")` — O que é um backend headless?

```python
import matplotlib
matplotlib.use("Agg")   # DEVE vir antes de import pyplot!
import matplotlib.pyplot as plt
```

### O problema sem Agg:
- Por padrão, matplotlib tenta abrir uma janela gráfica usando o sistema de display (X11 no Linux, Quartz no macOS)
- Em ambientes sem display (servidores, Docker, CI/CD, cron jobs), isso causa:
  ```
  _tkinter.TclError: no display name and no $DISPLAY environment variable
  ```

### O que `Agg` faz:
- Agg = **Anti-Grain Geometry** — renderizador de rasterização 2D
- Gera os pixels do gráfico em memória sem abrir janela
- `plt.savefig()` salva o resultado
- **Regra de ouro em produção**: sempre use backend não-interativo em scripts automatizados

### Outros backends disponíveis:
| Backend | Uso |
|---------|-----|
| `Agg` | Headless, salvar PNG/PDF |
| `TkAgg` | Desktop com Tkinter |
| `svg` | Gerar SVG vetorial |
| `pdf` | Gerar PDF diretamente |

---

## `figsize=(10, 6)` e `dpi=150` — A matemática da resolução

```python
plt.figure(figsize=(10, 6), dpi=150)
```

### Como calcular:
- **figsize** = tamanho em polegadas: 10" × 6" = ratio 16:10
- **dpi** = dots per inch: 150 dpi → imagem de **1500 × 900 pixels**

| dpi | Uso ideal |
|-----|-----------|
| 72  | Tela baixa resolução |
| 96  | Web padrão |
| 150 | Apresentações, slides |
| 300 | Impressão, publicação |

### Por que 10:6?
- Proporção próxima de 16:10 → confortável para apresentação e leitura
- Mais largo que alto → barras horizontais ficam bem proporcionadas
- `figsize` não determina qualidade, apenas proporção e escala da tipografia

---

## `sort_values()` vs `sort_index()`

```python
# Ordenar por valor (o que queremos aqui)
df.sort_values('faturamento_total', ascending=False)

# Ordenar por índice (nome do produto de A→Z)
df.sort_index()
```

**Quando usar cada um:**
- `sort_values`: quando a ordem tem significado de negócio (ranking, top-N)
- `sort_index`: quando o índice é semântico (datas, categorias ordenadas)

**Para gráfico de barras ranking**: sempre use `sort_values` descending e depois `invert_yaxis()` se horizontal:
```python
ax.invert_yaxis()  # coloca o #1 no topo
```

---

## Exportar CSV com `to_csv()`

```python
resumo.to_csv('resumo_vendas.csv', index=True, float_format='%.2f', encoding='utf-8-sig')
```

### Por que `utf-8-sig`?
O prefixo BOM (`\xef\xbb\xbf`) garante que Excel (Windows) abra o arquivo com encoding correto sem mostrar caracteres estranhos (ex: `Ã©` em vez de `é`).

### Por que `float_format='%.2f'`?
Força duas casas decimais nos floats. Sem isso, R$ 1234.5 pode virar `1234.4999999998` por imprecisão de ponto flutuante.

### Por que `index=True`?
O índice aqui é `produto` — um dado semântico. Se o índice fosse apenas `0,1,2,3...`, usaríamos `index=False`.

---

## Formatação do gráfico: escolhas deliberadas

```python
ax.bar(x, height, color=colors, edgecolor='white', linewidth=0.5)
ax.set_title('Faturamento por Categoria', fontsize=14, fontweight='bold', pad=16)
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x,_: f'R$ {x/1e6:.1f}M'))
```

### Por que `edgecolor='white'`?
Borda branca nas barras cria separação visual clara entre barras adjacentes da mesma cor. Sem ela, barras próximas parecem fundidas.

### Por que `FuncFormatter` e não `f'R$ {x:.0f}'`?
- `FuncFormatter` formata o eixo Y automaticamente para cada tick
- Converte `1400000` → `R$ 1.4M` tornando o eixo legível
- O lambda recebe `(value, position)` — o `_` ignora a posição

### Por que `pad=16` no título?
`pad` = espaçamento entre o título e os eixos em pontos. Sem isso, o título às vezes se sobrepõe ao y-axis label.
