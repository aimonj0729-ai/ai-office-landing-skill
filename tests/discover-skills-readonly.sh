#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

run_readonly_case() {
    local case_name="$1"
    shift
    local case_dir="${TEST_ROOT}/${case_name}"

    mkdir -p "$case_dir"

    (
        cd "$case_dir"
        bash "${REPO_ROOT}/discover-skills.sh" "$@" >/dev/null
    )

    if [[ -e "${case_dir}/ai-office/state.json" ]]; then
        echo "discover-skills.sh $* should not initialize workflow state" >&2
        exit 1
    fi
}

run_readonly_case "help" help
run_readonly_case "info" info ai-office-landing

stateful_dir="${TEST_ROOT}/discover"
mkdir -p "$stateful_dir"
(
    cd "$stateful_dir"
    bash "${REPO_ROOT}/discover-skills.sh" discover landing >/dev/null
)

if [[ ! -f "${stateful_dir}/ai-office/state.json" ]]; then
    echo "discover-skills.sh discover should still initialize workflow state" >&2
    exit 1
fi

echo "discover skills readonly commands: PASS"
