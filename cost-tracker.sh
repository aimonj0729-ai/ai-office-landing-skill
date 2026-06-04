#!/bin/bash
#
# AI Office - Cost Tracker (v2.2)
# Real-time token usage tracking and budget management
#

set -e

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Claude Pro daily limit
DEFAULT_CLAUDE_PRO_LIMIT=45000
CLAUDE_PRO_LIMIT=${CLAUDE_PRO_LIMIT:-$DEFAULT_CLAUDE_PRO_LIMIT}

# Cost database paths
COST_DB_PATH="ai-office/cost/session-cost.json"
COST_HISTORY_FILE="${HOME}/.claude/cost-history.json"

# Logging with color
log_cost() {
    echo -e "${BLUE}[COST]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

normalize_claude_pro_limit() {
    local value="$1"

    if [[ "$value" =~ ^[0-9]+$ ]]; then
        if ((10#$value > 0)); then
            printf '%s\n' "$((10#$value))"
            return 0
        fi
    fi

    printf "%b[WARN]%b CLAUDE_PRO_LIMIT 必须是正整数，已使用默认值 %s。\n" \
        "$YELLOW" "$NC" "$DEFAULT_CLAUDE_PRO_LIMIT" >&2
    printf '%s\n' "$DEFAULT_CLAUDE_PRO_LIMIT"
}

CLAUDE_PRO_LIMIT="$(normalize_claude_pro_limit "$CLAUDE_PRO_LIMIT")"

# Format token counts for display; fall back to raw numbers on macOS systems
# where GNU coreutils' numfmt is not installed.
format_tokens() {
    local value="${1:-0}"

    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec "$value"
    else
        printf "%s" "$value"
    fi
}

# Get the estimated token cost for a workflow phase.
get_phase_cost() {
    case "$1" in
        0) echo 15000 ;;  # Design Researcher
        1) echo 13000 ;;  # Interview
        2) echo 8000 ;;   # Style Tokens & Tasks
        3) echo 80000 ;;  # Executors (4x20k)
        4) echo 20000 ;;  # Critic
        5) echo 5000 ;;   # Integration
        *) echo 0 ;;
    esac
}

