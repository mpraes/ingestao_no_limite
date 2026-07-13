# 🚦 Gates, Ranking e Juiz Automático

Este documento define o que **aprova** ou **reprova** uma submissão (gates) e como o **ranking** é calculado entre soluções classificadas.

Scripts SQL executáveis estão em [`evaluator/judge/sql/`](../evaluator/judge/sql/). Este documento descreve apenas a **lógica** — sem queries.

---

## Visão geral do fluxo

```
Merge na main (submissions/*.json)
  → evaluator/evaluator.sh (orquestrador bash)
  → venv do juiz (psycopg2, boto3) + preflight via evaluator/judge/validar.py (Gate G1)
  → git clone + docker build (Gate G0)
  → docker run com timeout ~3h20m (Gate G2 — bash)
  → evaluator/judge/validar.py avaliar (Gates G2–G4 + métricas)
  → Gravação em ranking_ingestao + recalcular_posicoes_ranking()
  → Site de ranking + logs do workflow
```

### Divisão de responsabilidades

| Componente | Responsabilidade |
| :--- | :--- |
| `evaluator/evaluator.sh` | Clone, build (timeout 15 min), docker run, timeout pipeline, pico de RAM |
| `evaluator/judge/validar.py` | Gates SQL, métricas, INSERT ranking |
| `evaluator/judge/sql/` | Queries compartilhadas (gates, métricas, views, site) |

---

## 1. Gates (pass/fail)

Gates são **binários**. Falhou um = submissão **não classificada** (sem posição no ranking).

### Gate G0 — Estrutura da submissão

| Check | Condição | Status em caso de falha |
| :--- | :--- | :--- |
| JSON válido | Campos `participante` e `repositorio` presentes | `ERRO_JSON_INVALIDO` |
| Repositório clonável | `git clone` com sucesso | `ERRO_CLONE_GIT` |
| Dockerfile presente | Arquivo na raiz do repo | `DOCKERFILE_AUSENTE` |
| Build Docker | `docker build` com sucesso em ≤ 15 min | `ERRO_BUILD_DOCKER` / `ERRO_BUILD_TIMEOUT` |

### Gate G1 — Preflight

Executado antes do pipeline completo para evitar horas perdidas em soluções quebradas.

| Check | Condição | Status em caso de falha |
| :--- | :--- | :--- |
| Conectividade Postgres | Consegue conectar em `db_empresas` | `ERRO_PREFLIGHT_PG` |

Comando: `python3 evaluator/judge/validar.py preflight --participante <user>`

### Gate G2 — Execução do pipeline

| Check | Condição | Status em caso de falha |
| :--- | :--- | :--- |
| Sem OOM | Exit code ≠ 137 | `ERRO_OOM` |
| Sem crash | Exit code = 0 | `ERRO_EXECUCAO` |
| Timeout | Wall time ≤ timeout configurado (~3h20m) | `ERRO_TIMEOUT` |
| Tabela existe | Tabela `public.{participante}_empresas` criada | `ERRO_TABELA_AUSENTE` |

### Gate G3 — Sanidade de volume

Conta os registros na tabela final e compara com `limite_min` e `limite_max` do dataset oficial.

| Condição | Status |
| :--- | :--- |
| `total = 0` | `ERRO_TABELA_VAZIA` |
| `total < limite_min` | `ERRO_POUCOS_REGISTROS` |
| `total > limite_max` | `ERRO_REGISTROS_DEMAIS` |
| Dentro da faixa | aprovado |

Script manual: `evaluator/judge/sql/metrics/volume_sanity.sql`

### Gate G4 — Data Quality

Oito regras de qualidade (DQ-01 a DQ-08). Cada uma conta registros inválidos — **todas devem retornar 0**.

| Resultado | Status |
| :--- | :--- |
| Todas as regras = 0 erros | `CLASSIFICADO` |
| Qualquer regra > 0 | `ERRO_DATA_QUALITY` |

Detalhes de qual gate falhou ficam em `gate_dq_detalhes` (JSON).  
Regras em linguagem natural: [`REGRAS_E_CONTRATO.md`](./REGRAS_E_CONTRATO.md)  
Scripts: `evaluator/judge/sql/gates/dq-*.sql` e `evaluator/judge/sql/gates/run_all_dq_manual.sql`

---

## 2. Métricas de ranking (apenas se CLASSIFICADO)

Coletadas automaticamente após passar em todos os gates:

| Métrica | O que mede | Uso no ranking |
| :--- | :--- | :--- |
| `tempo_segundos` | Wall time do `docker run` | **Primário** — menor vence |
| `storage_postgres_mb` | Tamanho da tabela no Postgres | Desempate 1 |
| `storage_minio_mb` | Bytes no prefixo S3 do participante (MinIO na avaliação) | Desempate 1 |
| `storage_total_mb` | Postgres + S3 (calculado nas views) | Desempate 1 |
| `peak_ram_mb` | Pico de RAM do container | Desempate 2 |
| `total_registros` | Linhas na tabela final | Exibição no site |

