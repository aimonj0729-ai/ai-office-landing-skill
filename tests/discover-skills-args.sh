#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

run_missing_arg_case() {
    local command_name="$1"
    local expected_usage="$2"
    shift 2
    local output_file="${TEST_ROOT}/${command_name}.log"

    set +e
    (
        cd "$TEST_ROOT"
        bash "${REPO_ROOT}/discover-skills.sh" "$command_name" "$@"
    ) >"$output_file" 2>&1
    local status=$?
    set -e

    if [[ "$status" -eq 0 ]]; then
        echo "discover-skills.sh ${command_name} must fail when required args are missing" >&2
        cat "$output_file" >&2
        exit 1
    fi

    if ! grep -Fq "缺少 ${command_name} 参数" "$output_file"; then
        echo "expected a specific missing-argument error for ${command_name}" >&2
        cat "$output_file" >&2
        exit 1
    fi

    if ! grep -Fq "$expected_usage" "$output_file"; then
        echo "expected usage guidance for ${command_name}" >&2
        cat "$output_file" >&2
        exit 1
    fi

    if grep -Fq "Skill '' 不存在" "$output_file"; then
        echo "missing args should not fall through to an empty skill lookup" >&2
        cat "$output_file" >&2
        exit 1
    fi
}

run_missing_arg_case "discover" "discover <keyword> [category]"
run_missing_arg_case "info" "info <skill-name>"
run_missing_arg_case "load" "load <agent> <skill-name>" "designer"
run_missing_arg_case "suggest" "suggest <task-desc> [agent]"

echo "discover skills arg validation: PASS"
