# 03 — Insights de Negócio em Maestria

> **Por que este arquivo?**
> Dados sem contexto de negócio são apenas números. Este arquivo mostra como transformar os resultados em narrativa executiva — o que diferencia um analista de um estrategista.

---

## Framework: Pareto e Concentração de Receita

O **Princípio de Pareto** (80/20) é o ponto de partida para qualquer análise de portfólio:

| Categoria | Faturamento | % Acumulado |
|-----------|-------------|-------------|
| Eletrônicos | R$ 11,7M | 67% |
| Móveis | R$ 4,2M | 91% |
| Acessórios | R$ 1,0M | 97% |
| Livros | R$ 0,6M | 100% |

Neste portfólio, **2 categorias = 91% da receita**. Isso é mais concentrado que o Pareto clássico.

### O que isso significa para o negócio?

**Risco de concentração**: se Eletrônicos tiver problema de fornecimento, margem ou competição, 67% da receita está em risco. Um negócio saudável calibra sua exposição.

**Ação recomendada**: analisar a margem por categoria. Se Livros e Acessórios têm margem maior, podem ser crescidos estrategicamente mesmo com receita menor.

---

## Análise de Produtos: Volume vs. Receita

| Produto | Faturamento | Unidades | Preço médio |
|---------|-------------|----------|-------------|
| Notebook | R$ 8,3M | ~1.850 | ~R$ 4.500 |
| Monitor | ~R$ 1,9M | 2.613 | ~R$ 730 |

### Interpretação:
- Notebook = **produto premium, baixo volume, alta receita unitária**
- Monitor = **produto de massa, alto volume, margem unitária menor**

**Por que isso importa para estoque?**
- Notebook requer capital imobilizado alto (menos unidades, preço alto)
- Monitor requer giro rápido (muitas unidades, custo de armazenagem)
- Estratégia de compra/reposição deve separar essas lógicas

**Framework de portfólio:**
```
Alto faturamento + Alto volume → Cash Cow (proteger)
Alto faturamento + Baixo volume → Star (crescer com cuidado)
Baixo faturamento + Alto volume → Question Mark (avaliar margem)
Baixo faturamento + Baixo volume → Dog (considerar descontinuar)
```

---

## Análise de Vendedores: o que os números escondem

O ranking simples por faturamento:
1. Ana — R$ 3,54M
2. Carlos — R$ 3,42M
3. ...

**Armadilha do ranking simples**: vendedores que vendem mais produtos caros naturalmente ficam no topo, independente da sua performance real.

### Métricas mais justas:
- **Faturamento / Nº de transações** (produtividade por venda)
- **Faturamento / Nº de clientes** (LTV gerado por vendedor)
- **Taxa de repetição**: quantos dos clientes de cada vendedor voltaram?

```sql
-- Produtividade real por vendedor
SELECT vendedor,
       SUM(quantidade * preco_unitario) AS faturamento,
       COUNT(*) AS transacoes,
       SUM(quantidade * preco_unitario) / COUNT(*) AS fat_por_transacao,
       COUNT(DISTINCT cliente) AS clientes_unicos
FROM vendas
GROUP BY vendedor
ORDER BY fat_por_transacao DESC;
```

---

## Tendência Mensal: o que a queda de Dezembro significa?

O gráfico linha mostra pico em Abril e queda progressiva no segundo semestre.

### Hipóteses (sem dados adicionais, não podemos confirmar):

| Hipótese | Evidência a buscar |
|----------|-------------------|
| Dataset truncado (não capturou todo Dez) | Verificar última data do CSV |
| Sazonalidade real (compras concentradas no 1º sem) | Comparar com anos anteriores |
| Ruptura de estoque | Queda abrupta vs. gradual? |
| Mudança de mix de produtos | Dez vendeu mais produtos baratos? |

```python
# Verificar no Python
print(df['data_venda'].max())  # Última data disponível
print(df[df['data_venda'].str.startswith('2024-12')].shape[0])  # Registros de Dez
```

**Conclusão do analista**: nunca afirme "vendas caíram" sem verificar se o dado está completo. Dados truncados são a armadilha mais comum em análises de recência.

---

## 100% de Clientes Recorrentes: verdade ou artefato?

A query mostra que **todos os 282 clientes** compraram mais de uma vez.

### Cenários possíveis:

1. **Dataset sintético**: gerado intencionalmente com todos os clientes ativos — o mais provável para um desafio acadêmico

2. **Produto de consumo recorrente**: se o negócio vende commodities (papel, acessórios básicos), alta recorrência é esperada

3. **Período longo de análise**: 12 meses é tempo suficiente para capturar recompra em muitos segmentos

### Como verificar no mundo real:

```sql
-- Distribuição de frequência de compras
SELECT total_compras, COUNT(*) AS clientes
FROM (
  SELECT cliente, COUNT(*) AS total_compras FROM vendas GROUP BY cliente
) sub
GROUP BY total_compras
ORDER BY total_compras;
```

Se todos os clientes tivessem exatamente 2 compras → sinal forte de dado sintético.

---

## Como Transformar Isso em Slide Executivo

### Framework de Storytelling com Dados (Barbara Minto — Pirâmide MECE):

```
SITUAÇÃO: Enterprise de e-commerce com R$ 17,5M de faturamento em 2024
COMPLICAÇÃO: 91% da receita concentrada em 2 categorias
PERGUNTA: Como reduzir risco e crescer de forma sustentável?
RESPOSTA: Diversificar portfólio em Acessórios + otimizar margem de Eletrônicos
```

### Estrutura de slide:

```
[Título]: "Eletrônicos lidera com 67% — e isso é um risco calculado"

[Gráfico principal]: Donut ou waffle chart de participação por categoria

[3 bullets de insight]:
• Notebook é o produto âncora (R$ 8,3M, 47% do faturamento)
• Base de clientes 100% recorrente sinaliza forte retenção
• Queda em Dez requer investigação de supply chain

[Call to action]: Avaliar margem por categoria antes de definir mix 2025
```

**Regra de ouro**: 1 ideia por slide. O slide responde à pergunta "E então?", não descreve o dado.
