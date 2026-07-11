#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
INSTALL_DIR="${TEST_HOME}/.claude/skills/ai-office-landing"
OUTPUT_FILE="${TEST_HOME}/reinstall-output.log"

cleanup() {
    rm -rf "$TEST_HOME"
}
trap cleanup EXIT

mkdir -p "${INSTALL_DIR}/.claude-plugin" "${TEST_HOME}/.claude"
cp "${REPO_ROOT}/.claude-plugin/manifest.json" "${INSTALL_DIR}/.claude-plugin/manifest.json"
printf '%s\n' "keep this prior installation" > "${INSTALL_DIR}/previous-install.txt"
printf '%s\n' '{}' > "${TEST_HOME}/.claude/settings.json"

HOME="$TEST_HOME" bash "${REPO_ROOT}/install.sh" reinstall --force >"$OUTPUT_FILE" 2>&1

backup_dir="$(find "$(dirname "$INSTALL_DIR")" -maxdepth 1 -type d -name 'ai-office-landing.backup.*' -print -quit)"
if [[ -z "$backup_dir" ]]; then
    echo "reinstall must preserve the previous installation as a timestamped backup" >&2
    cat "$OUTPUT_FILE" >&2
    exit 1
fi

if [[ ! -f "${backup_dir}/previous-install.txt" ]]; then
    echo "reinstall backup did not preserve the previous installation contents" >&2
    exit 1
fi

if [[ ! -f "${INSTALL_DIR}/SKILL.md" || ! -f "${INSTALL_DIR}/.claude-plugin/manifest.json" ]]; then
    echo "reinstall did not create a complete replacement installation" >&2
    exit 1
fi

if [[ ! -f "${INSTALL_DIR}/LICENSE" ]]; then
    echo "install should copy LICENSE because the installed README references it" >&2
    exit 1
fi

echo "install reinstall backup: PASS"
