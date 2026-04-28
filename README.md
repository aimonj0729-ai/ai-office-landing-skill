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

## Autopilot Updates

<!-- github-autopilot:updates:start -->

### 2026-04-28 16:18

**改动**

修了一个高置信度的脚本稳定性问题：`discover-skills.sh` 和 `orchestrator.sh` 之前每次运行都会直接调用 `init_state`，会把已有的 `ai-office/state.json` 重置掉，等于破坏 `--resume` 场景。现在我在 [state-management.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/state-management.sh:209) 加了 `ensure_state_initialized()`，只有状态文件不存在时才初始化；[discover-skills.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/discover-skills.sh:371) 和 [orchestrator.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/orchestrator.sh:631) 已改为走这个非破坏性入口。

README 和变更记录也同步了这次修复，用户现在能直接在 [README.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38)、[README.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:151) 和 [CHANGELOG.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:5) 看到这次“保留已有 state.json”的说明。

**验证**

- 运行了 `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 做了状态保护 smoke test：预先写入 `current_phase=3` 和 checkpoint `keep-me`，执行 `bash ./discover-skills.sh help` 后，`state.json` 仍保持 `3 / keep-me`，没有被重置

未提交，未推送。

### 2026-04-28 16:16

这次只做了一项脚本稳定性修复：`discover-skills.sh` 和 `orchestrator.sh` 之前每次启动都会直接调用 `init_state`，导致已有的 `ai-office/state.json` 被重新初始化。只要用户在进行中的项目里跑一次技能发现或 Phase 3.5 汇总，`current_phase`、checkpoint 和输出状态就会被重置，这和 README 里声明的 `--resume`/状态恢复行为冲突。

- [state-management.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/state-management.sh:173) 新增 `ensure_state_initialized()`，只有在 `ai-office/state.json` 不存在时才初始化状态。
- [discover-skills.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/discover-skills.sh:378) 和 [orchestrator.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/orchestrator.sh:635) 已切换到非破坏性的状态引导，不会再覆盖现有会话。
- [README.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:142) 与 [CHANGELOG.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:7) 已记录这次修复。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 状态保护 smoke test：预先写入 `current_phase=3` 和自定义 checkpoint 后运行 `discover-skills.sh help`，确认 `state.json` 未被重置

未提交，未推送。

### 2026-04-27 09:43

修了一项高置信度的小问题：仓库首页已经声明 `v2.4.0`，但插件 manifest、安装脚本和几个对外脚本还在显示或校验 `v2.3`，会让安装结果、帮助输出和发布文案互相矛盾。

- [.claude-plugin/manifest.json](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/.claude-plugin/manifest.json:3) 已同步到 `2.4.0`，并补了 `2.4.0` 的 manifest 内部变更说明。
- [install.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh:40) 现在从 manifest 读取版本，安装提示、安装校验和生成的示例工作流不再硬编码旧版本。
- [discover-skills.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/discover-skills.sh:14) 的帮助输出和 `info` 子命令改为读取 manifest 元数据；[setup-github-repo.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/setup-github-repo.sh:6) 与 [examples/test.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/examples/test.sh:2) 也同步到了当前版本。
- [README.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38) 和 [CHANGELOG.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:8) 已记录这次修复。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- `./discover-skills.sh help`
- `bash examples/test.sh`
- 安装态 smoke test：复制仓库到临时 `~/.claude/skills` 风格目录后执行 `discover-skills.sh info ai-office-landing`，已正确输出 `Version: 2.4.0` 和描述

未提交，未推送。

### 2026-04-27 10:18

这次只做了一项高置信度改进：把插件版本元数据重新收口到 `.claude-plugin/manifest.json`，并同步修正所有对外脚本里的旧 `v2.3` 文案。此前 `README` 已经写成 `v2.4.0`，但 `manifest`、`install.sh`、`discover-skills.sh`、`setup-github-repo.sh` 和 [examples/test.sh](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/examples/test.sh:1>) 仍会显示 `v2.3`，`install.sh` 还会用旧版本号做安装校验，容易让用户误判当前安装内容。

现在 `.claude-plugin/manifest.json` 已更新到 `2.4.0`，`install.sh` 和发布/示例脚本会直接从 manifest 读取版本，避免后续继续漂移；另外 `discover-skills.sh info` 也改为从 manifest 读取 `version` 和 `description`，不再依赖旧的错误解析方式。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- `./discover-skills.sh help`
- `bash examples/test.sh`

未提交，也未推送。

### 2026-04-26 09:42

**改动**
- [orchestrator.sh](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/orchestrator.sh:9>) 现在会自行定位 `SKILL_ROOT`，并把 `check_execution_status()` 里的 Bash 4 关联数组改成 Bash 3.2 可用的普通数组；同时补了稳定的计数 helper 和安全的状态键写入，避免直接运行 Phase 3.5 时在 macOS 默认 `/bin/bash` 下报错。
- [install.sh](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh:40>) 和 [.claude-plugin/manifest.json](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/.claude-plugin/manifest.json:8>) 的 Bash 要求已从 `4.0+` 同步下调到 `3.2+`，和当前脚本能力保持一致。
- [README.md](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38>)、[README.md](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:94>) 和 [CHANGELOG.md](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:7>) 已同步写明这次兼容性修复。

**验证**
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- macOS `/bin/bash 3.2` smoke test：在临时目录直接执行仓库里的 `orchestrator.sh`，成功生成 `ai-office/outputs/orchestrator-summary.md`

未提交，也未推送。

### 2026-04-26 09:58

这次只做了一项高置信度改进：补齐了 `orchestrator.sh` 的 macOS 默认 Bash 兼容性。脚本原先还残留 `declare -A` 和对外部 `SKILL_ROOT` 的隐式依赖，导致 README 里这种直接运行方式在 macOS `/bin/bash 3.2` 下并不稳。现在 `orchestrator.sh` 会自行定位 skill 根目录，并改用 Bash 3 兼容的数据结构；`install.sh` 和 `.claude-plugin/manifest.json` 里的 Bash 要求也同步从 `4.0+` 下调到 `3.2+`。

README 和变更记录已经同步更新；此外在快速开始下方补了一条环境说明，明确 `install.sh`、`discover-skills.sh`、`orchestrator.sh` 和 `cost-tracker.sh` 现在都可以直接跑在 macOS 默认 Bash 3.2 上，不再要求额外安装 Homebrew Bash。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- macOS `/bin/bash 3.2` smoke test：在临时目录里直接执行仓库里的 `orchestrator.sh`，成功生成 `ai-office/outputs/orchestrator-summary.md`

未提交，也未推送。

### 2026-04-25 11:14

这次只做了一项高置信度改进：修复了成本追踪脚本的初始化与历史恢复链路。核心改动在 [cost-tracker.sh](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/cost-tracker.sh:41>)、[cost-tracker.sh](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/cost-tracker.sh:120>) 和 [cost-tracker.sh](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/cost-tracker.sh:435>)。原脚本会把 `total_token_limit` 变量名写错、从错误的数据文件读当前用量、写回日期键时 `jq` 表达式不稳，还依赖 Bash 4 关联数组和 `numfmt`。现在它会正确从 `~/.claude/cost-history.json` 恢复当天累计用量，改为兼容 macOS 默认 Bash 3 的相位成本实现，并在没有 `numfmt` 时自动回退到纯数字显示。

README 和变更记录也已同步更新，用户可以直接在 [README.md](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38>) 和 [README.md](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:214>) 看到这次修复说明；[CHANGELOG.md](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:7>) 也补了 `Unreleased` 记录。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 针对 `cost-tracker.sh` 做了临时 `HOME` smoke test：预置当天历史用量 `1234` 后，`init_cost_tracking` 正确恢复为 `1234/45000`；再记录 `2000` token 后，`session-cost.json` 和 `~/.claude/cost-history.json` 都更新为 `3234`

未提交，也未推送。

### 2026-04-25 11:10

- 已修复 `cost-tracker.sh` 的初始化链路：当天限额字段会正确写入 `session-cost.json`，并能从 `~/.claude/cost-history.json` 恢复当日累计用量。
- 成本追踪不再依赖 Bash 4 的关联数组；在 macOS 默认 Bash 3 环境下也能加载相位成本配置。
- 如果系统没有安装 `numfmt`，成本面板现在会自动回退为原始数字显示，避免在 macOS 上因缺少 GNU coreutils 而报错。

### 2026-04-23 22:05

- 已修复 `discover-skills.sh` 在 macOS Bash 3 下的自动发现链路，`discover`、`auto-designer`、`suggest` 现已恢复可用。
- `auto-designer` 现在会自动去重候选 skill，并跳过当前 `ai-office-landing` skill 自身，避免把内置 skill 当作外部参考重复加载。
- 后续自动化更新会默认直接同步到 `main`，并把每次新增、修复或调整的摘要持续写入本节，方便直接在仓库首页查看。

<!-- github-autopilot:updates:end -->

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

核心脚本 `install.sh`、`discover-skills.sh`、`orchestrator.sh` 和 `cost-tracker.sh` 现在都兼容 macOS 默认的 `/bin/bash 3.2`，不需要额外安装 Bash 4 才能完成安装和 Phase 3.5 汇总。

`discover-skills.sh` 和 `orchestrator.sh` 现在只会在缺少 `ai-office/state.json` 时初始化状态；如果你正在用 `--resume` 继续一个进行中的项目，再次运行这些辅助脚本也不会把当前 phase、checkpoint 和输出状态清空。

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

`cost-tracker.sh` 现在会优先恢复 `~/.claude/cost-history.json` 里的当天累计用量，并在缺少 `numfmt` 的环境中自动退回为纯数字输出，适合直接在 macOS 默认 shell 环境下查看成本面板。

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