build_cost_path_json() {
    local key="$1"
    local path_json='[]'
    local segment=""
    local IFS='.'
    local -a segments=()

    read -r -a segments <<< "$key"
    if [[ ${#segments[@]} -eq 0 ]]; then
        return 1
    fi

    for segment in "${segments[@]}"; do
        if [[ -z "$segment" ]]; then
            return 1
        fi

        if ! path_json=$(jq -c --arg segment "$segment" '. + [$segment]' <<< "$path_json"); then
            return 1
        fi
    done

    printf '%s\n' "$path_json"
}

# Read a value from the cost database.
read_cost_db() {
    local key="$1"
    local default_value="${2:-}"
    local path_json=""
    local value=""

    if [[ ! -f "$COST_DB_PATH" ]]; then
        echo "$default_value"
        return
    fi

    if ! path_json=$(build_cost_path_json "$key"); then
        echo "$default_value"
        return
    fi

    if ! value=$(jq -r \
        --argjson path "$path_json" \
        'getpath($path) as $value
        | if $value == null then empty
          elif ($value | type) == "string" then $value
          else ($value | tojson)
          end' \
        "$COST_DB_PATH" 2>/dev/null); then
        value=""
    fi

    if [[ -z "$value" ]]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# Calculate an integer usage percentage.
calculate_usage_percentage() {
    local used="${1:-0}"

    if [[ "$CLAUDE_PRO_LIMIT" -le 0 ]]; then
        echo 0
        return
    fi

    echo $((used * 100 / CLAUDE_PRO_LIMIT))
}

# Keep the cached summary fields aligned with the current daily total.
sync_current_usage() {
    local used="${1:-0}"
    local remaining=$((CLAUDE_PRO_LIMIT - used))
    local percentage

    if [[ "$remaining" -lt 0 ]]; then
        remaining=0
    fi

    percentage=$(calculate_usage_percentage "$used")

    update_cost_db "current_session.tokens_used" "$used"
    update_cost_db "current_session.tokens_remaining" "$remaining"
    update_cost_db "current_session.percentage_used" "$percentage"
    update_cost_db "daily_usage.claude" "$used"
}

#=====================================
# Core Functions
#=====================================

# Initialize cost tracking
init_cost_tracking() {
    mkdir -p ai-office/cost

    # Create cost log if it doesn't exist
    if [[ ! -f "$COST_DB_PATH" ]]; then
        cat > "$COST_DB_PATH" << EOF
{
  "session_id": "$(date +%Y%m%d_%H%M%S)",
  "start_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_token_limit": $CLAUDE_PRO_LIMIT,
  "daily_usage": {"claude": 0, "kimi": 0, "deepseek": 0},
  "current_session": {
    "phase": 0,
    "tokens_used": 0,
    "tokens_remaining": $CLAUDE_PRO_LIMIT,
    "percentage_used": 0
  },
  "phase_breakdown": {}
}
EOF
    fi

    # Seed the session counters from the last saved daily total if present.
    local today
    local restored_usage=0
    local existing_usage

    today=$(date +%Y-%m-%d)
    existing_usage=$(read_cost_db "current_session.tokens_used" "0")

    if [[ -f "$COST_HISTORY_FILE" ]]; then
        restored_usage=$(jq -r --arg today "$today" '.[$today].claude // 0' "$COST_HISTORY_FILE" 2>/dev/null || echo 0)
    fi

    if [[ "$existing_usage" -gt "$restored_usage" ]]; then
        restored_usage="$existing_usage"
    fi

    sync_current_usage "$restored_usage"

    if [[ "$restored_usage" -gt 0 ]]; then
        log_cost "已恢复今日累计用量: $(format_tokens "$restored_usage") tokens"
    fi

    log_cost "初始化成本追踪 - 日限额: $(format_tokens "$CLAUDE_PRO_LIMIT") tokens"
}

# Update cost database
update_cost_db() {
    local key="$1"
    local value="$2"
    local path_json=""

    if [[ ! -f "$COST_DB_PATH" ]]; then
        init_cost_tracking
    fi

    if ! path_json=$(build_cost_path_json "$key"); then
        log_error "Invalid cost db path: $key"
        return 1
    fi

    if jq \
        --argjson path "$path_json" \
        --argjson value "$value" \
        'setpath($path; $value)' \
        "$COST_DB_PATH" > "${COST_DB_PATH}.tmp"; then
        mv "${COST_DB_PATH}.tmp" "$COST_DB_PATH"
    else
        log_error "Failed to update cost db: $key"
        rm -f "${COST_DB_PATH}.tmp"
        return 1
    fi
}

# Get current usage
get_current_usage() {
    read_cost_db "current_session.tokens_used" "0"
}

# Get remaining tokens
get_remaining_tokens() {
    local used=$(get_current_usage)
    local remaining=$((CLAUDE_PRO_LIMIT - used))

    if [[ "$remaining" -lt 0 ]]; then
        remaining=0
    fi

    echo "$remaining"
}

# Calculate percentage used
get_usage_percentage() {
    local used=$(get_current_usage)
    calculate_usage_percentage "$used"
}

#=====================================
# Progress Visualization
#=====================================

# Generate progress bar
generate_progress_bar() {
    local percentage="$1"
    local width=40
    local filled
    local empty

    if [[ "$percentage" -lt 0 ]]; then
        percentage=0
    elif [[ "$percentage" -gt 100 ]]; then
        percentage=100
    fi

    filled=$((percentage * width / 100))
    empty=$((width - filled))

    local bar=""
    if [[ $percentage -le 60 ]]; then
        bar="${GREEN}"
    elif [[ $percentage -le 80 ]]; then
        bar="${YELLOW}"
    else
        bar="${RED}"
    fi

    # Build bar
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    bar+="${NC}"

    echo "$bar"
}

# Display cost header
display_cost_header() {
    local used=$(get_current_usage)
    local remaining=$(get_remaining_tokens)
    local percentage=$(get_usage_percentage)
    local bar=$(generate_progress_bar $percentage)

    echo ""
    echo -e "╔════════════════════════════════════════════════════════════╗"
    echo -e "║  AI Office 成本追踪 · 日限额: $(format_tokens "$CLAUDE_PRO_LIMIT") tokens  ║"
    echo -e "╠════════════════════════════════════════════════════════════╣"
    echo -e "║  已用: $(format_tokens "$used") tokens  ${bar}  ${percentage}%  ║"
    echo -e "║  剩余: $(format_tokens "$remaining") tokens                              ║"
    echo -e "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

#=====================================
# Phase Cost Estimation
#=====================================

# Estimate cost before phase
estimate_phase_cost() {
    local phase="$1"
    local cost
    local current_usage
    local projected_total
    local percentage

    cost=$(get_phase_cost "$phase")
    current_usage=$(get_current_usage)
    projected_total=$((current_usage + cost))
    percentage=$(calculate_usage_percentage "$projected_total")

    log_cost "预估 Phase $phase 消耗: $(format_tokens "$cost") tokens"
    log_cost "预计总消耗: $(format_tokens "$projected_total") / $(format_tokens "$CLAUDE_PRO_LIMIT") ($percentage%)"

    # Risk assessment
    if [[ $projected_total -gt $CLAUDE_PRO_LIMIT ]]; then
        echo ""
        log_error "⚠️  警告: 预计会超出限额 $(format_tokens "$((projected_total - CLAUDE_PRO_LIMIT))") tokens"
        echo ""
        suggest_cost_saving_measures $phase
        return 1
    elif [[ $percentage -gt 80 ]]; then
        echo ""
        log_warn "⚠️  注意: 预计使用 $percentage% 的日限额"
        log_warn "建议: 启用成本节省模式"
        echo ""
        suggest_cost_saving_measures $phase
    fi

    return 0
}

# Suggest cost saving measures
suggest_cost_saving_measures() {
    local phase="$1"

    echo -e "${PURPLE}成本节省建议:${NC}"

    case $phase in
        0)
            echo "  1) 跳过 Phase 0: /landing --skip-phase-0"
            echo "  2) 使用已有设计参考，不重新搜索"
            ;;
        1)
            echo "  1) 提供简洁的回答（减少访谈轮次）"
            echo "  2) 跳过可选问题"
            ;;
        2)
            echo "  1) 使用简化的 Style Tokens"
            echo "  2) 跳过非核心的情绪词转译"
            ;;
        3)
            echo "  1) 串行模式: /landing --serial (分摊到多天)"
            echo "  2) 使用 Kimi/DeepSeek: /landing --model=mixed"
            echo "  3) 减少 Executor 数量（只做 copy + frontend）"
            echo "  4) 人工审查: /landing --human-critic"
            ;;
        4)
            echo "  1) 人工 Critic: /landing --human-critic"
            echo "  2) 简化审查清单（只检查关键项）"
            ;;
    esac
    echo ""
}

# Update actual usage after phase
record_actual_cost() {
    local phase="$1"
    local actual_cost="$2"
    local phase_name="${3:-phase_$phase}"
    local percentage_of_total

    # Update current session
    local current_usage=$(get_current_usage)
    local new_usage=$((current_usage + actual_cost))
    percentage_of_total=$(calculate_usage_percentage "$actual_cost")

    sync_current_usage "$new_usage"
    update_cost_db "current_session.phase" "$phase"

    # Update phase breakdown
    update_cost_db "phase_breakdown.$phase_name" "{
        \"phase\": $phase,
        \"tokens\": $actual_cost,
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"percentage_of_total\": $percentage_of_total
    }"

    # Log the update
    log_cost "Phase $phase 实际消耗: $(format_tokens "$actual_cost") tokens"
    display_cost_summary
}

