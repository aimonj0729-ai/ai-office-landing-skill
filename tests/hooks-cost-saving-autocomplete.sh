#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for option in "--cost-saving" "--adapter <name>"; do
    if ! jq -e --arg option "$option" \
        '.commands[]
        | select(.name == "/landing")
        | .autocomplete[]
        | select(.option == $option)' \
        "${REPO_ROOT}/.claude-plugin/hooks.json" >/dev/null; then
        echo "hooks autocomplete must expose ${option}" >&2
        exit 1
    fi
done

for expected in "/landing --cost-saving" "/landing --adapter deepseek-api"; do
    if ! grep -Fq "$expected" "${REPO_ROOT}/install.sh"; then
        echo "generated workflow demo must include: ${expected}" >&2
        exit 1
    fi
done

echo "hooks cost-saving autocomplete: PASS"
