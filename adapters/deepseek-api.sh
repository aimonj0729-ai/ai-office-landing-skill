#!/bin/bash
set -euo pipefail

# DeepSeek API Adapter for AI Office Skill
# 使用 DeepSeek API (OpenAI 兼容格式) 执行 Executor 任务
# 适用场景：Claude Pro 限额用完后的降级方案，尤其擅长代码生成
# 适合角色：Frontend (MEDIUM-HIGH), SEO (LOW)
#
# 用法:
#   ./adapters/deepseek-api.sh <role> <task_id> <output_path>
# 例:
#   ./adapters/deepseek-api.sh frontend task3 /project/ai-office/outputs/index.html
#
# 环境变量:
#   DEEPSEEK_API_KEY    - (必需) DeepSeek API Key
#   DEEPSEEK_BASE_URL   - (可选) 默认 https://api.deepseek.com
#   DEEPSEEK_MODEL      - (可选) 默认 deepseek-chat (也可用 deepseek-coder)

ROLE="${1:?"Error: role is required"}"
TASK_ID="${2:?"Error: task_id is required"}"
OUTPUT_PATH="${3:?"Error: output_path is required"}"

# API 配置
DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:?"Error: DEEPSEEK_API_KEY environment variable is required"}"
DEEPSEEK_BASE_URL="${DEEPSEEK_BASE_URL:-https://api.deepseek.com}"
DEEPSEEK_MODEL="${DEEPSEEK_MODEL:-deepseek-chat}"

# 角色→模型自动选择：Frontend 角色默认用 deepseek-coder
if [[ "$ROLE" == "frontend" && "$DEEPSEEK_MODEL" == "deepseek-chat" ]]; then
  DEEPSEEK_MODEL="deepseek-coder"
fi

# 常量
SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="${SKILL_ROOT}/prompts/${ROLE}.md"
TASKS_FILE="${SKILL_ROOT}/templates/tasks.md"

# Colors
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

log() { echo -e "${BLUE}[adapter/deepseek-api]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[adapter/deepseek-api] WARN:${NC} $*" >&2; }
error() { echo -e "${RED}[adapter/deepseek-api] ERROR:${NC} $*" >&2; exit 1; }

check_file() {
  local file="$1" desc="$2"
  [[ -f "$file" ]] || error "${desc} not found: ${file}"
}

# 检查依赖
command -v curl >/dev/null 2>&1 || error "curl is required but not installed"
command -v jq >/dev/null 2>&1 || error "jq is required but not installed"

# 从 tasks.md 提取当前 task 的定义
extract_task_def() {
  local task_id="$1"
  awk -v task_id="$task_id" '
    $0 ~ "^## Task [0-9]+: " {
      current_task = $0
      in_task = 0
    }
    current_task ~ task_id { in_task = 1 }
    in_task { print }
    in_task && /^---$/ { exit }
  ' "$TASKS_FILE"
}

# 项目目录
PROJECT_DIR="$(pwd)"
AI_OFFICE_DIR="${PROJECT_DIR}/ai-office"

log "Role: ${ROLE} | Model: ${DEEPSEEK_MODEL}"
log "Task ID: ${TASK_ID}"
log "Output: ${OUTPUT_PATH}"

# 检查必要文件
check_file "$PROMPT_FILE" "Role prompt"
check_file "$TASKS_FILE" "Tasks template"
check_file "$AI_OFFICE_DIR/brief.md" "Brief"
check_file "$AI_OFFICE_DIR/style-tokens.md" "Style tokens"

# 提取 task 定义
TASK_DEF=$(extract_task_def "$TASK_ID")
[[ -n "$TASK_DEF" ]] || error "Task definition not found for: $TASK_ID"

# 组装 prompt — DeepSeek 对结构化 prompt 响应更好
SYSTEM_PROMPT="You are the ${ROLE} executor for AI Office workflow. You produce production-ready output. Be precise, follow the style tokens exactly, and mark any information gaps with [GAP: description]."

