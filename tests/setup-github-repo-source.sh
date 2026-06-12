#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
CALLER_DIR="${TEST_ROOT}/unrelated working directory"
GH_LOG="${TEST_ROOT}/gh-repo-create.args"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "${TEST_ROOT}/bin" "$CALLER_DIR"

cat > "${TEST_ROOT}/bin/gh" <<'EOF'
#!/bin/bash
set -euo pipefail

case "${1:-} ${2:-}" in
    "auth status")
        exit 0
        ;;
    "repo create")
        printf '%s\n' "$@" > "$GH_LOG"
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

(
    cd "$CALLER_DIR"
    PATH="${TEST_ROOT}/bin:${PATH}" GH_LOG="$GH_LOG" \
        bash "${REPO_ROOT}/setup-github-repo.sh" >/dev/null
)

if ! grep -Fqx -- "--source=${REPO_ROOT}" "$GH_LOG"; then
    echo "setup-github-repo.sh must publish the repository containing the script" >&2
    cat "$GH_LOG" >&2
    exit 1
fi

if grep -Fqx -- "--source=." "$GH_LOG"; then
    echo "setup-github-repo.sh must not publish the caller's working directory" >&2
    exit 1
fi

echo "setup-github-repo source directory: PASS"
