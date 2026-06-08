#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_MANIFEST="${REPO_ROOT}/.claude-plugin/manifest.json"
INSTALL_DIR="${HOME}/.claude/skills/ai-office-landing"
INSTALLED_MANIFEST="${INSTALL_DIR}/.claude-plugin/manifest.json"

fail() {
    echo "✗ $1" >&2
    echo "请从完整仓库运行: ./install.sh reinstall --force" >&2
    exit 1
}

if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "✗ 未检测到安装目录: ${INSTALL_DIR}" >&2
    echo "请先从完整仓库运行: ./install.sh install" >&2
    exit 1
fi

command -v jq >/dev/null 2>&1 || fail "缺少 jq，无法验证 manifest"

if ! jq -e '.' "$SOURCE_MANIFEST" >/dev/null 2>&1; then
    fail "源码 manifest 无效: ${SOURCE_MANIFEST}"
fi

if ! jq -e '.' "$INSTALLED_MANIFEST" >/dev/null 2>&1; then
    fail "安装 manifest 缺失或不是有效 JSON: ${INSTALLED_MANIFEST}"
fi

SKILL_VERSION="$(jq -r '.version // empty' "$SOURCE_MANIFEST")"
INSTALLED_VERSION="$(jq -r '.version // empty' "$INSTALLED_MANIFEST")"

if [[ -z "$SKILL_VERSION" || "$INSTALLED_VERSION" != "$SKILL_VERSION" ]]; then
    fail "安装版本不匹配: 期望 ${SKILL_VERSION:-unknown}，实际 ${INSTALLED_VERSION:-unknown}"
fi

CRITICAL_FILES=(
    "SKILL.md"
    "README.md"
    ".claude-plugin/hooks.json"
    "interview.md"
    "prompts/designer.md"
    "prompts/orchestrator-summary.md"
    "cost-tracker.sh"
    "orchestrator.sh"
    "discover-skills.sh"
    "state-management.sh"
)

for file in "${CRITICAL_FILES[@]}"; do
    [[ -f "${INSTALL_DIR}/${file}" ]] || fail "安装不完整，缺少关键文件: ${file}"
done

for script in cost-tracker.sh orchestrator.sh discover-skills.sh state-management.sh; do
    [[ -x "${INSTALL_DIR}/${script}" ]] || fail "安装脚本不可执行: ${script}"
done

echo "AI Office Landing v${INSTALLED_VERSION} - 安装验证"
echo ""
echo "✓ 安装验证通过: ${INSTALL_DIR}"
echo "✓ 版本: v${INSTALLED_VERSION}"
echo "✓ 核心组件:"
echo "  - orchestrator.sh (Phase 3.5 工作集成)"
echo "  - discover-skills.sh (动态 Skill 发现)"
echo "  - cost-tracker.sh (成本追踪)"
echo "✓ 快捷命令: /landing"
echo ""
echo "开始使用:"
echo "  claude"
echo "  /landing"
echo ""
