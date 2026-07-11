#!/bin/bash
# ==============================================================================
# JUIZ OFICIAL - COMPETIÇÃO INGESTÃO NO LIMITE
# ==============================================================================

PARTICIPANTE_TAG=${1:-"desconhecido"}
CONTAINER_NAME="teste_ingestao_$PARTICIPANTE_TAG"
DATA_INPUT="/mnt/hd_externo/dados_gov/empresas"
MINIO_OUTPUT_PATH="/home/renan/minio_data/marketing-leads/silver_empresas"

MINIO_USER="admin"
MINIO_PASS="minio_password"

echo "================================================="
echo "  AVALIANDO SUBMISSÃO: $PARTICIPANTE_TAG"
echo "================================================="

# 1. Limpeza Preventiva
docker rm -f $CONTAINER_NAME 2>/dev/null
rm -rf $MINIO_OUTPUT_PATH

# 2. Build local no Celeron
echo "--> Realizando Build local da imagem Docker..."
docker build -t "img_$PARTICIPANTE_TAG" .
if [ $? -ne 0 ]; then
    echo "❌ ERRO: Falha no build da imagem Docker."
    docker exec postgres_db psql -U postgres -c "INSERT INTO ranking_ingestao (github_user, tempo_segundos, tamanho_mb, status) VALUES ('$PARTICIPANTE_TAG', 0, 0, 'ERRO_BUILD');"
    exit 1
fi

# 3. Execução com Restrição (2GB RAM / 2 CPUs)
echo "--> Executando pipeline (Limite: 2GB RAM / 2 vCPUs)..."
START_TIME=$(date +%s%N)

docker run --name $CONTAINER_NAME \
  --net=host \
  --memory="2g" \
  --cpus="2" \
  -v "$DATA_INPUT":/data:ro \
  "img_$PARTICIPANTE_TAG"

EXIT_CODE=$?
END_TIME=$(date +%s%N)

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ DESCLASSIFICADO: Execução falhou ou estourou os 2GB de RAM (Exit code: $EXIT_CODE)"
    docker rmi "img_$PARTICIPANTE_TAG" -f 2>/dev/null
    rm -rf $MINIO_OUTPUT_PATH
    docker exec postgres_db psql -U postgres -c "INSERT INTO ranking_ingestao (github_user, tempo_segundos, tamanho_mb, status) VALUES ('$PARTICIPANTE_TAG', 0, 0, 'ERRO_OOM_EXECUCAO');"
    exit 1
fi

# 4. Métricas de Performance e Storage
DURATION_SEC=$(echo "scale=3; ($END_TIME - $START_TIME)/1000000000" | bc)
STORAGE_MB=$(du -sm "$MINIO_OUTPUT_PATH" 2>/dev/null | cut -f1)
STORAGE_MB=${STORAGE_MB:-0}

# 5. Auditoria de Data Quality via DuckDB
echo "--> Avaliando Métricas de Data Quality com DuckDB..."

ERROS_TOTAL=$(duckdb -total -noheader -list -c "
INSTALL httpfs;
INSTALL delta;
LOAD httpfs;
LOAD delta;
SET s3_endpoint='localhost:9000';
SET s3_access_key_id='$MINIO_USER';
SET s3_secret_access_key='$MINIO_PASS';
SET s3_use_ssl=false;
SET s3_url_style='path';

SELECT 
    COALESCE(SUM(CASE WHEN length(cnpj_basico) != 8 OR cnpj_basico NOT SIMILAR TO '^[0-9]{8}$' THEN 1 ELSE 0 END), 0) +
    COALESCE(SUM(CASE WHEN capital_social <= 1000.00 THEN 1 ELSE 0 END), 0) +
    COALESCE(SUM(CASE WHEN razao_social SIMILAR TO '.*[0-9]{11}$' THEN 1 ELSE 0 END), 0) +
    COALESCE(SUM(CASE WHEN porte_descricao NOT IN ('NÃO INFORMADO', 'MICRO EMPRESA', 'EMPRESA DE PEQUENO PORTE', 'DEMAIS') THEN 1 ELSE 0 END), 0)
FROM delta_scan('s3://marketing-leads/silver_empresas');
" 2>/dev/null)

# 6. Limpeza Pós-Teste (Manter SSD limpo)
rm -rf $MINIO_OUTPUT_PATH
docker rmi "img_$PARTICIPANTE_TAG" -f 2>/dev/null
docker rm -f $CONTAINER_NAME 2>/dev/null

# 7. Gravação do Resultado no Postgres
if [ -z "$ERROS_TOTAL" ] || [ "$ERROS_TOTAL" -gt 0 ]; then
    echo "❌ REPROVADO NO DATA QUALITY: $ERROS_TOTAL violações encontradas no contrato."
    docker exec postgres_db psql -U postgres -c "INSERT INTO ranking_ingestao (github_user, tempo_segundos, tamanho_mb, status) VALUES ('$PARTICIPANTE_TAG', $DURATION_SEC, $STORAGE_MB, 'FALHA_DATA_QUALITY');"
    exit 1
fi

echo "================================================="
echo "  ✅ AVALIAÇÃO CONCLUÍDA COM SUCESSO!"
echo "  - Tempo: $DURATION_SEC s | Storage: $STORAGE_MB MB"
echo "================================================="

docker exec postgres_db psql -U postgres -c "INSERT INTO ranking_ingestao (github_user, tempo_segundos, tamanho_mb, status) VALUES ('$PARTICIPANTE_TAG', $DURATION_SEC, $STORAGE_MB, 'CLASSIFICADO');"
