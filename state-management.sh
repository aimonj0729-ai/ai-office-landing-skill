#!/bin/bash
#
# AI Office - State Management Utilities
# 用于对话式工作流的会话状态管理
#

set -e

# Color codes for logging
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Ensure jq is available
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed. Please install jq first."
    exit 1
fi

# Read state from ai-office/state.json
# Usage: read_state "key" [default_value]
read_state() {
    local key="$1"
    local default_value="${2:-}"

    if [[ ! -f "ai-office/state.json" ]]; then
        echo "$default_value"
        return
    fi

    # Use jq to extract the value
    local value=$(jq -r ".$key // empty" ai-office/state.json 2>/dev/null)

    if [[ -z "$value" ]]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# Write state to ai-office/state.json
# Usage: write_state "key" "value" [value_type]
write_state() {
    local key="$1"
    local value="$2"
    local value_type="${3:-string}"

    # Create ai-office directory if it doesn't exist
    mkdir -p ai-office

    # Initialize state.json if it doesn't exist
    if [[ ! -f "ai-office/state.json" ]]; then
        echo '{"version": "v2"}' > ai-office/state.json
    fi

    # Read current state
    local state=$(cat ai-office/state.json 2>/dev/null || echo '{"version": "v2"}')

    # Prepare the value for jq based on type
    local jq_value=""
    case "$value_type" in
        string)
            jq_value=$(echo "$value" | jq -R -s .)
            ;;
        number)
            jq_value="$value"
            ;;
        boolean)
            jq_value="$value"
            ;;
        object|array)
            # Assume value is already valid JSON
            jq_value="$value"
            ;;
        *)
            jq_value=$(echo "$value" | jq -R -s .)
            ;;
    esac

    # Update the state using jq
    echo "$state" | jq ".$key = $jq_value" > ai-office/state.json.tmp

    if [[ $? -eq 0 ]]; then
        mv ai-office/state.json.tmp ai-office/state.json
        log_success "State updated: $key"
    else
        log_error "Failed to update state: $key"
        rm -f ai-office/state.json.tmp
        return 1
    fi
}

# Append to an array in state
# Usage: append_to_state_array "array_key" '{"new": "object"}'
append_to_state_array() {
    local array_key="$1"
    local new_item="$2"

    if [[ ! -f "ai-office/state.json" ]]; then
        log_error "state.json not found"
        return 1
    fi

    # Append to array using jq
    jq ".$array_key += [$new_item]" ai-office/state.json > ai-office/state.json.tmp

    if [[ $? -eq 0 ]]; then
        mv ai-office/state.json.tmp ai-office/state.json
        log_success "Added item to $array_key"
    else
        log_error "Failed to append to array: $array_key"
        rm -f ai-office/state.json.tmp
        return 1
    fi
}

# Update object field in state
# Usage: update_state_object "object_key" "field" "value"
update_state_object() {
    local object_key="$1"
    local field="$2"
    local value="$3"

    if [[ ! -f "ai-office/state.json" ]]; then
        log_error "state.json not found"
        return 1
    fi

    # Update object field using jq
    local escaped_value=$(echo "$value" | jq -R -s .)
    jq ".$object_key.$field = $escaped_value" ai-office/state.json > ai-office/state.json.tmp

    if [[ $? -eq 0 ]]; then
        mv ai-office/state.json.tmp ai-office/state.json
        log_success "Updated $object_key.$field"
    else
        log_error "Failed to update object field: $object_key.$field"
        rm -f ai-office/state.json.tmp
        return 1
    fi
}

# Get current phase from state
get_current_phase() {
    read_state "current_phase" "0"
}

# Get current task from state
get_current_task() {
    read_state "current_task" "0"
}

# Initialize state for new session (v2.1 with Phase 0 support)
init_state() {
    local project_name="${1:-$(basename $PWD)}"

    mkdir -p ai-office

    cat > ai-office/state.json << EOF
{
  "version": "v2.1",
  "current_phase": 0,
  "current_task": 0,
  "session_start": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "project_name": "${project_name}",
  "checkpoint": {
    "phase": 0,
    "task": 0,
    "text": "Session initialized"
  },
  "pending_questions": [],
  "user_inputs": {},
  "outputs_status": {
    "design-references": "pending",
    "brief.md": "pending",
    "style-tokens.md": "pending",
    "tasks.md": "pending",
    "copy.md": "pending",
    "design-spec.md": "pending",
    "index.html": "pending",
    "meta.md": "pending",
    "critique.md": "pending"
  }
}
EOF

    log_success "Initialized state.json for project: $project_name (v2.1 with Phase 0)"
}

# Check if there are pending questions
has_pending_questions() {
    local count=$(read_state "pending_questions" "[]" | jq 'length')
    [[ "$count" -gt 0 ]]
}

# Get pending questions count
get_pending_questions_count() {
    read_state "pending_questions" "[]" | jq 'length'
}

