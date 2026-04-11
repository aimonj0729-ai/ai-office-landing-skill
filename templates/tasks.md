---
version: v1
derived_from: brief.md v1 + style-tokens.md v1
created: <ISO timestamp>
---

# Task List — <项目名>

> 这份文件由 Brief Keeper 在 Phase 2 生成。
> 每个 task 对应 Phase 3 的一个 Executor。
> **每个 task 必须包含 `adapter:` 字段**(v1 固定填 `claude-agent`,v1.5 后可切换)。

---

## Task 1: Copywriting

### Metadata
| key | value |
|---|---|
| **task** | `copywriter` |
| **adapter** | `claude-agent` |
| **role_prompt** | `~/.claude/skills/ai-office-landing/prompts/copywriter.md` |
| **output_path** | `/ai-office/outputs/copy.md` |
| **depends_on** | brief.md, style-tokens.md |

### Acceptance Criteria

**Given** 已读 `brief.md` 和 `style-tokens.md`
**When** 我按情绪和语气词汇写文案
**Then** 必须满足:

- [ ] **Hero 区**:1 句主标题 + 1 句副标题 + 1 个 CTA 按钮文案
  - 主标题 ≤ 8 字,副标题 ≤ 20 字
  - 对准 brief 的"一句话定义"
  - CTA 文案对准 goal 的"最主要转化动作"

- [ ] **Features 区**:3-5 个 feature 卡片
  - 每个卡片:标题(≤6 字) + 描述(1-2 句) + 可选小标签
  - 内容来自 brief 的"核心卖点"和"差异化"
  - 不用形容词,用具体动词和名词

- [ ] **FAQ 区**:3-5 组问答
  - 问题用访客口吻,不要"官方 FAQ"腔
  - 答案对准 brief 的"产品定义"和"必须出现的内容"
  - 每答案 ≤ 100 字

- [ ] **CTA 区**:1 句行动召唤 + 按钮文案
  - 对准 goal,和 Hero 区 CTA 呼应
  -  urgency 词慎用(如"限时"),除非 brief 明确说了时间窗

- [ ] **整体**:全文不出现禁用词;出现推荐词 ≥ 3 次;语气统一

- [ ] **Gap 标记**:遇到 brief 没写的信息(如具体数字、引语),用 `[GAP: 需要什么]` 标注,**不要编造**

---

## Task 2: Design Specification

### Metadata
| key | value |
|---|---|
| **task** | `designer` |
| **adapter** | `claude-agent` |
| **role_prompt** | `~/.claude/skills/ai-office-landing/prompts/designer.md` |
| **output_path** | `/ai-office/outputs/design-spec.md` |
| **depends_on** | brief.md, style-tokens.md (copy.md optional - only for length reference if available)|

### Acceptance Criteria

**Given** 已读 `brief.md`, `style-tokens.md` (也可参考 copy.md 的大致长度)
**When** 我输出设计规范文档
**Then** 必须包含:

#### Layout (布局)
- [ ] **Hero 区**:
  - 版面密度(留白占比)对准 brief 的"版面密度倾向"
  - 主视觉位置(左文右图 / 全屏背景 / 居中)
  - 垂直间距(从 `space-16` 到 `space-24` 选)

- [ ] **Features 区**:
  - 网格结构(3 列 / 4 列 / 交替左右)
  - 卡片样式(有无边框 / 有无图 / 有无阴影)
  - 每个 card 内部:图高、标题区高、描述区高

- [ ] **FAQ 区**:
  - 折叠展开交互 or 平铺列表
  - 问题与答案的缩进/字号区分
  - 最大宽度(从 `container-narrow` 选)

- [ ] **CTA 区**:
  - 背景样式(纯色 / 渐变 / 图背景)
  - 按钮样式(主按钮尺寸、圆角、阴影)
  - 紧急感设计(如有 time-based goal)

#### Spacing & Rhythm (间距与节奏)
- [ ] 所有间距引用 `style-tokens.md` 的 token,**不要 hardcode px**
- [ ] 垂直节奏统一:section 之间间隔一致(如都用 `space-24`)
- [ ] 组件内节奏:card padding、元素间距引用 token