#=====================================
# Interactive Warnings
#=====================================

# Prompt user for action when approaching limit
prompt_for_cost_action() {
    local phase="$1"

    echo ""
    log_warn "日限额即将用完，请选择:"
    echo ""
    echo "1) 继续执行 (可能中途超限)"
    echo "2) 切换到成本节省模式"
    echo "3) 保存当前状态，明天继续 (--resume)"
    echo "4) 放弃本次会话"
    echo ""

    while true; do
        read -p "你的选择 (1-4): " CHOICE
        case $CHOICE in
            1)
                log_cost "继续执行..."
                return 0
                ;;
            2)
                log_cost "启用成本节省模式"
                export COST_SAVING_MODE="true"
                return 0
                ;;
            3)
                log_success "状态已保存，明天用 /landing --resume 继续"
                exit 0
                ;;
            4)
                log_cost "放弃本次会话"
                exit 1
                ;;
            *)
                log_error "无效选择，请重试"
                ;;
        esac
    done
}

#=====================================
# Summary and Reporting
#=====================================

# Display cost summary
display_cost_summary() {
    local used=$(get_current_usage)
    local remaining=$(get_remaining_tokens)
    local percentage=$(get_usage_percentage)
    local bar=$(generate_progress_bar $percentage)

    echo ""
    echo -e "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃  成本摘要                                                  ┃"
    echo -e "┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫"
    echo -e "┃  已用: $(format_tokens "$used") tokens  ${bar}  ${percentage}%  ┃"
    echo -e "┃  剩余: $(format_tokens "$remaining") tokens                          ┃"
    echo -e "┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫"
    echo -e "┃  如需节省成本，下次可尝试:                                 ┃"
    echo -e "┃  • /landing --serial (串行执行)                           ┃"
    echo -e "┃  • /landing --human-critic (人工审查)                     ┃"
    echo -e "┃  • 简化需求描述，减少 Executor 数量                        ┃"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo ""

    # Save daily summary
    save_daily_summary
}

