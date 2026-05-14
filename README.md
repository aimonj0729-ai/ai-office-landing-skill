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

### 2026-05-14 17:47

这次只做了一项小而完整的文档同步修复，重点是把过期的状态管理示例清掉，避免用户照着文档重新写回已经修过的坏模式。具体改动在 [SKILL.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/SKILL.md)、[README.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md) 和 [CHANGELOG.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md)。`SKILL.md` 里的 State Management、Recovery 和 Phase 3 Q&A 示例现在统一改为使用 `state-management.sh` 的 helper，比如 `ensure_state_initialized`、`get_current_phase`、`mark_task_completed`、`mark_task_waiting_for_user`、`add_pending_question` 和 `create_checkpoint`。README 也同步新增了这次更新说明，并补了一条明确建议：扩展工作流时优先复用这些 helper，不要手写 `jq` 去改 `state.json`。

这样改的原因很直接：仓库脚本已经修过带点号、连字符和引号的状态写入问题，但文档里还保留着旧示例，和实现不一致，继续误导用户的概率很高。这次把文档和当前实现重新对齐，属于高置信度、低风险的可用性修复。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- `rg -n 'jq \".*\$key|pending_questions\[0\]|outputs_status\.\$role' SKILL.md`

结果正常；未提交，未推送。

### 2026-05-14 15:15

这次做的是一项高置信度的文档同步修复：把 [`SKILL.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/SKILL.md>) 里仍在示范旧状态写入方式的片段，统一改成和当前脚本实现一致的 helper 用法。此前文档还保留着直接手写 `jq` 状态更新、数组下标写入和动态路径拼接的示例；这些写法和现在的 [`state-management.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/state-management.sh>) 已不一致，也容易把带点号、连字符或引号的真实值重新写坏。

现在 `SKILL.md` 的 State Management / Recovery / Phase 3 Q&A 示例都改成了 `ensure_state_initialized`、`get_current_phase`、`mark_task_completed`、`mark_task_waiting_for_user`、`add_pending_question` 和 `create_checkpoint` 这些仓库内置 helper。README 也同步补了一条说明：后续扩展或集成时应优先复用 `state-management.sh`，不要再按旧示例手写 `jq` 更新状态。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- `rg -n 'jq \".*\$key|pending_questions\[0\]|outputs_status\.\$role' SKILL.md`

结果正常：主 README、技能文档和实现说明现在一致，`SKILL.md` 里不再保留这组过期状态写入示例。未提交，未推送。

### 2026-05-12 09:38

这次只做了一项高置信度修复：把 [state-management.sh](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/state-management.sh:263) 里几处把自由文本直接拼进 `jq` 表达式的逻辑，改成了 `--arg` / `--argjson` 安全传参。受影响的是 `get_questions_for_source`、`mark_question_resolved`、`add_pending_question` 和 `create_checkpoint`。修这个是因为它能稳定复现：只要提问或 checkpoint 文案里带双引号，例如 `用户说 "hero 文案" 需要更短`，脚本之前就会报 `jq compile error`，直接破坏对话式状态保存。

README 和变更记录已经同步到 [README.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38)、[README.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:418) 和 [CHANGELOG.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:11)，用户现在可以直接从主 README 看到这次修复内容。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 临时目录 smoke test：`add_pending_question 'critic' '用户说 "hero 文案" 需要更短'`
- 临时目录 smoke test：`create_checkpoint 2 1 '用户要求 "先保留现有色板"'`

结果正常：两类带引号的文本都能成功写入 `ai-office/state.json`。未提交，未推送。

### 2026-05-12 09:37

这次只做了一项高置信度的状态管理稳定性修复：`state-management.sh` 之前在 `add_pending_question`、`get_questions_for_source`、`mark_question_resolved` 和 `create_checkpoint` 里，把用户文本直接拼进 `jq` 表达式。只要问题或 checkpoint 文案里带双引号，比如 `用户说 "hero 文案" 需要更短`，脚本就会直接报 `jq compile error`，导致对话式工作流的待处理问题和断点状态无法保存。

