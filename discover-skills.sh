#!/bin/bash
#
# AI Office - Skill Discovery Utility
# Dynamically discovers and loads relevant skills for Agents
#

set -e

# Auto-detect SKILL_ROOT if not set
if [[ -z "$SKILL_ROOT" ]]; then
    SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

read_manifest_field() {
    local manifest_path="$1"
    local field_name="$2"

    if [[ ! -f "$manifest_path" ]]; then
        return 0
    fi

    sed -n "s/^[[:space:]]*\"${field_name}\":[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$manifest_path" | head -n 1
}

DISCOVERY_MANIFEST="${SKILL_ROOT}/.claude-plugin/manifest.json"
DISCOVERY_VERSION="$(read_manifest_field "$DISCOVERY_MANIFEST" "version")"
DISCOVERY_VERSION="${DISCOVERY_VERSION:-unknown}"

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

#=====================================
# Core Discovery Functions
#=====================================

# Emit unique skill names whose docs mention the provided keyword.
collect_skill_matches() {
    local keyword="$1"
    local skills_root="${SKILL_ROOT}/../"
    local skill_file=""
    local skill_dir=""
    local skill_name=""

    while IFS= read -r -d '' skill_file; do
        if grep -q -i -- "$keyword" "$skill_file" 2>/dev/null; then
            skill_dir="$(dirname "$skill_file")"
            if [[ -f "$skill_dir/NAME" ]]; then
                skill_name="$(tr -d '\r\n' < "$skill_dir/NAME")"
            else
                skill_name="$(basename "$skill_dir")"
            fi
            printf '%s\n' "$skill_name"
        fi
    done < <(find "$skills_root" \( -name "SKILL.md" -o -name "README.md" \) -type f -print0 2>/dev/null) | sort -u
}

has_array_value() {
    local needle="$1"
    shift
    local item=""

    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done

    return 1
}

# Discover skills by keyword
# Usage: discover_skills "keyword" "category"
discover_skills() {
    local keyword="$1"
    local category="${2:-all}"
    local skills_root="${SKILL_ROOT}/../"
    local skill_name=""
    local unique_matches=()

    log "搜索包含 '$keyword' 的相关 skills..."

    while IFS= read -r skill_name; do
        [[ -n "$skill_name" ]] || continue
        unique_matches+=("$skill_name")
    done < <(collect_skill_matches "$keyword")

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
    local manifest_path="$skill_dir/.claude-plugin/manifest.json"
    local description="No description"
    local version="Unknown"
    local parsed_description=""
    local parsed_version=""

    parsed_description=$(read_manifest_field "$manifest_path" "description")
    parsed_version=$(read_manifest_field "$manifest_path" "version")

    if [[ -n "$parsed_description" ]]; then
        description="$parsed_description"
    fi
    if [[ -n "$parsed_version" ]]; then
        version="$parsed_version"
    fi

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
    local keyword=""
    local match=""

    for keyword in "${designer_keywords[@]}"; do
        while IFS= read -r match; do
            [[ -n "$match" ]] || continue
            [[ "$match" == "ai-office-landing" ]] && continue
            if ! has_array_value "$match" "${discovered[@]}"; then
                discovered+=("$match")
            fi
        done < <(collect_skill_matches "$keyword")
    done

    if [[ ${#discovered[@]} -eq 0 ]]; then
        log_warn "未找到适合 Designer 的外部 skills"
        write_state "designer.discovered_skills" ""
        return 0
    fi

    log_success "为 Designer 发现 ${#discovered[@]} 个候选 skills"

    # Store in state for Designer to reference
    write_state "designer.discovered_skills" "$(printf '%s,' "${discovered[@]}")"

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
    local suggestions=()
    local keyword=""
    local match=""

    log "分析任务需求: $task_desc"

    # Extract keywords from task
    local keywords=$(echo "$task_desc" | tr ' ' '\n' | grep -E "(design|code|test|deploy|build|image|color|typography|layout)" | sort -u)

    for keyword in $keywords; do
        while IFS= read -r match; do
            [[ -n "$match" ]] || continue
            if ! has_array_value "$match" "${suggestions[@]}"; then
                suggestions+=("$match")
            fi
        done < <(collect_skill_matches "$keyword")
    done

    if [[ ${#suggestions[@]} -gt 0 ]]; then
        log_success "建议的 skills:"
        for suggestion in "${suggestions[@]}"; do
            echo "  - $suggestion"
        done

        write_state "skills.suggested" "$(printf '%s,' "${suggestions[@]}")"
    else
        log_warn "未找到与任务匹配的 skills"
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

    # Initialize state only when this is the first command in a workflow.
    ensure_state_initialized

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
            echo "Skill Discovery Utility v${DISCOVERY_VERSION}"
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
