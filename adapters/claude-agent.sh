#!/bin/bash
set -euo pipefail

# Claude Agent Adapter for AI Office Skill
# 这是 v1 唯一的 adapter，封装 Claude Code 的 Agent 工具调用
# 职责：读文件 → 组装 prompt → 调 Agent → 写产物

# 用法:
#   ./adapters/claude-agent.sh <role> <task_id> <output_path>
# 例:
#   ./adapters/claude-agent.sh copywriter task1 /project/ai-office/outputs/copy.md

ROLE="${1:?"Error: role is required"}"
TASK_ID="${2:?"Error: task_id is required"}"
OUTPUT_PATH="${3:?"Error: output_path is required"}"

# 常量
SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="${SKILL_ROOT}/prompts/${ROLE}.md"
TASKS_FILE="${SKILL_ROOT}/templates/tasks.md"

# Colors for logging (only when running in terminal)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

log() {
  echo -e "${BLUE}[adapter/claude-agent]${NC} $*" >&2
}

error() {
  echo -e "${RED}[adapter/claude-agent] ERROR:${NC} $*" >&2
  exit 1
}

# 检查输入文件是否存在
check_file() {
  local file="$1"
  local desc="$2"
  if [[ ! -f "$file" ]]; then
    error "${desc} not found: ${file}"
  fi
}

# 从 tasks.md 提取当前 task 的定义
extract_task_def() {
  local task_id="$1"
  # 用 awk 提取 task 块
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

# 读取项目目录(相对于当前工作目录)
PROJECT_DIR="$(pwd)"
AI_OFFICE_DIR="${PROJECT_DIR}/ai-office"

log "Role: ${ROLE}"
log "Task ID: ${TASK_ID}"
log "Output: ${OUTPUT_PATH}"
log "Project dir: ${PROJECT_DIR}"

# 检查必要文件
check_file "$PROMPT_FILE" "Role prompt"
check_file "$TASKS_FILE" "Tasks template"
check_file "$AI_OFFICE_DIR/brief.md" "Brief"
check_file "$AI_OFFICE_DIR/style-tokens.md" "Style tokens"

# 提取 task 定义
TASK_DEF=$(extract_task_def "$TASK_ID")
if [[ -z "$TASK_DEF" ]]; then
  error "Task definition not found for: $TASK_ID"
fi

# 读取依赖文件
DEPENDS_ON=$(echo "$TASK_DEF" | grep -A10 "^### Acceptance Criteria" | grep "depends_on" | cut -d':' -f2- | tr -d ' ')

# 组装 prompt
PROMPT=$(cat <<EOF
You are the ${ROLE} executor for AI Office workflow.

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
3. Generate the output file at: ${OUTPUT_PATH}
4. Follow your role prompt for specific implementation guidance
5. IMPORTANT: If you encounter information gaps (things not defined in Brief), mark them with [GAP: description] rather than inventing information
6. Ensure all style-related values (colors, spacing, fonts) reference the Style Tokens - do NOT hardcode values
7. The output should be production-ready and follow best practices for your domain

## Output Requirements

- Write the complete content to the specified output path
- The output must be standalone and complete
- Do NOT include any meta commentary about the generation process
- Do NOT wrap the output in markdown code blocks
- Start directly with the content

Begin generation now.
EOF
)

# 显示成本预警（从 task 定义里读 adapter）
ADAPTER=$(echo "$TASK_DEF" | grep "adapter" | head -1 | cut -d':' -f2- | tr -d ' ' | xargs)
log "Adapter mode: ${ADAPTER:-claude-agent}"

# 创建输出目录
mkdir -p "$(dirname "$OUTPUT_PATH")"

# 调用 Agent 工具（这里用 echo 模拟，实际由 SKILL.md 里的 Agent 调用）
# 注意：这个脚本本身不直接调 Agent，而是被 SKILL.md 调用
# 我们生成一个临时的 prompt 文件，供 SKILL.md 里的 Agent 工具读取
PROMPT_TMP=$(mktemp)
echo "$PROMPT" > "$PROMPT_TMP"

log "Prompt assembled: ${PROMPT_TMP}"
log "Ready to call Agent tool with role=${ROLE}"

# 实际的 Agent 调用由 SKILL.md 完成，这里只准备上下文
# SKILL.md 会执行类似：
# Agent({
#   description: "Execute ${ROLE} task",
#   prompt: $(cat "${PROMPT_TMP}"),
#   output_path: "${OUTPUT_PATH}"
# })

# 标记这个 adapter 的执行状态
echo "${ROLE}:${TASK_ID}" >> "${AI_OFFICE_DIR}/.adapter-status"

# 返回 prompt 文件路径，供调用方使用
echo "$PROMPT_TMP"
