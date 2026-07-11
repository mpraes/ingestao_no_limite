# 📄 Regras de Negócio e Contrato de Dados

Para sua submissão ser aprovada pelo **Juiz Automático (DuckDB)**, a tabela final na camada Silver (`s3://marketing-leads/silver_empresas`) deve cumprir rigorosamente o schema e **zerar todas as métricas de erro**.

---

## 1. Origem dos Dados
* Diretório de dados brutos no container: `/data/`
* Múltiplos arquivos compactados (`.zip`).
* Extensão interna: arquivos do tipo `.EMPRECSV` (ex: `K3241.K03200Y0.D60613.EMPRECSV`).
* Codificação original: `ISO-8859-1` (Latin-1) ➔ Deve ser convertido para `UTF-8`.
* Separador: `;` (ponto e vírgula) com aspas duplas `"`. Sem cabeçalho.

---

## 2. Dicionário & Métricas Exatas de Data Quality

| Coluna Target | Tipo | Regra de Transformação | Métrica de Validação (DuckDB) | Tolerância |
| :--- | :--- | :--- | :--- | :--- |
| `cnpj_basico` | `VARCHAR(8)` | Exatamente 8 dígitos numéricos com zeros à esquerda. | `length(cnpj_basico) != 8 OR cnpj_basico NOT SIMILAR TO '^[0-9]{8}$'` | **0 erros** |
| `razao_social` | `VARCHAR` | Uppercase, sem espaços nas extremidades. | `razao_social != UPPER(razao_social) OR razao_social != TRIM(razao_social)` | **0 erros** |
| `natureza_juridica`| `VARCHAR(4)` | Manter código numérico de 4 dígitos. | `length(natureza_juridica) != 4` | **0 erros** |
| `qualificacao_responsavel` | `VARCHAR` | Manter código de qualificação. | `qualificacao_responsavel IS NULL` | **0 erros** |
| `capital_social` | `DOUBLE` | Converter vírgula BR para ponto numérico (`5000.00`). | `capital_social <= 1000.00 OR capital_social IS NULL` | **0 erros** |
| `porte_codigo` | `VARCHAR(2)` | Manter código original (`"00"`, `"01"`, `"03"`, `"05"`). | `porte_codigo NOT IN ('00', '01', '03', '05')` | **0 erros** |
| `porte_descricao` | `VARCHAR` | Mapeamento: `00`➔`NÃO INFORMADO`, `01`➔`MICRO EMPRESA`, `03`➔`EMPRESA DE PEQUENO PORTE`, `05`➔`DEMAIS`. | `porte_descricao NOT IN ('NÃO INFORMADO', 'MICRO EMPRESA', 'EMPRESA DE PEQUENO PORTE', 'DEMAIS')` | **0 erros** |
| `ente_federativo` | `VARCHAR` | Strings vazias `""` devem ser `NULL`. | N/A | OK |

---

## 3. Filtros de Negócio B2B

1. **Capital Social Mínimo:** Apenas empresas com `capital_social > 1000.00`.
2. **Filtro de MEI com CPF:** Remover qualquer registro onde a `razao_social` termine com 11 dígitos numéricos referentes ao CPF do titular.
   * *Métrica de Validação:* `razao_social SIMILAR TO '.*[0-9]{11}$'` ➔ **0 erros permitidos**.
