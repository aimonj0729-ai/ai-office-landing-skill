#!/bin/bash
#
# AI Office Landing Skill - Installation Script
# Version: follows .claude-plugin/manifest.json
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
MANIFEST_PATH="${CURRENT_DIR}/.claude-plugin/manifest.json"
SETTINGS_FILE="${HOME}/.claude/settings.json"
COMMAND="install"
FORCE_INSTALL=false

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

read_manifest_version() {
    if [[ ! -f "$MANIFEST_PATH" ]]; then
        error "缺少 manifest.json: ${MANIFEST_PATH}"
    fi

    local version
    version=$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFEST_PATH" | head -n 1)

    if [[ -z "$version" ]]; then
        error "无法从 manifest.json 读取版本号"
    fi

    echo "$version"
}

SKILL_VERSION="$(read_manifest_version)"
SKILL_SHORT_VERSION="${SKILL_VERSION%.*}"

validate_install_source() {
    local current_dir_physical=""
    local install_dir_physical=""

    if [[ ! -d "$INSTALL_DIR" ]]; then
        return 0
    fi

    current_dir_physical="$(cd "$CURRENT_DIR" && pwd -P)"
    install_dir_physical="$(cd "$INSTALL_DIR" && pwd -P)"

    if [[ "$current_dir_physical" == "$install_dir_physical" ]]; then
        error "不能从最终安装目录运行安装器: ${INSTALL_DIR}。请从临时 checkout 或其他源码目录运行 ./install.sh。原目录未被修改。"
    fi
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

validate_claude_settings() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        return 0
    fi

    if ! jq -e '.' "$SETTINGS_FILE" >/dev/null 2>&1; then
        error "Claude Code 配置损坏: ${SETTINGS_FILE} 不是有效 JSON。请先修复或删除该文件后再重试。原文件未被修改。"
    fi

    if ! jq -e '(.skills? == null) or ((.skills | type) == "object")' "$SETTINGS_FILE" >/dev/null 2>&1; then
        error "Claude Code 配置中的 .skills 不是对象，无法安全注册 ${SKILL_NAME}。请先修复 ${SETTINGS_FILE} 后再重试。"
    fi
}

INSTALL_HEALTH_STATUS="unknown"
INSTALL_HEALTH_MESSAGE=""
INSTALL_HEALTH_VERSION=""

assess_installed_skill() {
    local manifest_path="${INSTALL_DIR}/.claude-plugin/manifest.json"
    local version=""

    INSTALL_HEALTH_STATUS="missing"
    INSTALL_HEALTH_MESSAGE="未安装"
    INSTALL_HEALTH_VERSION=""

    if [[ ! -d "$INSTALL_DIR" ]]; then
        return 1
    fi

    if [[ ! -f "$manifest_path" ]]; then
        INSTALL_HEALTH_STATUS="broken"
        INSTALL_HEALTH_MESSAGE="检测到安装目录存在，但缺少 ${manifest_path}。这通常表示之前的安装中断了。"
        return 1
    fi

    if ! jq -e '.' "$manifest_path" >/dev/null 2>&1; then
        INSTALL_HEALTH_STATUS="broken"
        INSTALL_HEALTH_MESSAGE="检测到安装目录存在，但 manifest.json 不是有效 JSON。"
        return 1
    fi

    version=$(jq -r '.version // empty' "$manifest_path" 2>/dev/null)
    if [[ -z "$version" ]]; then
        INSTALL_HEALTH_STATUS="broken"
        INSTALL_HEALTH_MESSAGE="检测到安装目录存在，但 manifest.json 缺少 version 字段。"
        return 1
    fi

    INSTALL_HEALTH_STATUS="ok"
    INSTALL_HEALTH_MESSAGE="已安装: ${SKILL_NAME} v${version}"
    INSTALL_HEALTH_VERSION="$version"
    return 0
}

