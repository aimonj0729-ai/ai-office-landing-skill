#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED_TEMP_FILE="/tmp/progress_table.md"
BACKUP_FILE="$(mktemp)"
HAD_SHARED_TEMP_FILE=false

cleanup() {
    if [[ "$HAD_SHARED_TEMP_FILE" == "true" ]]; then
        cp "$BACKUP_FILE" "$SHARED_TEMP_FILE"
    else
        rm -f "$SHARED_TEMP_FILE"
    fi
    rm -f "$BACKUP_FILE"
}
trap cleanup EXIT

if [[ -f "$SHARED_TEMP_FILE" ]]; then
    cp "$SHARED_TEMP_FILE" "$BACKUP_FILE"
    HAD_SHARED_TEMP_FILE=true
fi

printf '%s\n' "preserve existing temp content" > "$SHARED_TEMP_FILE"

dashboard_output="$(
    SKILL_ROOT="$REPO_ROOT"
    source "${REPO_ROOT}/orchestrator.sh"
    generate_progress_dashboard
)"

if [[ "$(cat "$SHARED_TEMP_FILE")" != "preserve existing temp content" ]]; then
    echo "progress dashboard must not overwrite the shared /tmp/progress_table.md path" >&2
    exit 1
fi

if ! grep -Fq "| Agent | Task | Status | Progress | Key Metrics |" <<< "$dashboard_output"; then
    echo "progress dashboard output is missing its table header" >&2
    exit 1
fi

echo "orchestrator progress dashboard temp isolation: PASS"
