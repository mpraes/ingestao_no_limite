# =============================================================================
# TUTORIAL — Dockerfile (raiz do SEU repositório de solução)
# =============================================================================
#
# Requisito da competição:
#   - Este arquivo deve ficar na RAIZ do repo indicado em participante.json
#   - Ao iniciar o container, a ingestão deve rodar automaticamente (sem comando manual)
#
# Estrutura esperada do SEU repo (não copie docs/ nem juiz/ do repo oficial):
#
#   seu-repo/
#   ├── Dockerfile
#   ├── requirements.txt
#   ├── participante.json
#   └── src/
#       └── main.py          ← ajuste o CMD se usar outro entrypoint
#
# Docs: docs/STACK_E_LIMITES.md (env vars) · docs/REGRAS_E_CONTRATO.md (schema)
# =============================================================================

FROM python:3.11-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

# O avaliador executa apenas: docker run <sua-imagem>
# Portanto o CMD deve disparar TODA a ingestão até gravar no Postgres.
CMD ["python", "src/main.py"]