### Ordem de classificação

1. Menor `tempo_segundos`
2. Menor `storage_postgres_mb + storage_minio_mb`
3. Menor `peak_ram_mb`
4. Em empate total: quem foi avaliado primeiro (`criado_em`)

A função `recalcular_posicoes_ranking()` aplica essa ordem e preenche `posicao_ranking` na melhor tentativa de cada participante.

### Score composto (opcional para o site)

Para exibição visual: `score = tempo + (storage_total × 0.5) + (peak_ram × 0.1)` — menor é melhor.

---

## 3. Tabela `ranking_ingestao`

Resultados gravados em `db_ingestao.public.ranking_ingestao`.

DDL, função de ranking e views: `evaluator/judge/sql/schema/ranking_ingestao.sql`

### Campos principais

| Coluna | Descrição |
| :--- | :--- |
| `github_user` | Identificador do participante |
| `repositorio` | URL do repositório da solução |
| `tempo_segundos` | Wall time do pipeline |
| `storage_postgres_mb` / `storage_minio_mb` | Storage Postgres / S3 (coluna `storage_minio_mb` mede o prefixo no MinIO da avaliação) |
| `peak_ram_mb` | Pico de RAM |
| `total_registros` | Linhas na tabela final |
| `status` | Resultado final (ver abaixo) |
| `classificado` | `true` só se passou em todos os gates |
| `posicao_ranking` | Posição no leaderboard |
| `gate_preflight` … `gate_dq` | Flags de cada gate |
| `gate_dq_detalhes` | JSON com gates DQ que falharam |
| `commit_sha` / `pr_numero` | Rastreabilidade da submissão |
| `criado_em` | Data/hora da avaliação |

### Status possíveis

| Status | Significado |
| :--- | :--- |
| `CLASSIFICADO` | Passou em todos os gates |
| `ERRO_CLONE_GIT` | Falha ao clonar repositório |
| `DOCKERFILE_AUSENTE` | Sem Dockerfile na raiz |
| `ERRO_BUILD_TIMEOUT` | Build da imagem excedeu 15 minutos |
| `ERRO_BUILD_DOCKER` | Build da imagem falhou |
| `ERRO_PREFLIGHT_*` | Falha no preflight |
| `ERRO_OOM` | Container morto por falta de memória |
| `ERRO_TIMEOUT` | Excedeu o timeout do pipeline (~3h20m) |
| `ERRO_EXECUCAO` | Container saiu com erro |
| `ERRO_TABELA_AUSENTE` | Tabela final não encontrada |
| `ERRO_TABELA_VAZIA` | Tabela sem registros |
| `ERRO_POUCOS_REGISTROS` | Abaixo do mínimo esperado |
| `ERRO_REGISTROS_DEMAIS` | Acima do máximo esperado |
| `ERRO_DATA_QUALITY` | Uma ou mais regras DQ falharam |

---

## 4. Views para o site de ranking

`storage_total_mb` **não é coluna da tabela** — as views calculam `storage_postgres_mb + storage_minio_mb`.

| View | Uso no site |
| :--- | :--- |
| `v_leaderboard` | Ranking oficial (página principal) |
| `v_melhor_por_participante` | Melhor tentativa classificada de cada user |
| `v_ultima_avaliacao` | Última tentativa — feedback no ranking |
| `v_historico_tentativas` | Todas as execuções — gráficos e debug |

Consultas prontas para rodar no servidor: `evaluator/judge/sql/site/consultas_ranking.sql`

---

## 5. Regras operacionais da fila

| Regra | Comportamento |
| :--- | :--- |
| Fila única | 1 container de avaliação por vez (nunca em paralelo — `concurrency: avaliador-ingestao`) |
| Intervalo entre avaliações | Cooldown de 15 min após cada run (`COOLDOWN_SEC`) antes de liberar a fila |
| Reavaliação | Novo merge do JSON ou `workflow_dispatch` manual — execuções enfileiradas, não canceladas |
| Timeout global | ~3h20m no `docker run` (~48M linhas a processar) |
| Build global | 15 minutos no `docker build` (1 CPU / 1 GB — não compete com o pipeline) |
| Feedback | Logs do workflow + site de ranking (`v_ultima_avaliacao`) |
| Melhor resultado | Cada execução gera um registro; o site usa a melhor classificada |

---

## 6. O que **não** entra no ranking

* Linhas de código
* Número de dependências
* Elegância subjetiva do código
* Erros DQ parciais — ou passa com 0 em todas, ou reprova

Data Quality é **gate**, não pontuação parcial.