#### Component Specs (组件规格)
对每个组件(按钮、卡片、输入框、标签)给出:
- [ ] **尺寸**:宽、高、padding(引用 token)
- [ ] **颜色**:bg/border/text color(引用 `color-*` token)
- [ ] **字号**:引用 `text-*` token
- [ ] **交互**:hover / active 态变化(颜色、阴影、位移)
- [ ] **状态**:disabled / loading 态(如有)

#### Responsiveness (响应式)
- [ ] 桌面端断点:≥ `bp-lg` (1024px)
- [ ] 平板断点: `bp-md` (768px) 到 `bp-lg` 
- [ ] 移动端断点: < `bp-md`
- [ ] 每个断点下:网格变化(如 4 列→2 列→1 列)、字号降级(如 `text-display` 48px→36px→28px)

#### Accessibility (无障碍)
- [ ] 颜色对比度:所有文本 vs 背景 ≥ 4.5:1 (WCAG AA)
- [ ] 焦点顺序:tab 顺序从左到右、从上到下
- [ ] 语义标签:按钮用 `<button>`,导航用 `<nav>` 等

---

## Task 3: Frontend Implementation

### Metadata
| key | value |
|---|---|
| **task** | `frontend` |
| **adapter** | `claude-agent` |
| **role_prompt** | `~/.claude/skills/ai-office-landing/prompts/frontend.md` |
| **output_path** | `/ai-office/outputs/index.html` |
| **depends_on** | brief.md, style-tokens.md, design-spec.md (copy.md optional - use if available, but component can render with placeholder content) |

### Acceptance Criteria

**Given** 已读 `brief.md`, `style-tokens.md`, `design-spec.md`, `copy.md`
**When** 我输出 HTML/CSS 代码
**Then** 必须满足:

#### Code Quality
- [ ] **语义化 HTML5**:正确使用 `<header>`, `<section>`, `<main>`, `<footer>`, `<nav>` 等
- [ ] **样式隔离**:所有样式用 class 选择器,**不要写全局标签样式**(如 `h1 { ... }` 是不允许的)
- [ ] **CSS 变量**:所有颜色、字号、间距必须引用 `style-tokens.md` 里定义的 CSS 变量(token 名保持一致)
- [ ] **无内联样式**:`<div style="...">` 是不允许的
- [ ] **无 !important**:所有样式优先级靠选择器,不靠 `!important`

#### Structure
- [ ] **文件自包含**:单个 `.html` 文件,内嵌 `<style>` 和 `<script>`(如有)
- [ ] **Meta 完整**:包含 viewport, charset, title(从 brief goal 取)
- [ ] **区块完整**:Hero / Features / FAQ / CTA 四个区都存在,顺序和 design-spec 一致
- [ ] **导航**:如有锚点导航,用 `<nav>` 包裹,链接指向对应 section id

#### Style Implementation
- [ ] **颜色 100% token 合规**:检查所有 `color`, `background-color`, `border-color` 是否都引用了 `--color-*` 变量
- [ ] **字号 100% token 合规**:所有 `font-size` 引用 `--text-*` 变量
- [ ] **间距 100% token 合规**:所有 `margin`, `padding`, `gap` 引用 `--space-*` 变量
- [ ] **圆角 token 合规**: `border-radius` 引用 `--radius-*` 变量
- [ ] **动效(如有)**:引用 `--duration-*` 和 `--easing-*` 变量

#### Content
- [ ] **文案**:HTML 里的文字和 `copy.md` 完全一致(允许微小调整以适应 HTML 结构)
- [ ] **CTA 按钮**:文案对准 goal,链接用 `#` 占位(或 brief 指定的真实链接)
- [ ] **图片**:用占位图(svg data-uri 或 placeholder.com),不要自己编真实图片 URL

#### Responsiveness
- [ ] **断点实现**:CSS 里包含 `@media (min-width: var(--bp-sm))` 等断点规则
- [ ] **网格响应**:Features 区在 mobile 下变为 1 列
- [ ] **字号降级**:Hero 标题在 mobile 下引用更小的 token(如 `text-h1` 代替 `text-display`)