# Save daily summary to history
save_daily_summary() {
    local today=$(date +%Y-%m-%d)
    local summary_file="$COST_HISTORY_FILE"

    # Ensure directory exists
    mkdir -p "$(dirname "$summary_file")"

    # Initialize if doesn't exist
    if [[ ! -f "$summary_file" ]]; then
        echo "{}" > "$summary_file"
    fi

    # Update today's entry
    local used=$(get_current_usage)
    local current_data=$(cat "$summary_file")

    if echo "$current_data" | jq --arg today "$today" --arg last_updated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson used "$used" '
        .[$today] = {
            "claude": $used,
            "sessions": ((.[$today].sessions // 0) + 1),
            "last_updated": $last_updated
        }
    ' > "$summary_file.tmp"; then
        mv "$summary_file.tmp" "$summary_file"
    else
        log_warn "无法更新成本历史，已跳过: $summary_file"
        rm -f "$summary_file.tmp"
    fi
}

# Display daily history
display_daily_history() {
    local summary_file="$COST_HISTORY_FILE"

    if [[ ! -f "$summary_file" ]]; then
        log_cost "无历史记录"
        return
    fi

    echo ""
    echo "📊 最近 7 天成本统计:"
    echo ""

    # Show last 7 days
    for i in {0..6}; do
        local date=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null || date -v-"$i"d +%Y-%m-%d)
        local usage
        local sessions
        local usage_percentage

        usage=$(jq -r --arg day "$date" '.[$day].claude // 0' "$summary_file" 2>/dev/null || echo 0)
        sessions=$(jq -r --arg day "$date" '.[$day].sessions // 0' "$summary_file" 2>/dev/null || echo 0)

        if [[ $usage -gt 0 ]]; then
            usage_percentage=$(calculate_usage_percentage "$usage")
            local bar=$(generate_progress_bar "$usage_percentage")
            printf "  %s: %s tokens %s %d%% (%d 会话)\n" \
                "$date" \
                "$(format_tokens "$usage")" \
                "$bar" \
                "$usage_percentage" \
                "$sessions"
        else
            printf "  %s: 无数据\n" "$date"
        fi
    done

    echo ""
}

#=====================================
# Cost Saving Mode
#=====================================

# Apply cost saving measures for a phase
apply_cost_saving_mode() {
    local phase="$1"
    local remaining=$(get_remaining_tokens)

    log_cost "启用成本节省模式（剩余: $(format_tokens "$remaining")）"

    case $phase in
        0)
            log_cost "跳过 Phase 0"
            export SKIP_PHASE_0="true"
            ;;
        1)
            log_cost "减少访谈问题数量"
            export REDUCED_INTERVIEW="true"
            ;;
        2)
            log_cost "使用简化的 Style Tokens"
            export MINIMAL_TOKENS="true"
            ;;
        3)
            # Most expensive phase
            log_cost "串行执行 Executor"
            export SERIAL_MODE="true"

            if [[ $remaining -lt 60000 ]]; then
                log_cost "只执行核心 Agent (Copy + Frontend)"
                export CORE_ONLY="true"
            fi
            ;;
        4)
            log_cost "启用人工 Critic 审查"
            export HUMAN_CRITIC="true"
            ;;
    esac

    return 0
}

#=====================================
# Phase Cost Tracking
#=====================================

# Log phase completion with cost
log_phase_completion() {
    local phase="$1"
    local cost="$2"
    local phase_name="${3:-phase_$phase}"

    update_cost_db "completed_phases.$phase_name" "{
        \"phase\": $phase,
        \"cost\": $cost,
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
    }"

    log_success "Phase $phase 完成 ✓ 消耗: $(format_tokens "$cost") tokens"
}

# Check if we should warn about cost
should_warn_about_cost() {
    local phase="$1"
    local cost
    local current_usage
    local projected_total
    local percentage

    cost=$(get_phase_cost "$phase")
    current_usage=$(get_current_usage)
    projected_total=$((current_usage + cost))
    percentage=$(calculate_usage_percentage "$projected_total")

    # Warn if projected total exceeds 80%
    if [[ "$percentage" -gt 80 ]]; then
        return 0
    fi

    return 1
}