# Check if skill already exists
check_existing() {
    if [[ -d "$INSTALL_DIR" ]]; then
        warn "发现已存在的 ${SKILL_NAME} skill"

        if assess_installed_skill; then
            log "现有版本: v${INSTALL_HEALTH_VERSION}"
        else
            warn "${INSTALL_HEALTH_MESSAGE}"
            warn "将备份当前目录并执行一次完整重装"
        fi

        if [[ "$FORCE_INSTALL" == "true" ]]; then
            log "检测到 --force，跳过交互确认"
        elif [[ ! -t 0 ]]; then
            error "检测到非交互终端且 ${SKILL_NAME} 已存在。请重新运行: $0 install --force"
        else
            read -r -p "是否要覆盖安装? (y/n): " -n 1
            echo

            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "安装已取消"
                exit 0
            fi
        fi

        log "备份现有安装..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Install the skill
install_skill() {
    log "安装 ${SKILL_NAME} v${SKILL_VERSION}..."

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
        "interview.md"
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
    if [[ "$INSTALLED_VERSION" != "$SKILL_VERSION" ]]; then
        warn "版本不匹配: 期望 ${SKILL_VERSION}, 实际 ${INSTALLED_VERSION}"
    fi

    success "安装验证通过"
}

# Update Claude Code settings
update_claude_settings() {
    log "更新 Claude Code 配置..."

    mkdir -p "$(dirname "$SETTINGS_FILE")"

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
    if ! jq \
        --arg skill_name "$SKILL_NAME" \
        --arg skill_path "${INSTALL_DIR}/SKILL.md" \
        '.skills = (.skills // {}) | .skills[$skill_name] = $skill_path' \
        "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"; then
        rm -f "${SETTINGS_FILE}.tmp"
        error "写入 Claude Code 配置失败: ${SETTINGS_FILE}"
    fi
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

    success "Claude Code 配置已更新"
}

remove_skill_from_settings() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        log "未找到 Claude Code 配置，跳过清理"
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        warn "jq 未安装，无法从 ${SETTINGS_FILE} 清理 skill 注册"
        return 0
    fi

    if ! jq -e '.' "$SETTINGS_FILE" >/dev/null 2>&1; then
        warn "Claude Code 配置不是有效 JSON，跳过 skill 注册清理"
        return 0
    fi

    if ! jq -e --arg skill_name "$SKILL_NAME" '.skills[$skill_name]' "$SETTINGS_FILE" >/dev/null 2>&1; then
        log "Claude Code 配置中未发现 ${SKILL_NAME} 注册"
        return 0
    fi

    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"
    jq \
        --arg skill_name "$SKILL_NAME" \
        'if (.skills | type) == "object" then del(.skills[$skill_name]) else . end' \
        "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

    success "Claude Code 配置中的 ${SKILL_NAME} 注册已移除"
}

# Create example workflow
create_example() {
    log "创建示例工作流..."

    EXAMPLE_DIR="${INSTALL_DIR}/examples"
    mkdir -p "$EXAMPLE_DIR"

    cat > "${EXAMPLE_DIR}/workflow-demo.sh" <<EOF
#!/bin/bash
#
# AI Office Landing - 示例工作流
#

echo "🚀 AI Office Landing v${SKILL_SHORT_VERSION} - 示例工作流"
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
echo "✨ 当前工作流特性:"
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
    echo -e "${GREEN}║            AI Office Landing v${SKILL_VERSION} 安装成功！           ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║  📁 安装路径: ${INSTALL_DIR}                               ║${NC}"
    echo -e "${GREEN}║  📖 文档:    README.md                                     ║${NC}"
    echo -e "${GREEN}║  🎯 快速开始: /landing                                     ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  当前工作流特性:                                          ║${NC}"
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

print_cli_help() {
    echo "用法: $0 [install|uninstall|reinstall|check] [--force]"
    echo ""
    echo "命令:"
    echo "  install     - 安装技能 (默认)"
    echo "  uninstall   - 卸载技能并清理 Claude Code 注册"
    echo "  reinstall   - 重新安装"
    echo "  check       - 检查是否已健康安装（未安装或损坏时返回非零）"
    echo ""
    echo "选项:"
    echo "  --force, --yes, -y  - 已存在安装时跳过交互确认并覆盖安装"
    echo "  --help, -h          - 显示此帮助"
}

parse_args() {
    if [[ $# -gt 0 && "$1" != -* ]]; then
        COMMAND="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|--yes|-y)
                FORCE_INSTALL=true
                ;;
            --help|-h)
                print_cli_help
                exit 0
                ;;
            *)
                error "未知参数: $1"
                ;;
        esac
        shift
    done
}

# Main installation
main() {
    log "AI Office Landing v${SKILL_VERSION} 安装程序"
    log "=================================="
    echo ""

    check_requirements
    echo ""
    validate_claude_settings
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

    log "享受 v${SKILL_SHORT_VERSION}！"
}

# Handle command line arguments
parse_args "$@"

case "$COMMAND" in
    install|reinstall)
        validate_install_source
        ;;
esac

case "$COMMAND" in
    install)
        main
        ;;
    uninstall)
        if [[ -d "$INSTALL_DIR" ]]; then
            log "卸载 ${SKILL_NAME}..."
        else
            warn "技能目录不存在，继续检查 Claude Code 配置"
        fi

        remove_skill_from_settings

        if [[ -d "$INSTALL_DIR" ]]; then
            rm -rf "$INSTALL_DIR"
            success "已移除安装目录"
        fi

        success "已卸载"
        ;;
    reinstall)
        FORCE_INSTALL=true
        main
        ;;
    check)
        if assess_installed_skill; then
            success "${INSTALL_HEALTH_MESSAGE}"
        else
            warn "${INSTALL_HEALTH_MESSAGE}"
            if [[ "$INSTALL_HEALTH_STATUS" == "missing" ]]; then
                echo "运行 '$0 install' 进行安装。"
            else
                echo "运行 '$0 reinstall --force' 进行修复。"
            fi
            exit 1
        fi
        ;;
    *)
        print_cli_help
        exit 1
        ;;
esac

exit 0