现在这些入口都改成了 `jq --arg` / `--argjson` 的安全写法，带引号、空格和其他普通自由文本的提问、来源名和 checkpoint 文案都能正常写回 `ai-office/state.json`。README 和变更记录已同步更新，方便直接从仓库首页看到这次修复。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 临时目录 smoke test：`add_pending_question 'critic' '用户说 "hero 文案" 需要更短'`
- 临时目录 smoke test：`create_checkpoint 2 1 '用户要求 "先保留现有色板"'`

结果正常：两类带引号的自由文本现在都能成功写入状态文件，不再触发 `jq` 语法错误。未提交，未推送。

### 2026-05-10 09:43

修的是一处高置信度的发布回退问题。[setup-github-repo.sh](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/setup-github-repo.sh:8) 在本机没有 `gh` 时，原先给出的手动发布步骤把本地目录写死成 `/tmp/ai-office-landing`，而且 `git remote add origin` 也始终是占位符。现在它会改用当前 checkout 的真实路径，并支持从 `GITHUB_OWNER` 或 `REPO_OWNER` 注入 owner；如果没设置，也会明确提示。这样在没有 GitHub CLI 的机器上，回退说明可以直接更接近可执行状态。

README 和变更记录已同步到 [README.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38)、[README.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:415) 和 [CHANGELOG.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:11)，方便用户直接看到这次修复。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- `env PATH=/usr/bin:/bin bash ./setup-github-repo.sh`
- `env PATH=/usr/bin:/bin GITHUB_OWNER=stub-owner bash ./setup-github-repo.sh`

结果正常：无 `gh` 回退输出现在指向当前仓库路径，且在设置 `GITHUB_OWNER` 时会生成带真实 owner 的远程地址。未提交，未推送。

### 2026-05-10 09:42

这次只做了一项高置信度的发布回退修复：[`setup-github-repo.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/setup-github-repo.sh>) 在本机未安装 `gh` 时，会打印一套手动创建 GitHub 仓库的备用步骤；但这套步骤之前把本地目录写死成 `/tmp/ai-office-landing`，和实际 checkout 无关，复制后很容易直接进入不存在的目录。与此同时，哪怕调用方已经通过环境变量知道 GitHub owner，回退命令里的 `git remote add origin` 也仍然固定输出占位符。

现在这个回退路径会直接引用当前仓库 checkout 的真实路径，并支持从 `GITHUB_OWNER` 或 `REPO_OWNER` 环境变量注入远程仓库 owner；如果这两个变量都没设，脚本也会明确提示可以先设置后重跑，这样在缺少 GitHub CLI 的机器上也能更可靠地完成手动发布。README 和变更记录已同步更新。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- `env PATH=/usr/bin:/bin bash ./setup-github-repo.sh`
- `env PATH=/usr/bin:/bin GITHUB_OWNER=stub-owner bash ./setup-github-repo.sh`

未提交，未推送。

### 2026-05-09 16:03

修了一项高置信度的发布体验问题：[`setup-github-repo.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/setup-github-repo.sh:94>) 在 `gh repo create` 成功后，原先打印的安装示例仍然写死 `your-username`，用户直接复制会得到 404。现在脚本会把已解析到的 `REPO_OWNER` / `REPO_NAME` 注入到 `wget`、`git clone` 和 `curl` 示例里，发布完成后终端输出可以直接使用。

README 和变更记录也同步了这次修复：[`README.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38>) 新增了本次更新说明，[`README.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:390>) 补了发布后安装命令的说明，[`CHANGELOG.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:14>) 记录了该修复。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 成功路径 smoke test：注入临时 `gh` stub 后运行 `bash ./setup-github-repo.sh`，确认输出中的仓库地址、tarball URL 和 `git clone` URL 都使用 `stub-owner/ai-office-landing-skill`，且不再出现 `your-username`

未提交，未推送。

### 2026-05-09 16:02

这次只做了一项高置信度修复：发布脚本 [`setup-github-repo.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/setup-github-repo.sh>) 在 `gh repo create` 成功之后，后续打印给用户的安装示例还残留 `your-username` 占位符，导致仓库虽然已经创建成功，但复制 README 里的命令仍然会 404。这个问题直接影响发布后的首次安装体验，也不适合无人值守分发。