#### Accessibility
- [ ] **按钮可访问**:所有 `<button>` 有 `aria-label`(如无文字)或明确文字
- [ ] **图片 alt**:所有 `<img>` 有 `alt` 描述(或空 alt 如果是装饰图)
- [ ] **键盘导航**:所有交互元素(按钮、链接)可通过 Tab 键到达
- [ ] **颜色对比**:文本颜色 vs 背景对比度 ≥ 4.5:1

#### Gap 标记
- [ ] **遇到未定义的 token**:如果 design-spec 里用了 tokens 里不存在的值,用 `[GAP: style-tokens.md 缺少 token X]` 标注,不要硬编码
- [ ] **遇到未定义的文案**:如果 copy.md 没提供某段必需文案,用 `[GAP: copy.md 缺 XXX]` 标注

---

## Task 4: SEO & Meta

### Metadata
| key | value |
|---|---|
| **task** | `seo` |
| **adapter** | `claude-agent` |
| **role_prompt** | `~/.claude/skills/ai-office-landing/prompts/seo.md` |
| **output_path** | `/ai-office/outputs/meta.md` |
| **depends_on** | brief.md, copy.md (optional) |

### Acceptance Criteria

**Given** 已读 `brief.md`, `copy.md`
**When** 我输出 SEO 元数据文档
**Then** 必须包含:

#### Meta Tags
- [ ] **title**: ≤ 60 字符,包含核心关键词,对准 goal
- [ ] **description**: ≤ 160 字符,概括页面内容,吸引点击,来自 Hero 副标题或核心卖点
- [ ] **viewport**: `width=device-width, initial-scale=1`
- [ ] **charset**: `utf-8`
- [ ] **canonical**: 如果 brief 指定了主 URL,给出 canonical 链接

#### Open Graph (OG)
- [ ] **og:title**: 同 title 或稍作变体
- [ ] **og:description**: 同 description
- [ ] **og:type**: `website`
- [ ] **og:url**: 如 brief 给了落地页 URL,填写;否则用 `[GAP]`
- [ ] **og:image**: brief 若有指定社交分享图,填写;否则写推荐尺寸(1200×630)和占位建议

#### Twitter Card
- [ ] **twitter:card**: `summary_large_image`
- [ ] **twitter:title**: 同 OG title
- [ ] **twitter:description**: 同 OG description
- [ ] **twitter:image**: 同 OG image

#### Schema.org (JSON-LD)
- [ ] **@context**: `https://schema.org`
- [ ] **@type**: 根据 brief 选 `Product`, `Organization`, `WebPage` 等
- [ ] 必要字段:
  - `name`: 产品/组织名
  - `description`: 简短描述
  - `url`: 落地页 URL
  - 如 type=Product: `offers` (至少 placeholder)
  - 如 type=Organization: `logo` (尺寸建议)

#### Keywords (可选)
- [ ] 5-10 个核心关键词,来自 brief 的 product 定义和差异化
- [ ] 不堆砌,每个词在页面内容里真实出现

#### Accessibility & Performance
- [ ] **lang**: `<html lang="zh-CN">` (或 brief 指定的语言)
- [ ] **alt 文本**:为所有占位图提供 alt 描述建议
- [ ] **字体加载**:如用了 web font,给出 `font-display: swap` 建议

---

## Task 5: Critic Review

### Metadata
| key | value |
|---|---|
| **task** | `critic` |
| **adapter** | `claude-agent` |
| **role_prompt** | `~/.claude/skills/ai-office-landing/prompts/critic.md` |
| **output_path** | `/ai-office/critique.md` |
| **depends_on** | brief.md, style-tokens.md, outputs/* |
| **critical_requirement** | **必须是独立 Agent,不继承主控上下文** |

### Acceptance Criteria

见 `/Users/aimon/.claude/skills/ai-office-landing/critic-checklist.md` 的核查清单 + 输出格式章节。

---

## Task Schema Validation

每个 task 必须包含以上所有字段。Brief Keeper 生成时:

1. **校验**:用脚本或手动检查每个 task 有 `adapter:` 字段
2. **默认值**:v1 所有 `adapter` 填 `claude-agent`
3. **扩展性**:v1.5 支持 `kimi-api`, `deepseek-api` 时,直接改这个字段即可,无需改 SKILL.md 主流程