# Get pending questions for a specific source
get_questions_for_source() {
    local source="$1"
    read_state "pending_questions" "[]" | jq -r ".[] | select(.source == \"$source\") | .questions[]"
}

# Mark task as completed in state
mark_task_completed() {
    local task_name="$1"
    local status="${2:-completed}"

    update_state_object "outputs_status" "$task_name" "$status"
}

# Mark question as resolved
mark_question_resolved() {
    local source="$1"
    local question_index="${2:-0}"

    # This is more complex - we need to remove the question from the array
    # For now, we'll just mark the entire source's questions as resolved
    # A full implementation would handle individual questions

    # Get current pending questions
    local current_questions=$(read_state "pending_questions")

    # Filter out questions for this source
    local updated_questions=$(echo "$current_questions" | jq "map(select(.source != \"$source\"))")

    write_state "pending_questions" "$updated_questions" "array"
    log_success "Resolved questions for $source"
}

# Add a new pending question
add_pending_question() {
    local source="$1"
    local question="$2"
    local questions_file="${3:-}"

    local question_obj
    if [[ -n "$questions_file" && -f "$questions_file" ]]; then
        # Read questions from file
        local questions_content=$(cat "$questions_file" | grep "QUESTION:" | sed 's/.*QUESTION: \(.*\)/\1/' | jq -R -s -c 'split("\n") | map(select(length > 0))')
        question_obj=$(echo "{}" | jq ".source = \"$source\" | .file = \"$questions_file\" | .questions = $questions_content")
    else
        # Single question
        question_obj=$(echo "{}" | jq ".source = \"$source\" | .questions = [\"$question\"]")
    fi

    append_to_state_array "pending_questions" "$question_obj"
}

# Update checkpoint
create_checkpoint() {
    local phase="$1"
    local task="${2:-0}"
    local text="$3"

    local checkpoint=$(echo "{}" | jq ".phase = $phase | .task = $task | .text = \"$text\" | .timestamp = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"")
    write_state "checkpoint" "$checkpoint" "object"
}

# Log user interaction
log_user_interaction() {
    local phase="$1"
    local question="$2"
    local answer="$3"

    local log_file="ai-office/user-qa-log.md"

    if [[ ! -f "$log_file" ]]; then
        echo "# 用户问答日志" > "$log_file"
        echo "" >> "$log_file"
    fi

    cat >> "$log_file" << EOF
## $phase

### Q: $question
**A:** $answer

EOF

    log_success "Logged user interaction to $log_file"
}

# Clean up state (called on successful completion)
cleanup_state() {
    if [[ -f "ai-office/state.json" ]]; then
        local backup_file="ai-office/state.backup.$(date +%Y%m%d_%H%M%S).json"
        cp ai-office/state.json "$backup_file"
        rm -f ai-office/state.json
        log_success "State backed up to $backup_file and removed"
    fi
}

# Handle session resume
resume_session() {
    if [[ ! -f "ai-office/state.json" ]]; then
        log_error "No state.json found to resume"
        return 1
    fi

    local current_phase=$(get_current_phase)
    local current_task=$(get_current_task)
    local checkpoint=$(read_state "checkpoint" "{}" | jq -r '.text')

    log_success "Resuming session..."
    log "Phase: $current_phase, Task: $current_task"
    log "Checkpoint: $checkpoint"

    # Check for pending questions
    if has_pending_questions; then
        log_warning "There are $(get_pending_questions_count) pending questions"
        return 2  # Signal that questions need to be handled
    fi

    return 0
}

# Display current state summary
display_state_summary() {
    if [[ ! -f "ai-office/state.json" ]]; then
        log_warning "No state.json found"
        return
    fi

    local current_phase=$(get_current_phase)
    local current_task=$(get_current_task)
    local pending_count=$(get_pending_questions_count)

    echo ""
    echo "State Summary:"
    echo "  Phase: $current_phase"
    echo "  Task: $current_task"
    echo "  Pending Questions: $pending_count"
    echo ""

    # Show outputs status
    echo "Outputs Status:"
    read_state "outputs_status" "{}" | jq -r 'to_entries | .[] | "  \(.key): \(.value)"'
    echo ""

    # Show pending questions if any
    if [[ "$pending_count" -gt 0 ]]; then
        echo "Pending Questions:"
        read_state "pending_questions" | jq -r '.[] | "  Source: \(.source) | Questions: \(.questions | length)"'
        echo ""
    fi
}

# Check if a task is completed
task_is_completed() {
    local task_name="$1"
    local status=$(read_state "outputs_status.$task_name" "pending")
    [[ "$status" == "completed" || "$status" == "completed_confirmed" ]]
}

# Mark a task as requiring user feedback
mark_task_waiting_for_user() {
    local task_name="$1"
    update_state_object "outputs_status" "$task_name" "waiting_for_user"
}

# Get user input from state
get_user_input() {
    local key="$1"
    read_state "user_inputs.$key" ""
}

# Save user input to state
save_user_input() {
    local key="$1"
    local value="$2"
    update_state_object "user_inputs" "$key" "$value"
}