现在脚本会把已解析到的 GitHub 用户名继续注入到 tarball、`git clone` 和 `curl` 安装示例里，发布完成后终端里看到的命令可以直接复制使用；README 也同步补了一条说明，明确 `setup-github-repo.sh` 现在会输出带真实 owner 的可执行安装链接。[`README.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md>) 和 [`CHANGELOG.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md>) 已同步记录。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 受控 smoke test：注入成功路径 `gh` stub 后执行 `bash ./setup-github-repo.sh`，确认输出的 `wget`、`git clone` 和 `curl` 示例都已替换成真实 owner `stub-owner`，不再包含 `your-username`

未提交，未推送。

### 2026-05-08 17:30

这次只做了一项高置信度修复：收紧 `install.sh` 的 Claude 配置写入链路，避免在 `~/.claude/settings.json` 损坏时误报安装成功。

在 [install.sh](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh#L88) 我加了安装前校验：如果 `~/.claude/settings.json` 不是有效 JSON，或者 `.skills` 不是对象，脚本会在复制文件前直接失败并给出明确提示。配置写入步骤也改成了真正的致命错误处理，不再出现 `jq` parse error 已经发生、脚本却继续打印“安装成功”的情况，相关写入逻辑在 [install.sh](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh#L205)。README 和变更记录已同步到 [README.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md#L38)、[README.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md#L348) 和 [CHANGELOG.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md#L12)。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 临时 `HOME` smoke test：把 `~/.claude/settings.json` 预置成无效 JSON 后执行 `./install.sh install`，现在返回非零并明确报错
- 临时 `HOME` 正常安装 smoke test：`./install.sh install` 返回 `0`，并正确写入 `~/.claude/settings.json` 的 `ai-office-landing` 注册

未提交，也未推送。

### 2026-05-08 16:52

这次只做了一项高置信度的安装链路修复：[`install.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh>) 之前在 `~/.claude/settings.json` 已损坏成无效 JSON 时，会先打印 `jq` 解析错误，但随后仍继续输出“安装成功”并返回成功状态。这对无人值守安装尤其危险，因为自动化会误以为 skill 已正确注册。

现在安装器会在复制文件前先校验 `~/.claude/settings.json`：如果它不是有效 JSON，或者 `.skills` 不是对象，就会立即失败并给出明确提示；同时把配置写入步骤改成真正的致命错误处理，不再在 `jq` 失败后继续打印成功文案。[`README.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md>) 和 [`CHANGELOG.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md>) 已同步记录这次修复。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 临时 `HOME` smoke test：把 `~/.claude/settings.json` 预置成无效 JSON 后执行 `./install.sh install`，现在脚本会返回非零并明确提示配置损坏；不再在 `jq` parse error 后继续输出“安装成功”

未提交，未推送。

### 2026-05-07 09:41

这次只做了一项高置信度修复：发布脚本 [`setup-github-repo.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/setup-github-repo.sh:6>) 之前在 `gh repo create` 失败时仍会继续执行，最后误报“GitHub 仓库已创建成功”。我把它改成了 fail-fast：现在 `gh auth status`、`gh repo create` 和 GitHub 用户查询任一失败都会立刻退出并给出明确错误，不再输出假的成功信息；仓库地址也改为复用已成功查询到的用户名。[`README.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38>) 和 [`CHANGELOG.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:11>) 已同步记录这次更新。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 受控 smoke test：注入会让 `gh repo create` 失败的临时 `gh` stub，确认脚本现在返回退出码 `1`，且不再打印“GitHub 仓库已创建成功”

未提交，未推送。

### 2026-05-07 09:39

这次只做了一项高置信度的发布脚本修复：[`setup-github-repo.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/setup-github-repo.sh>) 之前没有启用严格错误处理，`gh repo create` 失败后脚本仍会继续往下执行，最后错误地打印“GitHub 仓库已创建成功”和仓库地址。这个失败路径很容易在仓库已存在、认证过期或网络异常时误导用户，尤其不适合无人值守发布。

现在脚本已改成 fail-fast：会在 `gh auth status`、`gh repo create` 或当前 GitHub 用户查询失败时立即退出，并输出明确的错误提示，不再在失败后继续展示成功文案。[`CHANGELOG.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md>) 也已同步记录。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 受控 smoke test：注入一个会让 `gh repo create` 返回非零的临时 `gh` stub，确认脚本现在会直接退出并返回非零状态，不再打印“GitHub 仓库已创建成功”

未提交，未推送。

### 2026-05-06 09:43

做了一项高置信度的安装体验修复。此前 `./install.sh uninstall` 只会删掉安装目录，不会清理 `~/.claude/settings.json` 里的 skill 注册，卸载后会残留一个失效的 `SKILL.md` 路径。现在 [install.sh](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh:219) 增加了配置清理逻辑，并把卸载流程改成先移除 `ai-office-landing` 注册，再删除安装目录；如果目录已经被手动删掉，也会继续清理残留注册，[install.sh](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh:401)。[README.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38) 和 [README.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:301) 已同步写明本次更新与卸载说明，[CHANGELOG.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:11) 也已记录。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 临时 `HOME` 安装/卸载 smoke test：`./install.sh install` 会注册 skill；随后 `./install.sh uninstall` 会同时删除安装目录和 `~/.claude/settings.json` 中的 `ai-office-landing` 条目
- 额外补了一次“目录先被手动删掉再执行 uninstall”的验证，残留注册也能被清掉

未提交，未推送。

### 2026-05-06 09:41

这次只做了一项高置信度的安装体验修复：[`install.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh>) 之前在 `uninstall` 时只会删除 `~/.claude/skills/ai-office-landing` 目录，但不会同步清理 `~/.claude/settings.json` 里的 skill 注册。这样卸载后 Claude Code 仍会保留一个指向已删除 `SKILL.md` 的失效路径，后续排查安装问题时很容易误导用户。

现在 `./install.sh uninstall` 会先检查并移除 `settings.json` 中的 `ai-office-landing` 注册，再删除安装目录；如果技能目录已经被手动删掉，它也会继续尝试清理这条残留注册。[`README.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md>) 和 [`CHANGELOG.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md>) 已同步记录。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 临时 `HOME` 安装/卸载 smoke test：`./install.sh install` 会注册 skill；随后 `./install.sh uninstall` 会同时删除安装目录和 `~/.claude/settings.json` 中的 `ai-office-landing` 条目

未提交，未推送。

### 2026-05-05 09:40

这次只做了一项高置信度改进：修正发布后安装说明里的错误路径。在 [setup-github-repo.sh](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/setup-github-repo.sh) 里，原先既有 raw `install.sh` 的单文件执行示例，也有“先解压/克隆到最终安装目录再运行安装器”的示例；这两种方式都和实际安装器行为不匹配。`install.sh` 需要同目录下的完整仓库文件，而且它本身会把当前 checkout 复制到 `~/.claude/skills/ai-office-landing`。现在这些示例都统一改成“先拿到临时完整 checkout，再从 checkout 里执行安装器”。[README.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md) 已同步加入本次更新说明和可用的 `curl` tarball 安装示例，[CHANGELOG.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md) 也已记录。

验证已完成：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- tarball 安装 smoke test：在临时 checkout 和临时 `HOME` 下执行 `./install.sh install`，安装成功，并生成了 `~/.claude/settings.json` 与 `examples/workflow-demo.sh`

未提交，未推送。

### 2026-05-05 09:37

修了一项高置信度的安装说明问题：[`setup-github-repo.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/setup-github-repo.sh>) 之前给发布后的仓库输出了几种不可靠的安装方式，包括 `bash -c "$(curl .../install.sh)"` 这种单文件安装，以及把仓库直接放进 `~/.claude/skills/ai-office-landing` 后再运行 [`install.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh>)。前者缺少 `.claude-plugin/manifest.json`、`prompts/`、`templates/` 等依赖文件，后者又会让安装器把“当前 checkout”误判成一个已存在安装，和脚本自己的复制逻辑打架。

现在 `setup-github-repo.sh` 里的下载/克隆示例都统一改成“先拿到完整仓库到临时目录，再从 checkout 里执行安装器”；README 也同步补充了“不要直接执行 raw install.sh，也不要在最终安装目录内自举安装”的说明和可用示例。这样保留了一键安装体验，同时不再宣传会天然缺少文件或和安装器逻辑冲突的错误入口；[`CHANGELOG.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md>) 也已记录本次调整。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 本地 tarball 安装 smoke test：在临时 `HOME` 下打包当前仓库并按新的 tarball 流程解压后执行 `./install.sh install`，安装成功

未提交，未推送。

### 2026-05-04 09:50

修了一项高置信度的状态管理问题。`state-management.sh` 之前把任务名直接拼进 jq 路径，像 `design-references`、`brief.md` 这类真实键会被当成减号或层级访问处理，结果要么报错，要么写出错误的嵌套结构 `outputs_status.brief.md`。我在 [state-management.sh](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/state-management.sh:60>) 里加了按字面键读取的 helper，把对象字段更新改成 `jq --arg` 安全写法，并让完成状态检查和用户输入读取也走这条安全路径；同时去掉了旧字符串写入会附带换行的问题。README 和变更记录已同步到 [README.md](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38>)、[CHANGELOG.md](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:10>)。

已运行验证。`bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh` 通过；另外做了临时目录 smoke test，结果是 `mark_task_completed "design-references"` 和 `mark_task_completed "brief.md"` 都能正确写回，`outputs_status` 不再出现错误的 `brief` 嵌套对象，`task_is_completed "brief.md"` 返回成功，带点号的用户输入键也能正常保存和读取（结果为 `Acme`）。

未提交，未推送。

### 2026-05-04 09:49

这次只做了一项高置信度的状态管理修复：`state-management.sh` 之前直接把任务名拼进 jq 路径，像 `design-references`、`brief.md`、`style-tokens.md` 这类真实输出键会被误当成减号或层级访问处理。结果要么直接报错，要么把状态错误地写成 `outputs_status.brief.md` 这样的嵌套对象，导致完成标记和恢复判断都不可靠。

现在对象字段读写已改成基于 `jq --arg` 的字面键访问，`mark_task_completed`、`task_is_completed` 和用户输入读取都会按真实键名工作；同时顺手去掉了旧字符串写入路径里会额外附带换行的问题。`README.md` 和 `CHANGELOG.md` 也已同步记录本次修复。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 状态管理 smoke test：`mark_task_completed "design-references"` 现在可成功写回；`mark_task_completed "brief.md"` 不再生成错误的 `outputs_status.brief.md` 嵌套结构；`task_is_completed "brief.md"` 会按预期返回成功

未提交，未推送。

### 2026-05-03 09:41

这次只做了一项高置信度修复：把安装链路里残留的旧 `prompts/interviewer.md` 引用，对齐到仓库当前实际使用的根目录 [interview.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/interview.md:1)。具体改动在 [.claude-plugin/manifest.json](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/.claude-plugin/manifest.json:37) 和 [install.sh](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh:160)，避免 `./install.sh install` 在复制完文件后因为检查一个不存在的旧路径而直接失败。README 和变更记录也已同步更新到 [README.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38) 和 [CHANGELOG.md](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:11)。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 临时 `HOME` 安装 smoke test：`./install.sh install` 成功完成，退出码 `0`

未提交，未推送。

### 2026-05-03 10:05

修了一项高置信度的安装链路问题：仓库当前实际把 Interview 阶段说明保存在根目录 [`interview.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/interview.md>)，但 `.claude-plugin/manifest.json` 和 [`install.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh>) 的安装校验还残留旧的 `prompts/interviewer.md` 路径，导致 `./install.sh install` 在复制完文件后直接失败，用户拿到的是一个“缺少关键文件”的假错误。

现在 manifest 已改为声明真实存在的 `interview.md`，安装校验也同步对齐当前目录结构；首次安装和临时 `HOME` 的 smoke test 都能顺利完成，不会再被这个过期路径拦住。[`CHANGELOG.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md>) 也已同步记录这次修复。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 临时 `HOME` 安装 smoke test：`./install.sh install` 现在可完成安装，不再报 `缺少关键文件: prompts/interviewer.md`

未提交，未推送。

### 2026-05-02 13:26

在 [discover-skills.sh](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/discover-skills.sh:93) 我修了 `info/load` 的一个真实可靠性问题。脚本原来用 `find | xargs grep` 定位 skill，当前这类带空格的 checkout 路径里会把合法 skill 误判成不存在；`load` 还会把 `ai-office-landing` 这类带连字符的名字直接拼进 jq 路径，导致状态写入失败。现在已改成空格安全的 `find -print0` 查找，并用 jq 安全键写入状态，[`discover-skills.sh`](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/discover-skills.sh:228)。README 和变更记录也同步更新到了 [`README.md`](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:38)、[`README.md`](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md:239) 和 [`CHANGELOG.md`](/Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md:11)。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- `./discover-skills.sh info ai-office-landing`
- `./discover-skills.sh load designer ai-office-landing`

未提交，未推送。

### 2026-05-02 13:35

修了一项高置信度的脚本可靠性问题：[`discover-skills.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/discover-skills.sh>) 之前在 `info` 和 `load` 子命令里使用 `find | xargs grep` 查找 skill，只要仓库或技能目录路径里带空格，就可能把合法 skill 误判成“不存在”；即便查找成功，`load` 在把 `ai-office-landing` 这类带连字符的 skill 名写回状态时，也会触发 jq 路径错误。当前自动化工作目录本身就带空格，这组问题可以稳定复现。

现在脚本已改成基于 `find -print0` 的安全查找 helper，并在状态写入时对带连字符的 skill 名改用 jq 安全键访问。`discover-skills.sh info ai-office-landing` 和 `discover-skills.sh load designer ai-office-landing` 在包含空格的 checkout、临时目录和桌面同步目录里都能正常工作。[`CHANGELOG.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md>) 也已同步记录本次修复。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- `./discover-skills.sh info ai-office-landing`
- `./discover-skills.sh load designer ai-office-landing`

未提交，未推送。

### 2026-04-29 09:42

实现了一项高置信度的安装体验改进：[`install.sh`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh>) 现在支持 `--force` / `--yes` / `-y`，在已有 `~/.claude/skills/ai-office-landing` 安装时可以无交互覆盖安装；如果在非交互终端里重复安装但没传 `--force`，脚本会直接报错并提示正确命令，不再卡在 `read -p`。这类场景主要对应 CI、脚本化更新和无人值守重装。`reinstall` 也同步走了无交互路径。

README 和文档已同步更新：[`README.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md>) 记录了本次更新并补了无人值守安装说明，[`CHANGELOG.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md>) 加了 `Unreleased` 条目，[`CONTRIBUTING.md`](</Users/aimon/Desktop/claude code test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CONTRIBUTING.md>) 也补了重复安装时的推荐命令。

验证已运行：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- `./install.sh --help`
- 临时 `HOME` 的安装 smoke test：首次 `./install.sh install` 成功；第二次无参数安装在非交互模式下按预期失败并提示 `--force`；随后 `./install.sh install --force` 成功完成覆盖安装

未提交，未推送。

### 2026-04-29 09:40

这次补了一项安装体验改进：`install.sh` 现在支持 `--force` / `--yes`，可以在已有安装目录时跳过交互确认，适合 CI、脚本化更新和其他无人值守场景。之前如果 `~/.claude/skills/ai-office-landing` 已存在，脚本一定会等待 `read -p` 输入；在非交互终端里这既不稳定，也不利于自动化重装。

- [install.sh](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/install.sh) 现在支持 `./install.sh install --force`、`./install.sh install --yes` 和 `./install.sh -y`。
- 如果检测到非交互终端且目标目录已存在，但没有传 `--force`，脚本会立即报错并提示正确命令，而不是卡在覆盖确认上。
- [README.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/README.md)、[CHANGELOG.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CHANGELOG.md) 和 [CONTRIBUTING.md](/Users/aimon/Desktop/claude%20code%20test/.cache/github-autopilot/repos/aimonj0729-ai__ai-office-landing-skill/CONTRIBUTING.md) 已同步更新这次无交互安装说明。

已运行验证：
- `bash -n cost-tracker.sh discover-skills.sh install.sh orchestrator.sh setup-github-repo.sh state-management.sh`
- 临时 `HOME` 安装 smoke test：首次 `./install.sh install` 成功；第二次无参数安装在非交互模式下按预期失败并提示 `--force`；随后 `./install.sh install --force` 成功完成覆盖安装

未提交，未推送。

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

`state-management.sh` 现在也会按字面键名读写 `outputs_status` 和 `user_inputs`，并且对 `pending_questions` / checkpoint 里的自由文本改成了 `jq --arg` 安全写入；像 `design-references`、`brief.md` 这类带连字符或点号的真实任务 ID，以及 `用户说 "hero 文案" 需要更短` 这类带引号的问题文本，都不会再把状态写入流程搞坏。

如果你在扩展工作流、补示例或写自动化脚本，优先复用 `state-management.sh` 里的 helper（例如 `mark_task_completed`、`mark_task_waiting_for_user`、`add_pending_question`、`create_checkpoint`），不要再按旧思路手写 `jq` 去更新 `state.json`。

如果你在 CI、自动化脚本或其他无人值守环境里重复安装这个 skill，直接运行 `./install.sh install --force` 即可跳过覆盖确认；如果目标目录已存在但未传 `--force`，安装脚本会快速失败并提示正确用法，而不会卡在交互输入上。

运行 `./install.sh uninstall` 时，脚本也会同步从 `~/.claude/settings.json` 删除 `ai-office-landing` 的注册，避免卸载后保留一个指向已删除 `SKILL.md` 的失效路径；如果你之前手动删过安装目录，也可以再跑一次 `uninstall` 来清理这条残留配置。

如果 `~/.claude/settings.json` 已被手动改坏成无效 JSON，`install.sh` 现在会在复制文件前直接报错并停止，不会再一边打印 `jq` parse error 一边继续输出“安装成功”。先修复或删除这个损坏的配置文件，再重新执行安装即可。

不要直接执行仓库 raw 链接里的 `install.sh`。这个安装器会读取同目录下的 `.claude-plugin/manifest.json`、`prompts/`、`templates/` 和其他资源文件，必须先拿到完整仓库副本后再运行。

也不要先把仓库解压或克隆到最终安装目录 `~/.claude/skills/ai-office-landing` 再执行安装器。`install.sh` 会把当前 checkout 复制到该目录，所以推荐始终从一个临时 checkout 里运行它。

如果你想保留 `curl` 下载体验，请先下载完整仓库到临时目录，再从 checkout 里安装：

```bash
tmpdir=$(mktemp -d)
cd "$tmpdir"
curl -fsSL -o ai-office-landing-skill.tar.gz https://github.com/aimonj0729-ai/ai-office-landing-skill/archive/refs/heads/main.tar.gz
tar -xzf ai-office-landing-skill.tar.gz
cd ai-office-landing-skill-main
./install.sh
```

如果你使用 `./setup-github-repo.sh` 发布自己的仓库，脚本现在也会在发布成功后直接打印带真实 GitHub owner 的 tarball 和 `git clone` 安装命令，便于把可执行示例原样发给用户。

如果当前机器还没装 `gh`，脚本输出的手动发布回退步骤现在也会直接指向当前 checkout；如先设置 `GITHUB_OWNER=your-name` 或 `REPO_OWNER=your-name`，回退说明里的 `git remote add origin` 也会自动带上真实 owner，减少手工替换。

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

`discover-skills.sh info` 和 `load` 现在也支持 skill 根目录、工作树或临时 checkout 路径中包含空格的场景，并且不会再因为 `ai-office-landing` 这类带连字符的 skill 名在状态写入时失败。

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
