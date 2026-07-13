"""
TUTORIAL — ponto de entrada da ingestão (primeiros passos)

Onde este arquivo deve estar:
  - Em src/ no SEU repositório público de solução (veja README — Passo 1)
  - Referenciado pelo CMD do Dockerfile na raiz desse repo

O que o avaliador espera ao rodar o container:
  1. Ler os .zip em /data/ (montados pelo servidor, somente leitura)
  2. Aplicar regras de negócio e qualidade (docs/REGRAS_E_CONTRATO.md)
  3. Gravar a tabela final em db_empresas.public.{participante}_empresas

Variáveis de ambiente (NÃO hardcode host/senha — leia do ambiente):
  - PARTICIPANTE, PG_TABLE, PG_HOST, PG_PORT, PG_USER, PG_PASSWORD, PG_DB
  - S3_ENDPOINT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, MINIO_BUCKET (opcional)

Próximos passos para você implementar:
  - [ ] Listar e abrir os arquivos .zip em /data/
  - [ ] Ler os CSV internos (.EMPRECSV): separador ';', encoding ISO-8859-1, sem cabeçalho
  - [ ] Transformar colunas conforme o contrato (uppercase, capital_social, porte_descricao, etc.)
  - [ ] Aplicar filtros B2B (capital_social > 1000; remover MEI com CPF no fim da razão social)
  - [ ] Criar/popular public.{PG_TABLE} no Postgres
  - [ ] (Opcional) usar S3 apenas em s3://marketing-leads/{PARTICIPANTE}/

Referências (no repo oficial da competição):
  - docs/REGRAS_E_CONTRATO.md
  - docs/STACK_E_LIMITES.md
  - docs/CHECKLIST_PR.md
"""

import os
import sys
from pathlib import Path

DATA_DIR = Path("/data")

# --- Passo 1: ler configuração injetada pelo avaliador ---
participante = os.environ["PARTICIPANTE"]
pg_table = os.environ.get("PG_TABLE", f"{participante}_empresas")

pg_host = os.environ.get("PG_HOST", "postgres_db")
pg_port = os.environ.get("PG_PORT", "5432")
pg_user = os.environ["PG_USER"]
pg_password = os.environ["PG_PASSWORD"]
pg_db = os.environ.get("PG_DB", "db_empresas")

# S3 é opcional — use só se fizer sentido na sua arquitetura
s3_endpoint = os.environ.get("S3_ENDPOINT")
s3_bucket = os.environ.get("MINIO_BUCKET", "marketing-leads")
s3_prefix = f"{participante}/"

print("=== Ingestão no Limite — starter (tutorial) ===")
print(f"Participante : {participante}")
print(f"Tabela destino: public.{pg_table}")
print(f"Postgres     : {pg_user}@{pg_host}:{pg_port}/{pg_db}")
print(f"Dados brutos : {DATA_DIR}")
if s3_endpoint:
    print(f"S3 (opcional): {s3_endpoint} → s3://{s3_bucket}/{s3_prefix}")

# --- Passo 2: verificar se /data/ está montado ---
zip_files = sorted(DATA_DIR.glob("*.zip"))
print(f"Arquivos .zip encontrados: {len(zip_files)}")
for path in zip_files:
    print(f"  - {path.name}")

# --- Passo 3: implemente seu pipeline a partir daqui ---
#
# Exemplo de esboço (não executa ingestão real):
#
#   for zip_path in zip_files:
#       with zipfile.ZipFile(zip_path) as zf:
#           ...
#       # transformar → filtrar → gravar em lotes no Postgres
#
# Dica: processe em streaming/lotes para respeitar o limite de 2 GB de RAM.

print()
print("TODO: implementar leitura, transformação e carga no Postgres.")
print("Este starter encerra com erro até você completar o pipeline.")
sys.exit(1)