USER_PROMPT=$(cat <<EOF
## Context (read-only)

### Brief
$(cat "$AI_OFFICE_DIR/brief.md")

### Style Tokens
$(cat "$AI_OFFICE_DIR/style-tokens.md")

### Your Task Definition
${TASK_DEF}

### Role Prompt
$(cat "$PROMPT_FILE")

## Instructions

1. Read the Brief and Style Tokens thoroughly
2. Understand your task definition and acceptance criteria
3. Generate the output for: ${OUTPUT_PATH}
4. Follow your role prompt for specific implementation guidance
5. IMPORTANT: If you encounter information gaps, mark them with [GAP: description]
6. Ensure all style-related values reference the Style Tokens - do NOT hardcode values
7. The output should be production-ready

## Output Requirements

- Output the complete content directly
- Do NOT include meta commentary about the generation process
- Do NOT wrap the output in markdown code blocks
- Start directly with the content

Begin generation now.
EOF
)

# 构建 JSON 请求体
REQUEST_BODY=$(jq -n \
  --arg model "$DEEPSEEK_MODEL" \
  --arg system "$SYSTEM_PROMPT" \
  --arg user "$USER_PROMPT" \
  '{
    model: $model,
    messages: [
      { role: "system", content: $system },
      { role: "user", content: $user }
    ],
    temperature: 0.7,
    max_tokens: 16384,
    stream: false
  }')

# 创建输出目录
mkdir -p "$(dirname "$OUTPUT_PATH")"

log "Calling DeepSeek API (${DEEPSEEK_MODEL})..."

# 调用 API
RESPONSE_FILE=$(mktemp)
HTTP_CODE=$(curl -s -w "%{http_code}" \
  -o "$RESPONSE_FILE" \
  -X POST "${DEEPSEEK_BASE_URL}/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${DEEPSEEK_API_KEY}" \
  -d "$REQUEST_BODY" \
  --max-time 300)

# 检查 HTTP 状态码
if [[ "$HTTP_CODE" -ne 200 ]]; then
  ERROR_MSG=$(jq -r '.error.message // .message // "Unknown error"' "$RESPONSE_FILE" 2>/dev/null || cat "$RESPONSE_FILE")
  rm -f "$RESPONSE_FILE"
  error "DeepSeek API returned HTTP ${HTTP_CODE}: ${ERROR_MSG}"
fi

# 提取内容
CONTENT=$(jq -r '.choices[0].message.content // empty' "$RESPONSE_FILE")
if [[ -z "$CONTENT" ]]; then
  rm -f "$RESPONSE_FILE"
  error "DeepSeek API returned empty content"
fi

# 提取 token 使用量
PROMPT_TOKENS=$(jq -r '.usage.prompt_tokens // 0' "$RESPONSE_FILE")
COMPLETION_TOKENS=$(jq -r '.usage.completion_tokens // 0' "$RESPONSE_FILE")
TOTAL_TOKENS=$(jq -r '.usage.total_tokens // 0' "$RESPONSE_FILE")

rm -f "$RESPONSE_FILE"

# 写入输出文件
echo "$CONTENT" > "$OUTPUT_PATH"
log "✓ Output written to ${OUTPUT_PATH}"
log "  Tokens: prompt=${PROMPT_TOKENS} completion=${COMPLETION_TOKENS} total=${TOTAL_TOKENS}"

# 记录 cost 信息
COST_DIR="${AI_OFFICE_DIR}/cost"
mkdir -p "$COST_DIR"
jq -n \
  --arg adapter "deepseek-api" \
  --arg model "$DEEPSEEK_MODEL" \
  --arg role "$ROLE" \
  --arg task_id "$TASK_ID" \
  --argjson prompt_tokens "$PROMPT_TOKENS" \
  --argjson completion_tokens "$COMPLETION_TOKENS" \
  --argjson total_tokens "$TOTAL_TOKENS" \
  --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    adapter: $adapter,
    model: $model,
    role: $role,
    task_id: $task_id,
    tokens: { prompt: $prompt_tokens, completion: $completion_tokens, total: $total_tokens },
    timestamp: $timestamp
  }' >> "${COST_DIR}/usage.jsonl"

# 标记 adapter 执行状态
echo "${ROLE}:${TASK_ID}:deepseek-api:${DEEPSEEK_MODEL}" >> "${AI_OFFICE_DIR}/.adapter-status"

log "✓ ${ROLE} task completed via DeepSeek API"
