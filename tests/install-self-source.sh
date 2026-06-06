#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
INSTALL_DIR="${TEST_HOME}/.claude/skills/ai-office-landing"

cleanup() {
    rm -rf "$TEST_HOME"
}
trap cleanup EXIT

mkdir -p "$(dirname "$INSTALL_DIR")"
cp -R "$REPO_ROOT" "$INSTALL_DIR"

for command in install reinstall; do
    output_file="${TEST_HOME}/${command}-output.log"

    set +e
    HOME="$TEST_HOME" bash "${INSTALL_DIR}/install.sh" "$command" --force >"$output_file" 2>&1
    status=$?
    set -e

    if [[ "$status" -eq 0 ]]; then
        echo "expected ${command} from the target directory to fail" >&2
        exit 1
    fi

    if ! grep -q "不能从最终安装目录运行安装器" "$output_file"; then
        echo "expected an actionable ${command} error message" >&2
        cat "$output_file" >&2
        exit 1
    fi

    if [[ ! -f "${INSTALL_DIR}/install.sh" || ! -f "${INSTALL_DIR}/SKILL.md" ]]; then
        echo "${command} source was modified before the safety check" >&2
        exit 1
    fi

    if compgen -G "${INSTALL_DIR}.backup.*" >/dev/null; then
        echo "${command} created a backup before rejecting the unsafe source path" >&2
        exit 1
    fi
done

echo "install self-source guard: PASS"
