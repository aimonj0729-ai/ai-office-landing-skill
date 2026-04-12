#!/bin/bash
set -euo pipefail

# Adapter Router for AI Office Skill
# 根据角色质量等级、可用 API key、成本模式自动选择最优 adapter
#
# 用法:
#   ./adapters/route.sh <role> <task_id> <output_path>
#
# 环境变量:
#   AI_OFFICE_ADAPTER   - (可选) 强制指定 adapter: claude-agent | kimi-api | deepseek-api
#   COST_SAVING_MODE    - (可选) true 时优先用便宜的 adapter
#   KIMI_API_KEY        - (可选) 有此 key 才能用 kimi-api adapter
#   DEEPSEEK_API_KEY    - (可选) 有此 key 才能用 deepseek-api adapter
#
# 角色质量等级 (来自项目设计文档):
#   HIGH (不可降级):      interviewer, brief-keeper, critic, integrator → claude-agent only
#   MEDIUM-HIGH:          frontend → deepseek-coder 可接受
#   MEDIUM:               copywriter, designer → kimi 可接受
#   LOW:                  seo → kimi 或 deepseek 都行

ROLE="${1:?"Error: role is required"}"
TASK_ID="${2:?"Error: task_id is required"}"
OUTPUT_PATH="${3:?"Error: output_path is required"}"

ADAPTERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
if [[ -t 1 ]]; then
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  YELLOW='' BLUE='' GREEN='' RED='' NC=''
fi

log() { echo -e "${BLUE}[adapter/router]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[adapter/router] WARN:${NC} $*" >&2; }

# 角色 → 质量等级映射
get_quality_tier() {
  case "$1" in
    interviewer|brief-keeper|critic|integrator)
      echo "HIGH" ;;
    frontend)
      echo "MEDIUM_HIGH" ;;
    copywriter|designer)
      echo "MEDIUM" ;;
    seo)
      echo "LOW" ;;
    *)
      echo "MEDIUM" ;;
  esac
}

# 检查 adapter 是否可用
is_available() {
  case "$1" in
    claude-agent)
      return 0 ;;  # Claude Agent 工具始终可用 (在 Claude Code 环境中)
    kimi-api)
      [[ -n "${KIMI_API_KEY:-}" ]] && return 0 || return 1 ;;
    deepseek-api)
      [[ -n "${DEEPSEEK_API_KEY:-}" ]] && return 0 || return 1 ;;
    *)
      return 1 ;;
  esac
}

# 选择 adapter
select_adapter() {
  local role="$1"
  local tier
  tier=$(get_quality_tier "$role")

  # 1. 用户强制指定
  if [[ -n "${AI_OFFICE_ADAPTER:-}" ]]; then
    if is_available "$AI_OFFICE_ADAPTER"; then
      # HIGH 角色不允许降级，即使用户强制指定
      if [[ "$tier" == "HIGH" && "$AI_OFFICE_ADAPTER" != "claude-agent" ]]; then
        warn "Role '${role}' is HIGH tier — ignoring AI_OFFICE_ADAPTER=${AI_OFFICE_ADAPTER}, using claude-agent"
        echo "claude-agent"
        return
      fi
      echo "$AI_OFFICE_ADAPTER"
      return
    else
      warn "Forced adapter '${AI_OFFICE_ADAPTER}' is not available, falling back to auto-routing"
    fi
  fi

  # 2. HIGH 角色 — 只用 claude-agent
  if [[ "$tier" == "HIGH" ]]; then
    echo "claude-agent"
    return
  fi

  # 3. 成本节省模式 — 尽可能用便宜的
  if [[ "${COST_SAVING_MODE:-}" == "true" ]]; then
    case "$tier" in
      MEDIUM_HIGH)
        # Frontend 优先 DeepSeek Coder
        if is_available "deepseek-api"; then echo "deepseek-api"; return; fi
        if is_available "kimi-api"; then echo "kimi-api"; return; fi
        ;;
      MEDIUM|LOW)
        # Copywriter/Designer/SEO 优先 Kimi
        if is_available "kimi-api"; then echo "kimi-api"; return; fi
        if is_available "deepseek-api"; then echo "deepseek-api"; return; fi
        ;;
    esac
  fi

  # 4. 默认 — claude-agent
  echo "claude-agent"
}

# 执行路由
ADAPTER=$(select_adapter "$ROLE")
TIER=$(get_quality_tier "$ROLE")

log "Role: ${ROLE} (${TIER}) → Adapter: ${ADAPTER}"

if [[ "${COST_SAVING_MODE:-}" == "true" ]]; then
  log "Cost saving mode: ON"
fi

# 调用选中的 adapter
exec "${ADAPTERS_DIR}/${ADAPTER}.sh" "$ROLE" "$TASK_ID" "$OUTPUT_PATH"
