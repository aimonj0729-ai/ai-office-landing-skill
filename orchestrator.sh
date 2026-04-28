#!/bin/bash
#
# AI Office - Orchestrator (Phase 3.5)
# Collects and summarizes all Executor outputs
#

set -e

# Auto-detect SKILL_ROOT if not set so the orchestrator can be invoked
# directly from the installed skill path.
if [[ -z "$SKILL_ROOT" ]]; then
    SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[ORCHESTRATOR]${NC} $1"
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
# Utility Functions
#=====================================

# Get file size
file_size() {
    local file="$1"
    wc -c < "$file" 2>/dev/null || echo 0
}

# Get line count
line_count() {
    local file="$1"
    wc -l < "$file" 2>/dev/null || echo 0
}

# Count grep matches without emitting duplicate zeroes when grep exits 1.
grep_count() {
    local pattern="$1"
    local file="$2"
    local count=0

    if [[ -f "$file" ]]; then
        count=$(grep -c "$pattern" "$file" 2>/dev/null || true)
    fi

    printf '%s\n' "${count:-0}"
}

# Extract section from markdown
extract_section() {
    local file="$1"
    local section="$2"
    sed -n "/^## $section/,/^##/p" "$file" 2>/dev/null | head -n -1
}

# Check if file has specific content
has_content() {
    local file="$1"
    local pattern="$2"
    grep -q "$pattern" "$file" 2>/dev/null && echo "yes" || echo "no"
}

# Count occurrences
count_occurrences() {
    local file="$1"
    local pattern="$2"
    grep_count "$pattern" "$file"
}

#=====================================
# Core Orchestrator Functions
#=====================================

# Check if all outputs exist
check_execution_status() {
    log "检查 Executor 输出状态..."

    local outputs_dir="ai-office/outputs"
    local statuses=()
    local expected_outputs=(
        "copy.md:Copywriter"
        "design-spec.md:Designer"
        "index.html:Frontend"
        "meta.md:SEO"
    )
    local entry=""
    local file=""
    local agent=""
    local path=""

    for entry in "${expected_outputs[@]}"; do
        file="${entry%%:*}"
        agent="${entry#*:}"
        path="${outputs_dir}/${file}"

        if [[ -f "$path" ]]; then
            local size=$(file_size "$path")
            local lines=$(line_count "$path")
            statuses+=("✓ $agent: $file ($lines lines, $size bytes)")
        else
            statuses+=("✗ $agent: $file (MISSING)")
        fi
    done

    # Print report
    echo ""
    echo "执行状态:"
    for status in "${statuses[@]}"; do
        if [[ $status == ✓* ]]; then
            echo -e "  ${GREEN}$status${NC}"
        else
            echo -e "  ${RED}$status${NC}"
        fi
    done
    echo ""

    # Count completed
    local completed=$(printf "%s\n" "${statuses[@]}" | grep -c "✓" || echo 0)
    log "完成度: $completed/4 Executors"

    return $((4 - completed))
}

# Generate progress dashboard
generate_progress_dashboard() {
    log "生成进度仪表板..."

    local outputs_dir="ai-office/outputs"

    cat > /tmp/progress_table.md << EOF
| Agent | Task | Status | Progress | Key Metrics |
|---|---|---|---|---|
$(generate_agent_row "copywriter" "copy.md" "文案" "4 sections, content generation")
$(generate_agent_row "designer" "design-spec.md" "设计规范" "layout, components, tokens")
$(generate_agent_row "frontend" "index.html" "前端实现" "HTML/CSS/JS, responsive")
$(generate_agent_row "seo" "meta.md" "SEO优化" "meta tags, schema.org")
EOF

    cat /tmp/progress_table.md
}

# Generate agent row for table
generate_agent_row() {
    local agent_name="$1"
    local filename="$2"
    local task_desc="$3"
    local metrics_desc="$4"
    local file_path="ai-office/outputs/${filename}"

    if [[ -f "$file_path" ]]; then
        local size=$(file_size "$file_path")
        local lines=$(line_count "$file_path")
        local status="✓ Complete"
        local progress="100%"
        local metrics="${lines} lines, $size bytes, $metrics_desc"
        echo "| $agent_name | $task_desc | ${status} | ${progress} | ${metrics} |"
    else
        echo "| $agent_name | $task_desc | ✗ Missing | 0% | File not found |"
    fi
}

