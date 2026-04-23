# AI Office Landing Skill - v2.4

**版本**: v2.4.0  
**发布日期**: 2026-04-12  
**核心特性**: 多模型 Adapter 路由 + Kimi/DeepSeek 降级支持

## 版本历史

### v2.4.0 (当前版本)
- **多模型 Adapter 路由**: 新增 `adapters/route.sh` 自动根据角色质量等级选择最优 API
- **Kimi API 适配器**: `adapters/kimi-api.sh` — 适合 Copywriter/Designer/SEO 降级
- **DeepSeek API 适配器**: `adapters/deepseek-api.sh` — 适合 Frontend (自动选 deepseek-coder)
- **成本节省模式**: `--cost-saving` / `COST_SAVING_MODE=true` 自动路由到便宜模型
- **HIGH 角色保护**: Critic/Interviewer/Integrator 不可降级，确保质量安全网

### v2.3.0
- **新增 Phase 3.5 Orchestrator**: 自动收集和汇总所有 Executor 输出
- **动态 Skill 发现**: Designer Agent 可自动发现和加载相关 skills
- **Gap & Conflict 报告**: 识别 Agent 间的不一致和信息缺口
- **进度仪表板**: 可视化显示所有 Agent 的完成状态

### v2.2.0
- **成本追踪**: 实时 token 消耗追踪和可视化
- **基准分析**: 与参考网站对比，识别改进空间
- **限额警告**: 自动检测是否接近 Claude Pro 日限额

### v2.0.0
- **对话式交互**: 支持执行中提问和增量交付
- **素材搜索**: Designer 可搜索参考网站和视觉素材

### v1.0.0
- **基础工作流**: 批处理模式的 5 阶段 Agent 协作

## 快速开始

```bash
# 启动交互式工作流
/landing

# 串行模式（分天执行，避免超限）
/landing --serial

# 人工审查（节省成本）
/landing --human

# 成本节省模式：自动路由 MEDIUM/LOW 角色到 Kimi/DeepSeek
export KIMI_API_KEY="your-key"
export DEEPSEEK_API_KEY="your-key"
/landing --cost-saving
```

## 增强特性

### 1. Orchestrator 汇总 (Phase 3.5)
在所有 Executor 完成后自动运行，生成 `orchestrator-summary.md` 包含：
- ✅ 执行状态和完成度
- ✅ 跨 Agent 一致性检查
- ✅ 差距与冲突报告
- ✅ 整合说明和依赖关系
- ✅ 关键决策记录
- ✅ 项目指标和性能估算

### 2. 动态 Skill 发现
Designer Agent 可自动发现相关 skills：

```bash
# 自动发现（推荐）
~/.claude/skills/ai-office-landing/discover-skills.sh auto-designer

# 搜索特定关键词
~/.claude/skills/ai-office-landing/discover-skills.sh discover "color theory"

# 任务导向建议
~/.claude/skills/ai-office-landing/discover-skills.sh suggest "coffee shop branding"
```

`auto-designer` 现在会自动去重候选项，并跳过当前 `ai-office-landing` skill 自身，避免把内置 skill 误当作外部参考重复加载。

### 3. 智能决策支持
- **Skill 加载**: 自动将相关 skill 内容加载到 Agent 上下文
- **引用参考**: 在 design-spec.md 中引用 skill 提供的洞察
- **Token 合规**: 确保所有设计决策符合 style-tokens.md

## 技术架构

```
ai-office/
├── brief.md              # Living Brief (single source of truth)
├── style-tokens.md       # 设计系统令牌
├── tasks.md              # Agent 任务定义
├── state.json            # 状态追踪和 checkpoint
├── cost/                 # Token 消耗记录
├── interaction/          # 用户 Q&A 日志
├── references/           # 参考网站和素材
├── outputs/              # 所有 Agent 输出
│   ├── copy.md
│   ├── design-spec.md
│   ├── index.html
│   ├── meta.md
│   └── orchestrator-summary.md  ← NEW v2.3
└── critique.md           # Critic 审查报告
```

