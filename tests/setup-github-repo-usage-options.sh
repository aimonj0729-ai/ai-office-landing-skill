#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
OUTPUT_FILE="${TEST_ROOT}/setup-output.txt"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "${TEST_ROOT}/bin"

cat > "${TEST_ROOT}/bin/gh" <<'EOF'
#!/bin/bash
set -euo pipefail

case "${1:-} ${2:-}" in
    "auth status")
        exit 0
        ;;
    "repo create")
        exit 0
        ;;
    "api user")
        printf '%s\n' "test-owner"
        exit 0
        ;;
esac

printf 'unexpected gh invocation: %s\n' "$*" >&2
exit 1
EOF
chmod +x "${TEST_ROOT}/bin/gh"

PATH="${TEST_ROOT}/bin:${PATH}" bash "${REPO_ROOT}/setup-github-repo.sh" > "$OUTPUT_FILE"

for expected in "/landing --cost-saving" "/landing --adapter deepseek-api"; do
    if ! grep -Fq "$expected" "$OUTPUT_FILE"; then
        echo "setup-github-repo.sh generated usage must include: ${expected}" >&2
        cat "$OUTPUT_FILE" >&2
        exit 1
    fi
done

echo "setup-github-repo usage options: PASS"