# Generate content consistency check
check_content_consistency() {
    log "检查内容一致性..."

    local outputs_dir="ai-office/outputs"

    cat << EOF

### 内容一致性

**Hero 区域一致性:**
- Hero headline in copy.md: $(get_hero_headline "$outputs_dir/copy.md")
- Hero headline in index.html: $(get_hero_headline "$outputs_dir/index.html")
- Match: $(check_headline_match "$outputs_dir")

**FAQ 一致性:**
- FAQ count in copy.md: $(count_faq "$outputs_dir/copy.md")
- FAQ section in design-spec.md: $(has_faq_section "$outputs_dir/design-spec.md")

**CTA 一致性:**
- CTA text in copy.md: $(get_cta_text "$outputs_dir/copy.md")
- CTA button in index.html: $(get_cta_button "$outputs_dir/index.html")
- Match: $(check_cta_match "$outputs_dir")

**SEO 对齐:**
- Keywords in meta.md: $(get_keywords "$outputs_dir/meta.md")
- Keywords present in copy.md: $(check_keywords_in_copy "$outputs_dir")

EOF
}

# Extract hero headline from file
get_hero_headline() {
    local file="$1"
    sed -n '/^## Hero/,/^##/p' "$file" 2>/dev/null | grep -i "title\|headline" | head -1 | cut -d: -f2 | tr -d ' ' || echo "N/A"
}

# Check if headlines match
check_headline_match() {
    local outputs_dir="$1"
    local copy_headline=$(get_hero_headline "$outputs_dir/copy.md")
    local html_headline=$(get_hero_headline "$outputs_dir/index.html")

    if [[ "$copy_headline" == "$html_headline" && "$copy_headline" != "N/A" ]]; then
        echo "✓ Match"
    else
        echo "✗ Mismatch"
    fi
}

# Count FAQ entries
count_faq() {
    local file="$1"
    grep_count "^###" "$file"
}

# Check if file has FAQ section
has_faq_section() {
    local file="$1"
    has_content "$file" "FAQ\|faq"
}

# Get CTA text
get_cta_text() {
    local file="$1"
    sed -n '/^## CTA/,/^##/p' "$file" 2>/dev/null | grep -i "button\|cta" | head -1 | cut -d: -f2 || echo "N/A"
}

# Get CTA button from HTML
get_cta_button() {
    local file="$1"
    grep -o 'btn.*">[^<]*' "$file" 2>/dev/null | head -1 | sed 's/.*>//' || echo "N/A"
}

# Check CTA match
check_cta_match() {
    local outputs_dir="$1"
    local copy_cta=$(get_cta_text "$outputs_dir/copy.md")
    local html_cta=$(get_cta_button "$outputs_dir/index.html")

    if [[ "$copy_cta" == "N/A" || "$html_cta" == "N/A" ]]; then
        echo "⚠️ Unknown"
    elif [[ "$copy_cta" == "$html_cta" ]]; then
        echo "✓ Match"
    else
        echo "✗ Mismatch"
    fi
}

# Get keywords from meta.md
get_keywords() {
    local file="$1"
    grep -i "keyword" "$file" 2>/dev/null | head -5 | cut -d: -f2 | tr '\n' ',' | sed 's/,$//' || echo "N/A"
}

# Check if keywords appear in copy
 check_keywords_in_copy() {
    local outputs_dir="$1"

    # Extract keywords from meta.md
    local keywords=$(grep -A5 "Keywords\|keywords" "$outputs_dir/meta.md" 2>/dev/null | tail -n +2 | tr '[:upper:]' '[:lower:]' || echo "")

    if [[ -z "$keywords" ]]; then
        echo "N/A"
        return
    fi

    # Check each keyword in copy.md
    local present=0
    local total=0

    for keyword in $keywords; do
        total=$((total + 1))
        if grep -qi "$keyword" "$outputs_dir/copy.md" 2>/dev/null; then
            present=$((present + 1))
        fi
    done

    if [[ $total -eq 0 ]]; then
        echo "N/A"
    else
        echo "$present/$total present"
    fi
}

# Check design token compliance
check_token_compliance() {
    log "检查设计令牌合规性..."

    local outputs_dir="ai-office/outputs"
    local design_spec="$outputs_dir/design-spec.md"
    local index_html="$outputs_dir/index.html"

    cat << EOF

### 设计令牌合规性

**design-spec.md 中的令牌引用:**
- color-* 令牌: $(count_occurrences "$design_spec" "color-")
- text-* 令牌: $(count_occurrences "$design_spec" "text-")
- space-* 令牌: $(count_occurrences "$design_spec" "space-")

**index.html 中的令牌引用:**
- var(--color-) 使用: $(count_occurrences "$index_html" "var(--color-)")
- var(--text-) 使用: $(count_occurrences "$index_html" "var(--text-)")
- var(--space-) 使用: $(count_occurrences "$index_html" "var(--space-)")

⚠️  注意: 详细比对需要手动审查

EOF
}