## v2.3 主要改进

### 自动化集成
- ✅ 自动生成 Orchestrator 汇总报告
- ✅ 一致性检查（Content/CTA/SEO 对齐）
- ✅ Token 合规性验证
- ✅ 间隙和冲突自动识别

### 扩展能力
- ✅ Designer Agent 支持 skill 发现
- ✅ 上下文感知的设计决策
- ✅ 可插拔的 skill 系统
- ✅ 资源引用和重用

### 用户体验
- ✅ 执行状态可视化
- ✅ 进度仪表板
- ✅ 明确的下一步行动
- ✅ 决策追踪和审计

## 文件清单

**新增 v2.4:**
- `adapters/kimi-api.sh` - Kimi (Moonshot) API 适配器
- `adapters/deepseek-api.sh` - DeepSeek API 适配器 (Frontend 自动选 deepseek-coder)
- `adapters/route.sh` - Adapter 路由器 (根据角色质量等级自动选择)

**v2.3:**
- `orchestrator.sh` - Orchestrator 执行脚本
- `discover-skills.sh` - Skill 发现工具
- `prompts/orchestrator-summary.md` - Orchestrator 提示
- `prompts/benchmark-analyzer.md` - 基准分析

**改进:**
- `SKILL.md` - 添加 adapter 路由逻辑到 Phase 3
- `README.md` - 更新版本和 adapter 文档

## 使用示例

### 完整工作流
```bash
# 1. Phase 0-2: 需求收集和令牌生成
/landing

# 2. Phase 3: 执行（Designer 自动发现 skills）
# Designer 自动运行: discover-skills.sh auto-designer

# 3. Phase 3.5: 自动汇总（自动触发）
orchestrator.sh

# 4. Phase 4: Critic 审查
# 使用 benchmark-analyzer.md 进行基准对比

# 5. Phase 5: 交付
# 所有输出在 ai-office/outputs/
```

### Skill 发现示例
```bash
# 搜索设计相关的 skills
~/.claude/skills/ai-office-landing/discover-skills.sh discover "coffee"

# 输出:
# ✓ 发现 3 个相关 skills:
#   - color-palettes
#   - web-design-guidelines
#   - ui-ux-pro-max

# 加载特定 skill
~/.claude/skills/ai-office-landing/discover-skills.sh load designer color-palettes

# 在上下文目录中访问 skill 内容
ls ~/.claude/skills/ai-office-landing/context/designer/
```

## 性能与成本

**预计 Token 消耗:**
- Phase 0: 15,000 tokens
- Phase 1: 13,000 tokens  
- Phase 2: 8,000 tokens
- Phase 3: 80,000 tokens (4x Executors)
- Phase 3.5: 5,000 tokens ← NEW
- Phase 4: 20,000 tokens (Benchmark Analyzer 增强)
- Phase 5: 5,000 tokens
- **总计**: ~146,000 tokens

**优化建议:**
- 使用 `--serial` 分摊到多天
- 使用 `--human` 跳过 Critic
- 启用成本节省模式: `export COST_SAVING_MODE=true`

## 扩展指南

### 添加新 Skill
1. 创建 skill 目录结构
2. 实现必要的 prompts 和 assets
3. 更新 `discover-skills.sh` 的 keywords 映射
4. 测试 skill 发现和加载

### 自定义 Orchestrator 检查
编辑 `orchestrator.sh`：
- 在 `check_content_consistency()` 添加新的检查逻辑
- 在 `identify_conflicts_and_gaps()` 添加自定义冲突检测
- 在 `generate_metrics()` 添加新的项目指标

### 集成外部 Skills
在 `.claude/skills/` 安装外部 skills：
- `discover-skills.sh` 会自动扫描所有子目录
- Designer Agent 可以发现并使用这些 skills
- 无需修改核心代码

## 许可证

MIT - 详见 LICENSE 文件

## 贡献

欢迎提交 Issue 和 Pull Request！

## 支持

路径：`~/.claude/skills/ai-office-landing/`
快捷方式：`/landing`
文档：`SKILL.md`
