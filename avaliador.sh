#!/bin/bash
set -eo pipefail

# ==============================================================================
# CONFIGURAÇÕES DA INFRAESTRUTURA
# ==============================================================================
PG_CONTAINER="postgres_db"
PG_USER="homelab_postgres"
PG_DB="db_ingestao"
PG_PASS="kmdop9se27!"

DIR_TESTES="/tmp/testes_ingestao"
CONTAINER_APP_NAME="app_submissao_test"

# ==============================================================================
# FUNÇÕES DE LOGS E FORMATAÇÃO VISUAL
# ==============================================================================
log_info() {
    echo -e "[\033[1;34mINFO\033[0m] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "[\033[1;32mSUCESSO\033[0m] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "[\033[1;33mALERTA\033[0m] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "[\033[1;31mERRO\033[0m] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# ==============================================================================
# FUNÇÃO DE BANCO DE DADOS (POSTGRESQL)
# ==============================================================================
gravar_ranking() {
    local tag="$1"
    # Garante a substituição de vírgula por ponto para evitar rejeição no Postgres
    local tempo=$(echo "$2" | tr ',' '.')
    local tamanho=$(echo "$3" | tr ',' '.')
    local status="$4"

    log_info "Persistindo resultado no Postgres (Status: $status | Tempo: ${tempo}s)..."

    if docker exec -e PGPASSWORD="$PG_PASS" "$PG_CONTAINER" \
      psql -U "$PG_USER" -d "$PG_DB" \
      -c "INSERT INTO ranking_ingestao (github_user, tempo_segundos, tamanho_mb, status) VALUES ('$tag', $tempo, $tamanho, '$status');"; then
        log_success "Dados inseridos com sucesso na tabela 'ranking_ingestao'."
    else
        log_error "Falha ao gravar registro no PostgreSQL."
    fi
}

# ==============================================================================
# 1. VERIFICAÇÃO E DIAGNÓSTICO DO AMBIENTE LOCAL
# ==============================================================================
echo -e "\n================================================="
echo "  🔍 DIAGNÓSTICO INICIAL DO SERVIDOR DE AVALIAÇÃO"
echo -e "=================================================\n"

log_info "Verificando dependências de sistema (jq, git, docker)..."
for cmd in jq git docker; do
    if ! command -v $cmd &> /dev/null; then
        log_error "Ferramenta essencial não encontrada no sistema: $cmd"
        exit 1
    fi
done
log_success "Todas as ferramentas essenciais estão instaladas."

log_info "Verificando se o serviço Docker está ativo..."
if ! docker info > /dev/null 2>&1; then
    log_error "O daemon do Docker não está rodando ou o usuário atual não tem permissão."
    exit 1
fi
log_success "Serviço Docker operacional."

log_info "Verificando disponibilidade do container PostgreSQL ('$PG_CONTAINER')..."
if ! docker ps --format '{{.Names}}' | grep -q "^${PG_CONTAINER}$"; then
    log_error "Container $PG_CONTAINER não encontrado rodando! Verifique seu docker ps."
    exit 1
fi
log_success "Container de banco de dados '$PG_CONTAINER' ativo."

# ==============================================================================
# 2. VALIDAÇÃO DA SUBMISSÃO (ARQUIVO JSON)
# ==============================================================================
JSON_FILE="$1"

if [ -z "$JSON_FILE" ]; then
    log_error "Nenhum arquivo JSON foi informado como parâmetro."
    echo "Uso: ./avaliador.sh submissoes/nome_do_arquivo.json"
    exit 1
fi

if [ ! -f "$JSON_FILE" ]; then
    log_error "Arquivo de submissão não encontrado: $JSON_FILE"
    exit 1
fi

log_info "Validando estrutura do arquivo JSON '$JSON_FILE'..."
if ! jq empty "$JSON_FILE" > /dev/null 2>&1; then
    log_error "O arquivo $JSON_FILE contém sintaxe JSON inválida!"
    exit 1
fi

PARTICIPANTE_TAG=$(jq -r '.participante // empty' "$JSON_FILE")
REPO_URL=$(jq -r '.repositorio // empty' "$JSON_FILE")

if [ -z "$PARTICIPANTE_TAG" ] || [ -z "$REPO_URL" ]; then
    log_error "O JSON precisa conter obrigatoriamente os campos 'participante' e 'repositorio'."
    exit 1
fi

echo -e "\n================================================="
echo "  🚀 INICIANDO AVALIAÇÃO DO PARTICIPANTE: $PARTICIPANTE_TAG"
echo "  📂 REPOSITÓRIO: $REPO_URL"
echo -e "=================================================\n"

# ==============================================================================
# 3. PREPARAÇÃO DO AMBIENTE E CLONE DO REPOSITÓRIO DO PARTICIPANTE
# ==============================================================================
DIR_PARTICIPANTE="$DIR_TESTES/$PARTICIPANTE_TAG"

log_info "Limpando diretórios temporários antigos em $DIR_PARTICIPANTE..."
rm -rf "$DIR_PARTICIPANTE"
mkdir -p "$DIR_PARTICIPANTE"

log_info "Clonando o repositório do participante em /tmp..."
if ! git clone --depth 1 "$REPO_URL" "$DIR_PARTICIPANTE" > /dev/null 2>&1; then
    log_error "Falha crítica ao clonar o repositório do participante!"
    gravar_ranking "$PARTICIPANTE_TAG" "0.000" "0.00" "ERRO_CLONE_GIT"
    exit 1
fi
log_success "Repositório clonado com sucesso em $DIR_PARTICIPANTE."

cd "$DIR_PARTICIPANTE"

if [ ! -f "Dockerfile" ]; then
    log_error "Dockerfile não foi encontrado na raiz do repositório do participante!"
    gravar_ranking "$PARTICIPANTE_TAG" "0.000" "0.00" "DOCKERFILE_AUSENTE"
    exit 1
fi

# ==============================================================================
# 4. BUILD DA IMAGEM DOCKER
# ==============================================================================
NOME_IMAGEM="submissao_$PARTICIPANTE_TAG"

log_info "Iniciando o build da imagem Docker ($NOME_IMAGEM)..."
if ! docker build -t "$NOME_IMAGEM" . ; then
    log_error "Falha na compilação do Dockerfile!"
    gravar_ranking "$PARTICIPANTE_TAG" "0.000" "0.00" "ERRO_BUILD_DOCKER"
    exit 1
fi
log_success "Imagem Docker construída com sucesso."

# ==============================================================================
# 5. EXECUÇÃO CONTROLADA COM LIMITES DE RECURSOS (2 vCPUs, 2 GB RAM)
# ==============================================================================
docker rm -f "$CONTAINER_APP_NAME" > /dev/null 2>&1 || true

log_info "Disparando container com limites de hardware (2 vCPUs, 2 GB RAM)..."
START_TIME=$(date +%s.%N)

if docker run --name "$CONTAINER_APP_NAME" \
    --cpus="2.0" \
    --memory="2g" \
    -e POLARS_SKIP_CPU_CHECK=1 \
    "$NOME_IMAGEM"; then
    
    END_TIME=$(date +%s.%N)
    DURATION_SEC=$(awk "BEGIN {print $END_TIME - $START_TIME}" | tr ',' '.')
    log_success "Execução concluída em ${DURATION_SEC}s!"
    
    STORAGE_MB=150.00
    STATUS_FINAL="CLASSIFICADO"
else
    log_error "O container do participante falhou ou excedeu o limite de memória (OOM)!"
    DURATION_SEC="0.000"
    STORAGE_MB="0.00"
    STATUS_FINAL="ERRO_EXECUCAO"
fi

# ==============================================================================
# 6. LIMPEZA E REGISTRO FINAL
# ==============================================================================
log_info "Removendo container de teste e imagens temporárias..."
docker rm -f "$CONTAINER_APP_NAME" > /dev/null 2>&1 || true
docker rmi -f "$NOME_IMAGEM" > /dev/null 2>&1 || true

gravar_ranking "$PARTICIPANTE_TAG" "$DURATION_SEC" "$STORAGE_MB" "$STATUS_FINAL"

echo -e "\n================================================="
echo "  🏁 PROCESSO DE AVALIAÇÃO CONCLUÍDO ($STATUS_FINAL)"
echo -e "=================================================\n"
