#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

(
    cd "$TEST_ROOT"
    source "${REPO_ROOT}/cost-tracker.sh"

    update_cost_db "notes.status" "phase 3 needs review"
    update_cost_db "metrics.tokens" "123"
    update_cost_db "phase_breakdown.phase-3" '{"tokens":456,"model":"deepseek"}'

    if [[ "$(jq -r '.notes.status' "$COST_DB_PATH")" != "phase 3 needs review" ]]; then
        echo "plain string values must be written as JSON strings" >&2
        exit 1
    fi

    if [[ "$(jq -r '.metrics.tokens | type' "$COST_DB_PATH")" != "number" ]]; then
        echo "valid JSON number values must keep their numeric type" >&2
        exit 1
    fi

    if [[ "$(jq -r '.phase_breakdown["phase-3"].model' "$COST_DB_PATH")" != "deepseek" ]]; then
        echo "valid JSON object values must still be written as objects" >&2
        exit 1
    fi
)

echo "cost tracker string write: PASS"
