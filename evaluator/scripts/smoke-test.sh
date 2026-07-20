#!/bin/bash
# Smoke test — validates toolchain, judge, workflow and (optional) evaluator.sh end-to-end.
#
# Usage:
#   ./evaluator/scripts/smoke-test.sh           # judge + infra (fast)
#   ./evaluator/scripts/smoke-test.sh --full      # includes evaluator.sh with local clone
#   ./evaluator/scripts/smoke-test.sh --no-seed   # skip seed (table already exists)
set -eo pipefail

EVALUATOR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$EVALUATOR_ROOT/.." && pwd)"
JUDGE_DIR="$EVALUATOR_ROOT/judge"
PARTICIPANTE="${SMOKE_PARTICIPANTE:-smoke_test}"
RUN_FULL=false
RUN_SEED=true

for arg in "$@"; do
    case "$arg" in
        --full) RUN_FULL=true ;;
        --no-seed) RUN_SEED=false ;;
        -h|--help)
            sed -n '2,6p' "$0"
            exit 0
            ;;
        *) echo "Argumento desconhecido: $arg" >&2; exit 1 ;;
    esac
done

PASS=0
FAIL=0
SKIP=0
SMOKE_ENV=""
SMOKE_JSON=""

# shellcheck disable=SC1091
source "$EVALUATOR_ROOT/scripts/lib/ensure-judge-venv.sh"

log()  { echo -e "[smoke] $*"; }
pass() { PASS=$((PASS + 1)); log "✅ $*"; }
fail() { FAIL=$((FAIL + 1)); log "❌ $*"; }
skip() { SKIP=$((SKIP + 1)); log "⏭️  $*"; }

cleanup() {
    [[ -n "$SMOKE_ENV" && -f "$SMOKE_ENV" ]] && rm -f "$SMOKE_ENV"
    [[ -n "$SMOKE_JSON" && -f "$SMOKE_JSON" ]] && rm -f "$SMOKE_JSON"
}
trap cleanup EXIT

run_step() {
    local title="$1"
    shift
    log ""
    log "── $title"
    if "$@"; then
        pass "$title"
        return 0
    fi
    fail "$title"
    return 1
}

require_cmd() {
    command -v "$1" &>/dev/null
}

check_toolchain() {
    local missing=0
    for cmd in jq git docker python3; do
        require_cmd "$cmd" || { log "   ausente: $cmd"; missing=1; }
    done
    [[ $missing -eq 0 ]]
}

check_python_deps() {
    resolve_judge_python
    "$JUDGE_PYTHON" - <<'PY'
import importlib
for mod in ("psycopg2", "boto3"):
    importlib.import_module(mod)
PY
}

ensure_venv() {
    ensure_judge_venv
}

python_judge() {
    resolve_judge_python
    JUIZ_CONFIG="$SMOKE_ENV" "$JUDGE_PYTHON" "$JUDGE_DIR/validar.py" "$@"
}

check_repo_layout() {
    local missing=0
    for f in evaluator/evaluator.sh evaluator/judge/validar.py evaluator/judge/requirements.txt \
             .github/workflows/teste.yml submitter/Dockerfile submissions/dev_python.json; do
        [[ -f "$REPO_ROOT/$f" ]] || { log "   ausente: $f"; missing=1; }
    done
    [[ $missing -eq 0 ]]
}

check_sql_layout() {
    local sql_base="${JUIZ_SQL_DIR:-$JUDGE_DIR/sql}"
    local missing=0
    for f in gates/dq-01_cnpj_basico.sql gates/dq-08_is_mei.sql \
             metrics/table_exists.sql metrics/row_count.sql \
             schema/ranking_ingestao.sql dev/seed_participante.sql; do
        [[ -f "$sql_base/$f" ]] || { log "   ausente: $sql_base/$f"; missing=1; }
    done
    [[ $missing -eq 0 ]]
}

check_workflow_yaml() {
    local wf="$REPO_ROOT/.github/workflows/teste.yml"
    grep -q "submissions/\*\.json" "$wf" \
        && grep -q "evaluator/evaluator.sh" "$wf" \
        && grep -q "cleanup-all" "$wf" \
        && grep -q "self-hosted" "$wf" \
        && { grep -q "push:" "$wf" || grep -q "workflow_dispatch:" "$wf"; }
}

check_submission_json() {
    local json="$REPO_ROOT/submissions/dev_python.json"
    jq -e '.participante and .repositorio' "$json" >/dev/null
}

prepare_smoke_env() {
    local base_cfg="$JUDGE_DIR/config.env"
    [[ -f "$base_cfg" ]] || base_cfg="$JUDGE_DIR/config.env.example"

    SMOKE_ENV="$(mktemp)"
    {
        echo "# gerado por evaluator/scripts/smoke-test.sh"
        echo "JUIZ_SQL_DIR=$JUDGE_DIR/sql"
        echo "VOLUME_MIN=1"
        echo "VOLUME_MAX=100"
        grep -v -E '^(JUIZ_SQL_DIR|VOLUME_MIN|VOLUME_MAX)=' "$base_cfg" \
            | grep -v '^# gerado por'
    } > "$SMOKE_ENV"

    export JUIZ_CONFIG="$SMOKE_ENV"
    export JUIZ_SQL_DIR="$JUDGE_DIR/sql"
    export VOLUME_MIN=1
    export VOLUME_MAX=100
}

check_postgres_container() {
    local pg_container="${PG_CONTAINER:-postgres_db}"
    docker ps --format '{{.Names}}' | grep -q "^${pg_container}$"
}

