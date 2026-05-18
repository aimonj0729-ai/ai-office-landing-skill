#!/bin/bash
#
# GitHub Repository Setup Script for AI Office Landing
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR_SHELL="$(printf '%q' "$CURRENT_DIR")"
MANIFEST_PATH="${CURRENT_DIR}/.claude-plugin/manifest.json"
SKILL_VERSION="$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFEST_PATH" | head -n 1)"
SKILL_VERSION="${SKILL_VERSION:-2.4.0}"
SKILL_SHORT_VERSION="${SKILL_VERSION%.*}"
REPO_NAME="ai-office-landing-skill"
REPO_DESC="AI-powered landing page generator with multi-agent orchestration, cost tracking, and dynamic skill discovery (Claude Code Skill)"
REPO_OWNER_HINT="${GITHUB_OWNER:-${REPO_OWNER:-<your-github-username>}}"

echo "📦 准备发布 AI Office Landing v${SKILL_SHORT_VERSION} 到 GitHub"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) 未安装"
    echo ""
    echo "请按以下步骤安装:"
    echo "  brew install gh"
    echo ""
    echo "或使用以下手动步骤发布:"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "手动发布步骤:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. 访问: https://github.com/new"
    echo ""
    echo "2. 填写仓库信息:"
    echo "   - 仓库名称: ${REPO_NAME}"
    echo "   - 描述: ${REPO_DESC}"
    echo "   - 选择: Public"
    echo "   - 保持仓库为空: 不要勾选 README / .gitignore / License"
    echo ""
    echo "3. 创建完成后，执行:"
    echo "   cd ${CURRENT_DIR_SHELL}"
    echo "   git remote add origin https://github.com/${REPO_OWNER_HINT}/${REPO_NAME}.git"
    echo "   git push -u origin main"
    echo ""
    echo "提示: 这里建议创建空仓库；如果先让 GitHub 自动生成 README 或 License，直接 push 很可能会因为远端已有初始提交而被拒绝。"
    echo "提示: 如需把远程地址里的 owner 也自动替换成真实值，可先设置 GITHUB_OWNER 或 REPO_OWNER 后再运行此脚本。"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi

# Check if user is logged in
echo "🔑 检查 GitHub 认证状态..."
if ! gh auth status; then
    echo ""
    echo "请先登录 GitHub:"
    echo "  gh auth login"
    exit 1
fi

# Create repository
echo ""
echo "📚 创建 GitHub 仓库..."

if ! gh repo create "$REPO_NAME" \
  --public \
  --description "$REPO_DESC" \
  --source=. \
  --remote=origin \
  --push; then
    echo ""
    echo "❌ GitHub 仓库创建失败，请修复上面的错误后重试"
    exit 1
fi

if ! REPO_OWNER="$(gh api user --jq .login)"; then
    echo ""
    echo "❌ 无法读取当前 GitHub 用户信息，请确认 gh 登录状态后重试"
    exit 1
fi

echo ""
echo "✅ GitHub 仓库已创建成功!"
echo ""
echo "🔗 仓库地址: https://github.com/${REPO_OWNER}/$REPO_NAME"
echo ""
echo "🚀 下一步:"
echo "   1. 访问仓库查看代码"
echo "   2. 分享给其他人使用"
echo "   3. 在 README 中添加使用示例"
echo ""
echo "📖 安装和使用说明:"
echo ""
cat <<'EOF' | sed \
  -e "s/__SKILL_SHORT_VERSION__/${SKILL_SHORT_VERSION}/g" \
  -e "s/__REPO_OWNER__/${REPO_OWNER}/g" \
  -e "s/__REPO_NAME__/${REPO_NAME}/g"
## Installation

### Option 1: Direct Download
```bash
tmpdir=$(mktemp -d)
cd "$tmpdir"
wget -O ai-office-landing-skill.tar.gz https://github.com/__REPO_OWNER__/__REPO_NAME__/archive/refs/heads/main.tar.gz
tar -xzf ai-office-landing-skill.tar.gz
cd ai-office-landing-skill-main
./install.sh
```

### Option 2: Git Clone
```bash
tmpdir=$(mktemp -d)
git clone https://github.com/__REPO_OWNER__/__REPO_NAME__.git "$tmpdir/ai-office-landing-skill"
cd "$tmpdir/ai-office-landing-skill"
./install.sh
```

### Option 3: CURL + Tarball
```bash
tmpdir=$(mktemp -d)
cd "$tmpdir"
curl -fsSL -o ai-office-landing-skill.tar.gz https://github.com/__REPO_OWNER__/__REPO_NAME__/archive/refs/heads/main.tar.gz
tar -xzf ai-office-landing-skill.tar.gz
cd ai-office-landing-skill-main
./install.sh
```

## Usage

```bash
# Start Claude Code
claude

# Use the skill
/landing

# Or with options
/landing --serial   # Serial execution
/landing --human    # Human critic review
/landing --resume   # Resume from checkpoint
```

## Features

✨ **Current Workflow Features (v__SKILL_SHORT_VERSION__):**
- Phase 3.5 Orchestrator - Automatic work integration
- Dynamic skill discovery - Designer auto-finds relevant skills
- Cross-agent consistency checks
- Progress dashboard
- Cost tracking
- Benchmark analysis

### Multi-Agent Workflow

1. **Phase 0-1**: Interview & brief generation
2. **Phase 2**: Style tokens & task creation
3. **Phase 3**: Parallel execution (Copy, Design, Frontend, SEO)
4. **Phase 3.5**: Orchestrator auto-summary
5. **Phase 4**: Critic review with benchmark analysis
6. **Phase 5**: Delivery

## Documentation

- [README.md](README.md) - Full documentation
- [SKILL.md](SKILL.md) - Workflow definition
- [install.sh](install.sh) - Installation script

## License

MIT License - see [LICENSE](LICENSE) file
EOF
