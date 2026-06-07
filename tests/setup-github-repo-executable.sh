#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${REPO_ROOT}/setup-github-repo.sh"

if [[ ! -x "$SCRIPT_PATH" ]]; then
    echo "setup-github-repo.sh must be executable for the documented ./setup-github-repo.sh command" >&2
    exit 1
fi

echo "setup-github-repo executable entrypoint: PASS"
