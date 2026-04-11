# Decision Log — <项目名>

> **Append-only.** 每次 phase 转换、每次 Critic 修复决策、每次恢复中断都要追加一条。
> 不要编辑或删除已有条目。修正错误时追加一条新条目说明。
>
> 格式:一条 = 一个 H2 + 元数据表 + 正文。

---

## [YYYY-MM-DD HH:MM] Phase 1 — Brief v1 locked

| key | value |
|---|---|
| phase | 1 → 2 |
| actor | Brief Keeper (main Claude) |
| brief_version | v1 |
| mode | full-claude |

**What happened:**
- 完成 5 维度结构化访谈,用了 1 批 `AskUserQuestion`(5 题)。
- 生成 `brief.md` v1,覆盖度: goal ✅ / audience ✅ / product ✅ / style ✅ / constraints ✅
- 未解决项: [GAP: 社会证明素材], [GAP: 品牌既有配色]
- 决定跳过第二批追问,理由: 5 维度各已获至少 1 条具体答案,达成"足够好"判据

**Next:** Phase 2 — 生成 style-tokens + tasks

---

## [YYYY-MM-DD HH:MM] Phase 2 — Tasks + Style Tokens generated

| key | value |
|---|---|
| phase | 2 → 3 |
| actor | Brief Keeper |
| brief_version | v1 |
| mode | full-claude |

**What happened:**
- 从 brief "克制 / 手作感 / 温暖" 情绪词转译为具体令牌: 主色 `#3A2618`, 副色 `#D4A574`, 字体 `Noto Serif SC + Inter`, ...
- 生成 4 个 task,全部 `adapter: claude-agent`
- 成本预估: Phase 3 将触发 4 次 Agent + Phase 4 将触发 1 次 Critic Agent

**Next:** Phase 3 — 并行执行 4 个 Executor

---

## [YYYY-MM-DD HH:MM] Phase 3 — Parallel executors completed

| key | value |
|---|---|
| phase | 3 → 4 |
| actor | main Claude (dispatcher) |
| brief_version | v1 |
| mode | full-claude |
| adapter_used | claude-agent (all 4) |

**What happened:**
- 并行触发 Copywriter / Designer / Frontend / SEO 4 个 Executor(单条消息 4 个 Agent 调用)
- 产出: outputs/copy.md, outputs/design-spec.md, outputs/index.html, outputs/meta.md
- Gap 标记: Copy 1 处, Design 0 处, Frontend 2 处, SEO 0 处

**Next:** Phase 4 — 独立 Critic 审查

---

## [YYYY-MM-DD HH:MM] Phase 4 — Critic review + integration

| key | value |
|---|---|
| phase | 4 → 5 |
| actor | Critic Agent (independent) + Integrator (main Claude) |
| brief_version | v1 |

**Critic findings:**
- CRITICAL: 1 (A1: Copy 编造了"10k+ 用户"数字)
- HIGH: 2 (B3: Frontend 2 处使用了 tokens 之外的颜色值)
- MEDIUM: 3
- LOW: 1

**Integrator decisions:**
- 修复 CRITICAL × 1: 删除 Copy Hero 第 2 行编造数字,改为 [GAP]
- 修复 HIGH × 2: 替换 Frontend 的 off-token 颜色
- 跳过 MEDIUM × 1: D2 缺阴影定义 — 本次设计不需要阴影
- 记录 MEDIUM × 2: 留到 v2 处理

**Next:** Phase 5 — 终审交付

---

## [YYYY-MM-DD HH:MM] Phase 5 — Delivered

| key | value |
|---|---|
| phase | 5 (done) |
| actor | main Claude |

**Deliverables:**
- `<project>/ai-office/outputs/index.html`
- `<project>/ai-office/outputs/copy.md`
- `<project>/ai-office/outputs/design-spec.md`
- `<project>/ai-office/outputs/meta.md`

**Remaining gaps (for user follow-up):**
- [GAP: 社会证明素材]
- [GAP: 品牌既有配色]
- [GAP: Hero 区英雄图素材]

---

## Conventions

- **Timestamp**: ISO-like `YYYY-MM-DD HH:MM`,本地时区即可。
- **mode 取值**: `full-claude` | `mixed-routing` | `human-critic`
- **phase 取值**: `1 → 2`, `2 → 3`, `3 → 4`, `4 → 5`, `5 (done)`, `resume-from-<phase>`
- **恢复中断时追加**: 专门写一条 `## [timestamp] Resume from Phase N`,说明磁盘状态、跳过了哪些步骤、为什么。
- **Phase 3 部分失败时**: 追加 `## [timestamp] Phase 3 partial failure`,列出成功/失败的 Executor 和原因,**不要回滚任何已成功产物**。
