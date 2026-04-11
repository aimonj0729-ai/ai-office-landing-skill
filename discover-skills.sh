#!/bin/bash
#
# AI Office - Skill Discovery Utility (v2.3)
# Dynamically discovers and loads relevant skills for Agents
#

set -e

# Auto-detect SKILL_ROOT if not set
if [[ -z "$SKILL_ROOT" ]]; then
    SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[SKILL-DISCOVERY]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

#=====================================
# Core Discovery Functions
#=====================================

# Discover skills by keyword
# Usage: discover_skills "keyword" "category"
discover_skills() {
    local keyword="$1"
    local category="${2:-all}"
    local skills_root="${SKILL_ROOT}/../"

    log "搜索包含 '$keyword' 的相关 skills..."

    # Find matching skills
    local matches=()
    while IFS= read -r skill_file; do
        if [[ -f "$skill_file" ]]; then
            local skill_dir=$(dirname "$skill_file")
            local skill_name=$(basename "$skill_dir")
            matches+=("$skill_name")
        fi
    done < <(find "$skills_root" -name "SKILL.md" -o -name "README.md" 2>/dev/null | xargs grep -l -i "$keyword" 2>/dev/null || true)

    # Remove duplicates
    local unique_matches=($(printf "%s\n" "${matches[@]}" | sort -u))

    if [[ ${#unique_matches[@]} -eq 0 ]]; then
        log_warn "未找到与 '$keyword' 相关的 skills"
        return 1
    fi

    log_success "发现 ${#unique_matches[@]} 个相关 skills:"
    for match in "${unique_matches[@]}"; do
        echo "  - $match"
    done

    # Store in state
    write_state "skills.discovered.${keyword// /_}" "$(printf '%s,' "${unique_matches[@]}")"

    return 0
}

# Get skill metadata
# Usage: get_skill_info "skill-name"
get_skill_info() {
    local skill_name="$1"
    local skills_root="${SKILL_ROOT}/../"
    local skill_path=$(find "$skills_root" -maxdepth 2 -name "NAME" -type f 2>/dev/null | xargs grep -l "^$skill_name$" 2>/dev/null || echo "")

    if [[ -z "$skill_path" ]]; then
        log_error "Skill '$skill_name' 不存在"
        return 1
    fi

    local skill_dir=$(dirname "$skill_path")
    local description=$(grep "^description:" "$skill_dir/.claude-plugin/manifest.json" 2>/dev/null | cut -d'"' -f4 || echo "No description")
    local version=$(grep "^version:" "$skill_dir/.claude-plugin/manifest.json" 2>/dev/null | cut -d'"' -f4 || echo "Unknown")

    echo "Skill: $skill_name"
    echo "Version: $version"
    echo "Description: $description"
    echo "Path: $skill_dir"

    # Check if it has relevant files
    if [[ -f "$skill_dir/prompts/designer.md" ]]; then
        echo "Has Designer prompt: ✓"
    fi
    if [[ -f "$skill_dir/assets/"* ]]; then
        echo "Has assets: ✓"
    fi

    return 0
}

# Load skill for Agent
# Usage: load_skill_for_agent "agent-name" "skill-name"
load_skill_for_agent() {
    local agent_name="$1"
    local skill_name="$2"
    local skills_root="${SKILL_ROOT}/../"

    log "为 $agent_name 加载 skill: $skill_name"

    # Find skill directory
    local skill_path=$(find "$skills_root" -maxdepth 2 -name "NAME" -type f 2>/dev/null | xargs grep -l "^$skill_name$" 2>/dev/null || echo "")

    if [[ -z "$skill_path" ]]; then
        log_error "Skill '$skill_name' 不存在"
        return 1
    fi

    local skill_dir=$(dirname "$skill_path")

    # Copy relevant files to agent's context
    local agent_context_dir="${SKILL_ROOT}/context/${agent_name}"
    mkdir -p "$agent_context_dir"

    # Copy prompts if they exist
    if [[ -d "$skill_dir/prompts" ]]; then
        cp -r "$skill_dir/prompts/"* "$agent_context_dir/" 2>/dev/null || true
        log_success "复制 prompts 到 agent 上下文"
    fi

    # Copy assets if they exist
    if [[ -d "$skill_dir/assets" ]]; then
        cp -r "$skill_dir/assets" "$agent_context_dir/" 2>/dev/null || true
        log_success "复制 assets 到 agent 上下文"
    fi

    # Copy templates if they exist
    if [[ -d "$skill_dir/templates" ]]; then
        cp -r "$skill_dir/templates" "$agent_context_dir/" 2>/dev/null || true
        log_success "复制 templates 到 agent 上下文"
    fi

    # Record in state
    write_state "skills.loaded.${agent_name}.${skill_name}" "true"

    log_success "Skill '$skill_name' 已加载给 $agent_name"
    return 0
}

# Auto-discover skills for Designer
auto_discover_for_designer() {
    log "为 Designer Agent 自动发现相关 skills..."

    local designer_keywords=(
        "design"
        "color"
        "typography"
        "layout"
        "visual"
        "assets"
        "image"
    )

    local discovered=()

    for keyword in "${designer_keywords[@]}"; do
                local tmp_array=()
        while IFS= read -r item; do
            tmp_array+=("$item")
        done
        matches=("${tmp_array[@]}")
         "$keyword" 2>/dev/null | grep "^-" | sed 's/^  - //' || true)
        discovered+=("${matches[@]}")
    done

    # Remove duplicates and this skill itself
    local unique_discovered=($(printf "%s\n" "${discovered[@]}" | grep -v "^ai-office-landing$" | sort -u))

    log_success "为 Designer 发现 ${#unique_discovered[@]} 个候选 skills"

    # Store in state for Designer to reference
    write_state "designer.discovered_skills" "$(printf '%s,' "${unique_discovered[@]}")"

    return 0
}

# Interactive skill selection
interactive_skill_selection() {
    local agent_name="$1"
    shift
    local available_skills=("$@")

    echo ""
    echo "为 $agent_name 选择 skill:"
    for i in "${!available_skills[@]}"; do
        echo "$((i+1))) ${available_skills[i]}"
    done
    echo "0) 跳过"
    echo ""

    read -p "选择 (0-${#available_skills[@]}): " choice

    if [[ $choice -gt 0 && $choice -le ${#available_skills[@]} ]]; then
        local selected_skill="${available_skills[$((choice-1))]}"
        load_skill_for_agent "$agent_name" "$selected_skill"
        echo "$selected_skill"
        return 0
    fi

    echo ""
    return 1
}

#=====================================
# Skill Intelligence Functions
#=====================================

# Analyze task requirements and suggest skills
# Usage: suggest_skills_for_task "task-description"
suggest_skills_for_task() {
    local task_desc="$1"
    local agent_name="${2:-all}"

    log "分析任务需求: $task_desc"

    # Extract keywords from task
    local keywords=$(echo "$task_desc" | tr ' ' '\n' | grep -E "(design|code|test|deploy|build|image|color|typography|layout)" | sort -u)

    local suggestions=()

    for keyword in $keywords; do
                local tmp_array=()
        while IFS= read -r item; do
            tmp_array+=("$item")
        done
        matches=("${tmp_array[@]}")
         "$keyword" 2>/dev/null | grep "^-" | sed 's/^  - //' || true)
        suggestions+=("${matches[@]}")
    done

    # Remove duplicates
    local unique_suggestions=($(printf "%s\n" "${suggestions[@]}" | sort -u))

    if [[ ${#unique_suggestions[@]} -gt 0 ]]; then
        log_success "建议的 skills:"
        for suggestion in "${unique_suggestions[@]}"; do
            echo "  - $suggestion"
        done

        write_state "skills.suggested" "$(printf '%s,' "${unique_suggestions[@]}")"
    fi

    return 0
}

# Cache skill registry for fast lookup
cache_skill_registry() {
    local skills_root="${SKILL_ROOT}/../"
    local cache_file="${SKILL_ROOT}/.skill-registry.cache"

    log "缓存 skill registry..."

    # Find all skills
    find "$skills_root" -maxdepth 2 -name "NAME" -type f 2>/dev/null | while read -r name_file; do
        local skill_dir=$(dirname "$name_file")
        local skill_name=$(cat "$name_file" 2>/dev/null || echo "unknown")
        local has_prompts=$([[ -d "$skill_dir/prompts" ]] && echo "yes" || echo "no")
        local has_assets=$([[ -d "$skill_dir/assets" ]] && echo "yes" || echo "no")
        local has_templates=$([[ -d "$skill_dir/templates" ]] && echo "yes" || echo "no")

        echo "$skill_name|$skill_dir|$has_prompts|$has_assets|$has_templates"
    done > "$cache_file"

    log_success "已缓存 $(wc -l < "$cache_file") 个 skills"
    return 0
}

# Load cached skill registry
load_cached_registry() {
    local cache_file="${SKILL_ROOT}/.skill-registry.cache"

    if [[ -f "$cache_file" ]]; then
        log "从缓存加载 registry"
        cat "$cache_file"
    else
        log_warn "缓存不存在，重新生成..."
        cache_skill_registry
        cat "$cache_file"
    fi

    return 0
}

#=====================================
# Entry Point
#=====================================

# Main function
run_skill_discovery() {
    local command="${1:-help}"

    # Set up environment
    source "$SKILL_ROOT/state-management.sh"

    # Initialize if needed
    init_state

    case "$command" in
        discover)
            shift
            discover_skills "$@"
            ;;
        info)
            shift
            get_skill_info "$@"
            ;;
        load)
            shift
            load_skill_for_agent "$@"
            ;;
        auto-designer)
            auto_discover_for_designer
            ;;
        suggest)
            shift
            suggest_skills_for_task "$@"
            ;;
        cache)
            cache_skill_registry
            ;;
        help|*)
            echo "Skill Discovery Utility v2.3"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  discover <keyword> [category]  - 搜索相关 skills"
            echo "  info <skill-name>              - 获取 skill 详细信息"
            echo "  load <agent> <skill-name>      - 为 Agent 加载 skill"
            echo "  auto-designer                  - 为 Designer 自动发现 skills"
            echo "  suggest <task-desc> [agent]    - 建议相关 skills"
            echo "  cache                          - 缓存 skill registry"
            echo "  help                           - 显示帮助信息"
            echo ""
            ;;
    esac

    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_skill_discovery "$@"
fi