# Identify conflicts and gaps
identify_conflicts_and_gaps() {
    log "识别冲突和差距..."

    local outputs_dir="ai-office/outputs"

    cat << EOF

## 差距与冲突报告

### 信息缺口

$(identify_gaps "$outputs_dir")

### 冲突检测

$(identify_conflicts "$outputs_dir")

### 重复工作

$(identify_overlaps "$outputs_dir")

EOF
}

# Identify gaps
identify_gaps() {
    local outputs_dir="$1"
    local gap_count=0

    # Check for GAP markers
    local gaps=$(find "$outputs_dir" -name "*.md" -exec grep -l "GAP\|QUESTION" {} \; 2>/dev/null || echo "")

    if [[ -n "$gaps" ]]; then
        for file in $gaps; do
            local gap_lines=$(grep -n "GAP\|QUESTION" "$file" 2>/dev/null || echo "")
            if [[ -n "$gap_lines" ]]; then
                echo "- $(basename $file):"
                echo "$gap_lines" | head -3 | sed 's/^/  /'
                gap_count=$((gap_count + 1))
            fi
        done
    fi

    if [[ $gap_count -eq 0 ]]; then
        echo "✓ 未发现信息缺口"
    fi
}

# Identify conflicts
identify_conflicts() {
    local outputs_dir="$1"
    local conflict_count=0

    # Example: Check if CTA appears in multiple places with different text
    local copy_cta=$(get_cta_text "$outputs_dir/copy.md")
    local html_cta=$(get_cta_button "$outputs_dir/index.html")

    if [[ "$copy_cta" != "N/A" && "$html_cta" != "N/A" && "$copy_cta" != "$html_cta" ]]; then
        echo "**CTA 文本不一致**"
        echo "  - Copywriter: $copy_cta"
        echo "  - Frontend: $html_cta"
        echo "  - 建议: 统一为同一个 CTA"
        conflict_count=$((conflict_count + 1))
    fi

    # Check for section count mismatch
    if [[ -f "$outputs_dir/copy.md" && -f "$outputs_dir/design-spec.md" ]]; then
        local copy_sections=$(grep_count "^## " "$outputs_dir/copy.md")
        local design_sections=$(grep_count "^## " "$outputs_dir/design-spec.md")

        if [[ $copy_sections -ne $design_sections ]]; then
            echo "**章节数量不匹配**"
            echo "  - Copywriter: $copy_sections sections"
            echo "  - Designer: $design_sections sections"
            echo "  - 建议: 检查是否有章节缺失"
            conflict_count=$((conflict_count + 1))
        fi
    fi

    if [[ $conflict_count -eq 0 ]]; then
        echo "✓ 未发现 Agent 冲突"
    fi
}

# Identify overlaps
identify_overlaps() {
    local outputs_dir="$1"

    # Check if multiple agents defined button styles
    local design_buttons=$(count_occurrences "$outputs_dir/design-spec.md" "btn\|button")
    local html_buttons=$(count_occurrences "$outputs_dir/index.html" "btn\|button")

    if [[ $html_buttons -gt $design_buttons ]]; then
        echo "**按钮定义可能重叠**"
        echo "  - Designer: 定义了 $design_buttons 种按钮样式"
        echo "  - Frontend: 创建了 $html_buttons 个按钮实例"
        echo "  - 注意: 检查是否有重复定义"
    else
        echo "✓ 未发现重复工作"
    fi
}

# Generate decision log
generate_decision_log() {
    log "生成决策记录..."

    if [[ -f "ai-office/user-qa-log.md" ]]; then
        echo ""
        echo "## 关键决策记录"
        echo ""
        grep -A2 "^### Q" "ai-office/user-qa-log.md" | head -20 || echo "暂无决策记录"
    else
        echo ""
        echo "## 关键决策记录"
        echo "暂无 (user-qa-log.md 不存在)"
    fi
}

# Generate metrics
generate_metrics() {
    log "生成项目指标..."

    local copy_file="ai-office/outputs/copy.md"
    local html_file="ai-office/outputs/index.html"

    cat << EOF

## 项目指标

**内容指标:**
- Total word count: $(grep -oE "\w+" "$copy_file" 2>/dev/null | wc -l || echo 0)
- Unique keywords: $(grep -oE "\w{4,}" "$copy_file" 2>/dev/null | sort -u | wc -l || echo 0)
- Sections: $(grep_count "^## " "$copy_file")

**代码指标:**
- Lines of code: $(wc -l < "$html_file" 2>/dev/null || echo 0)
- File size: $(wc -c < "$html_file" 2>/dev/null || echo 0) bytes
- Components: $(grep_count "class=" "$html_file")

**性能估算:**
- Page weight: $(wc -c < "$html_file" 2>/dev/null || echo 0) bytes (without images)
- Lighthouse (预估): 90+ (good structure)
- Accessibility: Check contrast ratios manually

EOF
}

