#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
TEST_HOME="${TEST_ROOT}/home"
INSTALL_DIR="${TEST_HOME}/.claude/skills/ai-office-landing"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$TEST_HOME"

missing_output="${TEST_ROOT}/missing.log"
if HOME="$TEST_HOME" bash "${REPO_ROOT}/examples/test.sh" >"$missing_output" 2>&1; then
    echo "expected the install check to fail when the skill is not installed" >&2
    cat "$missing_output" >&2
    exit 1
fi

if ! grep -q "未检测到安装目录" "$missing_output"; then
    echo "expected an actionable missing-install error" >&2
    cat "$missing_output" >&2
    exit 1
fi

mkdir -p "$(dirname "$INSTALL_DIR")"
cp -R "$REPO_ROOT" "$INSTALL_DIR"

healthy_output="${TEST_ROOT}/healthy.log"
if ! HOME="$TEST_HOME" bash "${REPO_ROOT}/examples/test.sh" >"$healthy_output" 2>&1; then
    echo "expected a complete installation to pass validation" >&2
    cat "$healthy_output" >&2
    exit 1
fi

if ! grep -q "安装验证通过" "$healthy_output"; then
    echo "expected a clear successful validation message" >&2
    cat "$healthy_output" >&2
    exit 1
fi

rm "$INSTALL_DIR/orchestrator.sh"

broken_output="${TEST_ROOT}/broken.log"
if HOME="$TEST_HOME" bash "${REPO_ROOT}/examples/test.sh" >"$broken_output" 2>&1; then
    echo "expected the install check to fail when a critical file is missing" >&2
    cat "$broken_output" >&2
    exit 1
fi

if ! grep -q "orchestrator.sh" "$broken_output"; then
    echo "expected the broken-install error to name the missing file" >&2
    cat "$broken_output" >&2
    exit 1
fi

echo "examples install check: PASS"
