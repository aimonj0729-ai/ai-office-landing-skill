#!/bin/bash
#
# AI Office Landing Skill - Installation Script
# Version: 2.3.0
#

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Paths
SKILL_NAME="ai-office-landing"
INSTALL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging
log() {
    echo -e "${BLUE}[INSTALL]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# Check requirements
check_requirements() {
    log "检查系统要求..."

    # Check bash version
    if [[ "${BASH_VERSINFO[0]}" -lt 3 ]] || [[ "${BASH_VERSINFO[0]}" -eq 3 && "${BASH_VERSINFO[1]}" -lt 2 ]]; then
        error "需要 Bash 3.2+，当前版本: ${BASH_VERSION}"
    fi

    # Check jq
    if ! command -v jq &> /dev/null; then
        error "需要 jq 工具，请先安装: brew install jq (macOS) 或 apt install jq (Linux)"
    fi

    # Check node
    if ! command -v node &> /dev/null; then
        warn "Node.js 未安装，某些功能可能受限"
    else
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$NODE_VERSION" -lt 16 ]]; then
            warn "Node.js 版本过低 (需要 16+)，某些功能可能受限"
        fi
    fi

    success "系统要求检查通过"
}

# Check if skill already exists
check_existing() {
    if [[ -d "$INSTALL_DIR" ]]; then
        warn "发现已存在的 ${SKILL_NAME} skill"

        if [[ -f "${INSTALL_DIR}/.claude-plugin/manifest.json" ]]; then
            EXISTING_VERSION=$(jq -r '.version' "${INSTALL_DIR}/.claude-plugin/manifest.json")
            log "现有版本: v${EXISTING_VERSION}"
        fi

        read -p "是否要覆盖安装? (y/n): " -n 1 -r
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "安装已取消"
            exit 0
        fi

        log "备份现有安装..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Install the skill
install_skill() {
    log "安装 ${SKILL_NAME} v2.3.0..."

    # Create directories
    mkdir -p "${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}/.claude-plugin"
    mkdir -p "${INSTALL_DIR}/prompts"
    mkdir -p "${INSTALL_DIR}/templates"
    mkdir -p "${INSTALL_DIR}/adapters"

    # Copy all files
    log "复制文件..."

    # Root files
    cp -r "${CURRENT_DIR}/SKILL.md" "$INSTALL_DIR/" 2>/dev/null || true
    cp -r "${CURRENT_DIR}/README.md" "$INSTALL_DIR/" 2>/dev/null || true
    cp -r "${CURRENT_DIR}/NAME" "$INSTALL_DIR/" 2>/dev/null || true
    cp -r "${CURRENT_DIR}/interview.md" "$INSTALL_DIR/" 2>/dev/null || true
    cp -r "${CURRENT_DIR}/critic-checklist.md" "$INSTALL_DIR/" 2>/dev/null || true

    # Scripts (make executable)
    cp -r "${CURRENT_DIR}"/*.sh "$INSTALL_DIR/"
    chmod +x "${INSTALL_DIR}"/*.sh

    # Directories
    cp -r "${CURRENT_DIR}/.claude-plugin"/* "${INSTALL_DIR}/.claude-plugin/"
    cp -r "${CURRENT_DIR}/prompts"/* "${INSTALL_DIR}/prompts/"
    cp -r "${CURRENT_DIR}/templates"/* "${INSTALL_DIR}/templates/" 2>/dev/null || true
    cp -r "${CURRENT_DIR}/adapters"/* "${INSTALL_DIR}/adapters/" 2>/dev/null || true

    success "文件复制完成"
}

# Verify installation
verify_installation() {
    log "验证安装..."

    # Check critical files
    CRITICAL_FILES=(
        "SKILL.md"
        "README.md"
        ".claude-plugin/manifest.json"
        ".claude-plugin/hooks.json"
        "prompts/interviewer.md"
        "prompts/designer.md"
        "prompts/orchestrator-summary.md"
        "cost-tracker.sh"
        "orchestrator.sh"
        "discover-skills.sh"
        "state-management.sh"
    )

    for file in "${CRITICAL_FILES[@]}"; do
        if [[ ! -f "${INSTALL_DIR}/${file}" ]]; then
            error "缺少关键文件: ${file}"
        fi
    done

    # Check manifest
    if [[ ! -f "${INSTALL_DIR}/.claude-plugin/manifest.json" ]]; then
        error "manifest.json 不存在"
    fi

    # Verify version
    INSTALLED_VERSION=$(jq -r '.version' "${INSTALL_DIR}/.claude-plugin/manifest.json")
    if [[ "$INSTALLED_VERSION" != "2.3.0" ]]; then
        warn "版本不匹配: 期望 2.3.0, 实际 ${INSTALLED_VERSION}"
    fi

    success "安装验证通过"
}

# Update Claude Code settings
update_claude_settings() {
    log "更新 Claude Code 配置..."

    SETTINGS_FILE="${HOME}/.claude/settings.json"

    # Backup existing settings
    if [[ -f "$SETTINGS_FILE" ]]; then
        cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"
        log "已备份现有配置"
    fi

    # Check if skill already registered
    if [[ -f "$SETTINGS_FILE" ]]; then
        if jq -e '.skills["ai-office-landing"]' "$SETTINGS_FILE" > /dev/null 2>&1; then
            log "skill 已注册，跳过"
            return 0
        fi
    fi

    # Add skill to settings
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo "{}" > "$SETTINGS_FILE"
    fi

    # Register the skill
    jq '.skills["ai-office-landing"] = "'"${INSTALL_DIR}"'/SKILL.md"' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

    success "Claude Code 配置已更新"
}

# Create example workflow
create_example() {
    log "创建示例工作流..."

    EXAMPLE_DIR="${INSTALL_DIR}/examples"
    mkdir -p "$EXAMPLE_DIR"

    cat > "${EXAMPLE_DIR}/workflow-demo.sh" << 'EOF'
#!/bin/bash
#
# AI Office Landing - 示例工作流
#

echo "🚀 AI Office Landing v2.3 - 示例工作流"
echo ""
echo "1. 启动工作流:"
echo "   /landing"
echo ""
echo "2. 串行模式（避免超限）:"
echo "   /landing --serial"
echo ""
echo "3. 人工审查（节省成本）:"
echo "   /landing --human"
echo ""
echo "4. Skill 发现工具:"
echo "   ~/.claude/skills/ai-office-landing/discover-skills.sh auto-designer"
echo ""
echo "5. Orchestrator 汇总:"
echo "   ~/.claude/skills/ai-office-landing/orchestrator.sh"
echo ""
echo "✨ v2.3 新增:"
echo "   - Phase 3.5 Orchestrator 自动汇总"
echo "   - 动态 Skill 发现（Designer 自动）"
echo "   - 跨 Agent 一致性检查"
echo "   - 进度仪表板"
EOF

    chmod +x "${EXAMPLE_DIR}/workflow-demo.sh"
    success "示例工作流已创建"
}

# Print success message
print_success() {
    log "安装完成！"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            AI Office Landing v2.3.0 安装成功！           ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║  📁 安装路径: ${INSTALL_DIR}                               ║${NC}"
    echo -e "${GREEN}║  📖 文档:    README.md                                     ║${NC}"
    echo -e "${GREEN}║  🎯 快速开始: /landing                                     ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  新增 v2.3 特性:                                          ║${NC}"
    echo -e "${GREEN}║  ✓ Phase 3.5 Orchestrator - 自动工作汇总                  ║${NC}"
    echo -e "${GREEN}║  ✓ 动态 Skill 发现 - Designer 自动查找相关技能           ║${NC}"
    echo -e "${GREEN}║  ✓ 跨 Agent 一致性检查 - 自动识别冲突和缺口              ║${NC}"
    echo -e "${GREEN}║  ✓ 进度仪表板 - 可视化显示执行状态                       ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  下一步:                                                  ║${NC}"
    echo -e "${GREEN}║  1. 打开新终端                                            ║${NC}"
    echo -e "${GREEN}║  2. 输入: claude                                           ║${NC}"
    echo -e "${GREEN}║  3. 输入: /landing                                         ║${NC}"
    echo -e "${GREEN}║  4. 开始创建你的落地页！                                   ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print usage
print_usage() {
    log "查看示例:"
    echo ""
    echo "examples/workflow-demo.sh"
    echo ""
    echo "查看详情:"
    echo "cat ~/.claude/skills/${SKILL_NAME}/README.md"
    echo ""
}

# Main installation
main() {
    log "AI Office Landing v2.3.0 安装程序"
    log "=================================="
    echo ""

    check_requirements
    echo ""
    check_existing
    echo ""
    install_skill
    echo ""
    verify_installation
    echo ""
    update_claude_settings
    echo ""
    create_example
    echo ""

    print_success
    print_usage

    log "享受 v2.3！"
}

# Handle command line arguments
case "${1:-install}" in
    install)
        main
        ;;
    uninstall)
        if [[ -d "$INSTALL_DIR" ]]; then
            log "卸载 ${SKILL_NAME}..."
            rm -rf "$INSTALL_DIR"
            success "已卸载"
        else
            warn "技能未安装"
        fi
        ;;
    reinstall)
        "$0" uninstall
        sleep 1
        "$0" install
        ;;
    check)
        if [[ -d "$INSTALL_DIR" ]]; then
            VERSION=$(jq -r '.version' "${INSTALL_DIR}/.claude-plugin/manifest.json")
            success "已安装: ${SKILL_NAME} v${VERSION}"
        else
            warn "未安装"
        fi
        ;;
    *)
        echo "用法: $0 {install|uninstall|reinstall|check}"
        echo ""
        echo "命令:"
        echo "  install     - 安装技能 (默认)"
        echo "  uninstall   - 卸载技能"
        echo "  reinstall   - 重新安装 (覆盖更新)"
        echo "  check       - 检查是否已安装"
        exit 1
        ;;
esac

exit 0