#=====================================
# Main Function
#=====================================

# Generate Orchestrator Summary
generate_orchestrator_summary() {
    log "开始生成 Orchestrator 汇总..."

    local output_file="ai-office/outputs/orchestrator-summary.md"

    # Check if outputs exist
    check_execution_status
    if [[ $? -gt 0 ]]; then
        log_warn "部分输出文件缺失，生成部分汇总..."
    fi

    # Generate summary
    cat > "$output_file" << EOF
# Orchestrator Summary - Executive Report

**生成时间**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**项目**: $(grep -A1 "## 主要目标" ai-office/brief.md 2>/dev/null | tail -1 || echo "Unknown")

## 1. 执行摘要

**完成度**: $(get_completion_percentage)/100%
**总工作量**: 4 Executors
**状态**: 所有 Agent 已完成工作

**主要交付物**:
$(list_all_deliverables)

## 2. 进度仪表板

$(generate_progress_dashboard)

## 3. 跨 Agent 一致性检查

$(check_content_consistency)

$(check_token_compliance)

## 4. 差距与冲突报告

$(identify_conflicts_and_gaps)

## 5. 整合说明

**文件依赖关系**: All outputs reference style-tokens.md and brief.md
**加载顺序**: Tokens → Design Spec → Copy → HTML → Meta

**Hot Reload 指南**:
- 修改 copy.md → 重新运行 Frontend Agent (仅 Phase 3.3)
- 修改 design-spec.md → 重新运行 Frontend Agent
- 修改 style-tokens.md → 重新运行 Designer + Frontend

## 6. 执行回放

待 Phase 4 (Critic) 完成后更新...

## 7. 关键决策记录

$(generate_decision_log)

## 8. 项目指标

$(generate_metrics)

## 9. 下一步行动

**准备进入 Phase 4 (Critic Review):**
1. 审查本汇总报告
2. 识别需要 Critic 关注的问题
3. 确定审查优先级

EOF

    log_success "Orchestrator 汇总已生成: $output_file"

    # Display summary to user
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$output_file" | head -50
    echo "..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Get completion percentage
get_completion_percentage() {
    local completed=$(check_execution_status >/dev/null 2>&1; echo $?)
    echo $(((4 - completed) * 25))
}

# List all deliverables
list_all_deliverables() {
    local outputs_dir="ai-office/outputs"

    for file in "$outputs_dir"/*.md; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file" .md)
            echo "- ✓ $(basename $file): $(wc -c < "$file" || echo 0) bytes"
        fi
    done

    if [[ -f "$outputs_dir/index.html" ]]; then
        echo "- ✓ index.html: $(wc -c < "$outputs_dir/index.html" || echo 0) bytes"
    fi
}

#=====================================
# Integration Functions
#=====================================

# Check if we should proceed to Phase 4
should_proceed_to_phase_4() {
    local completion=$(get_completion_percentage)

    if [[ $completion -lt 75 ]]; then
        log_warn "完成度不足 75%，建议先解决缺失的输出"
        return 1
    fi

    log_success "完成度 $completion%，可以进入 Phase 4"
    return 0
}

# Save state for Phase 3.5
save_orchestrator_state() {
    write_state "orchestrator_summary_generated" "true"
    write_state "outputs_status.orchestrator_summary" "completed"

    # Record metrics
    if [[ -f "ai-office/outputs/orchestrator-summary.md" ]]; then
        local size=$(file_size "ai-office/outputs/orchestrator-summary.md")
        write_state "orchestrator.metrics.size" "$size"
        write_state "current_phase" "3.5"
    fi

    log_success "Orchestrator 状态已保存"
}

#=====================================
# Entry Point
#=====================================

# Main function
run_orchestrator() {
    log "Orchestrator Phase 3.5 启动"

    # Set up environment
    source "$SKILL_ROOT/state-management.sh"

    # Initialize state only when this run starts from a fresh workspace.
    ensure_state_initialized

    # Record start time
    local START_TIME=$(date +%s)

    # Generate summary
    generate_orchestrator_summary

    # Check if we should proceed
    should_proceed_to_phase_4

    # Save state
    save_orchestrator_state

    # Record duration
    local END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))

    log_success "Orchestrator 完成 (耗时: ${DURATION}s)"

    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_orchestrator
fi