check_databases() {
  # shellcheck disable=SC1091
    set -a && source "$SMOKE_ENV" && set +a
    local pg_container="${PG_CONTAINER:-postgres_db}"
    docker exec -e PGPASSWORD="$PG_PASSWORD" "$pg_container" \
        psql -U "$PG_USER" -d "$PG_DB_RANKING" -tAc "SELECT 1" >/dev/null \
        && docker exec -e PGPASSWORD="$PG_PASSWORD" "$pg_container" \
        psql -U "$PG_USER" -d "$PG_DB_EMPRESAS" -tAc "SELECT 1" >/dev/null
}

ensure_schema() {
    chmod +x "$JUDGE_DIR/run-sql.sh"
    JUIZ_CONFIG="$SMOKE_ENV" "$JUDGE_DIR/run-sql.sh" schema >/dev/null
}

check_preflight() {
    python_judge preflight --participante "$PARTICIPANTE" | grep -q PREFLIGHT_OK
}

seed_participant() {
    JUIZ_CONFIG="$SMOKE_ENV" "$JUDGE_DIR/run-sql.sh" seed "$PARTICIPANTE" >/dev/null
}

check_registrar() {
    python_judge registrar \
        --participante "$PARTICIPANTE" \
        --status SMOKE_TEST \
        --repositorio "https://github.com/smoke/test" \
        | grep -q REGISTRADO
}

check_avaliar_classificado() {
    local out
    out="$(python_judge avaliar \
        --participante "$PARTICIPANTE" \
        --repositorio "https://github.com/smoke/test" \
        --tempo 3.0 \
        --exit-code 0 \
        --peak-ram-mb 64 \
        --timed-out false \
        --commit-sha deadbeef \
        --pr-numero 0)"

    echo "$out" | grep -q '"status": "CLASSIFICADO"' \
        && echo "$out" | grep -q '"classificado": true'
}

simulate_workflow_json_pick() {
    local json="$REPO_ROOT/submissions/dev_python.json"
    local picked
    picked="$(echo "$json" | awk '{print $1}')"
    [[ -n "$picked" && -f "$picked" ]]
}

run_evaluator_full() {
    ensure_venv
    SMOKE_JSON="$(mktemp)"
    cat > "$SMOKE_JSON" <<EOF
{
  "participante": "$PARTICIPANTE",
  "repositorio": "file://${REPO_ROOT}/submitter"
}
EOF

    chmod +x "$EVALUATOR_ROOT/evaluator.sh"
    (
        cd "$REPO_ROOT"
        JUIZ_CONFIG="$SMOKE_ENV" \
            PR_NUMERO=0 \
            LOG_RUN_SLUG="${PARTICIPANTE}_smoke" \
            CONTAINER_APP_NAME="app_smoke_test" \
            "$EVALUATOR_ROOT/evaluator.sh" "$SMOKE_JSON"
    )
}

main() {
    local log_slug="smoke_test"
    $RUN_FULL && log_slug="${log_slug}_full"

    # shellcheck disable=SC1091
    source "$EVALUATOR_ROOT/scripts/lib/log-run.sh"
    log_run_init smoke-test "$log_slug"
    trap 'log_run_finish $?' EXIT

    log "Smoke test — Ingestão no Limite"
    log "Repo: $REPO_ROOT | evaluator: $EVALUATOR_ROOT | participante: $PARTICIPANTE"

    run_step "Toolchain (jq, git, docker, python3)" check_toolchain

    if ensure_venv && check_python_deps 2>/dev/null; then
        pass "Dependências Python (venv + psycopg2, boto3)"
    else
        fail "Dependências Python (venv + psycopg2, boto3)"
    fi

    run_step "Layout do repositório" check_repo_layout
    run_step "Layout SQL do judge" check_sql_layout
    run_step "Workflow teste.yml" check_workflow_yaml
    run_step "JSON de submissão (dev_python)" check_submission_json
    run_step "Simulação de pick do workflow" simulate_workflow_json_pick

    prepare_smoke_env
    pass "Config smoke gerada ($SMOKE_ENV)"

    if check_postgres_container; then
        pass "Container Postgres rodando"
    else
        fail "Container Postgres rodando"
        log ""
        log "Resumo: $PASS ok, $FAIL falha(s), $SKIP pulado(s)"
        exit 1
    fi

    run_step "Conexão aos bancos db_ingestao e db_empresas" check_databases
    run_step "Schema ranking (idempotente)" ensure_schema
    run_step "Preflight do judge" check_preflight

    if $RUN_SEED; then
        run_step "Seed da tabela ${PARTICIPANTE}_empresas" seed_participant
    else
        skip "Seed da tabela ( --no-seed )"
    fi

    run_step "Registrar status no ranking" check_registrar
    run_step "Avaliar gates + CLASSIFICADO (judge)" check_avaliar_classificado

    if $RUN_FULL; then
        if $RUN_SEED; then
            seed_participant >/dev/null 2>&1 || true
        fi
        log ""
        log "── Evaluator ponta a ponta (--full)"
        if run_evaluator_full; then
            pass "Evaluator ponta a ponta (--full)"
        else
            fail "Evaluator ponta a ponta (--full)"
        fi
    else
        skip "Evaluator ponta a ponta (use --full)"
    fi

    log ""
    if [[ $FAIL -eq 0 ]]; then
        log "🎉 Smoke test OK — $PASS passou, $SKIP pulado(s)"
        exit 0
    fi

    log "💥 Smoke test FALHOU — $PASS ok, $FAIL falha(s), $SKIP pulado(s)"
    exit 1
}

main "$@"
