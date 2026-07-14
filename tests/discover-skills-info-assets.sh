#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

SKILL_DIR="${TEST_ROOT}/.claude/skills/multi-assets"
mkdir -p "${SKILL_DIR}/assets"
printf '%s\n' "multi-assets" > "${SKILL_DIR}/NAME"
printf '%s\n' "# Multi Assets" > "${SKILL_DIR}/SKILL.md"
printf '%s\n' "one" > "${SKILL_DIR}/assets/one.txt"
printf '%s\n' "two" > "${SKILL_DIR}/assets/two.txt"

OUTPUT_FILE="${TEST_ROOT}/info.log"
(
    cd "$TEST_ROOT"
    HOME="$TEST_ROOT" SKILL_ROOT="$REPO_ROOT" bash "${REPO_ROOT}/discover-skills.sh" info multi-assets
) >"$OUTPUT_FILE" 2>&1

if ! grep -Fq "Skill: multi-assets" "$OUTPUT_FILE"; then
    echo "expected info output for the test skill" >&2
    cat "$OUTPUT_FILE" >&2
    exit 1
fi

if ! grep -Fq "Has assets: ✓" "$OUTPUT_FILE"; then
    echo "expected info to report non-empty assets directories with multiple files" >&2
    cat "$OUTPUT_FILE" >&2
    exit 1
fi

echo "discover skills info assets: PASS"
