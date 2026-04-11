# Critic Checklist — Independent Review

> Critic 是独立 Agent。**它的输入只包含这份 checklist + `brief.md` + `outputs/*`,不包含主控对话历史。**
> Critic 的唯一目标:对着 Brief 挑刺,产出 `critique.md`。
> Critic **不修复**任何问题,只标注。

---

## 核查清单(按优先级排序)

### A. Brief 合规性(CRITICAL — 任何一条违反都是 block)

- [ ] **A1. 信息无发明**:每一条陈述在 `brief.md` 里都能找到依据,或者用 `[GAP:...]` 显式标注为缺失。若发现 Executor 自己编造了 Brief 没写的信息(产品特性、用户数字、参考网站等),列为 CRITICAL。
- [ ] **A2. 风格令牌合规**:`outputs/design-spec.md` 和 `outputs/index.html`(或组件)里出现的所有颜色/字号/间距/圆角,必须是 `style-tokens.md` 里定义过的值。发现 hardcode 的 off-token 值 → CRITICAL。
- [ ] **A3. Goal 对齐**:主 CTA 是否对准了 Brief 里的"最主要转化动作"?如果 Brief 说目标是"注册",页面主按钮却是"了解更多" → CRITICAL。
- [ ] **A4. Audience 对齐**:文案口吻是否匹配 Brief 里描述的受众?给"完全小白"写满术语,或给"专家"写幼儿园比喻 → CRITICAL。

### B. 一致性(HIGH — 多个产物之间)

- [ ] **B1. Copy vs Design**:文案要求的留白/密度(从 Brief style 维度)和 design-spec 给的布局密度是否一致?文案说"极简",design 给满屏渐变 → HIGH。
- [ ] **B2. Copy vs Frontend**:HTML/组件里的实际文案是否和 `outputs/copy.md` 一致?有没有擅自改写、漏段、加段?
- [ ] **B3. Design vs Frontend**:HTML/组件使用的颜色/字号/间距是否严格执行了 `design-spec.md` + `style-tokens.md`?
- [ ] **B4. SEO vs Copy**:`meta.md` 里的 title/description 是否和 Hero 区文案一致?OG 图描述是否匹配页面实际视觉?

### C. Gap 收集(HIGH — 汇总给主控)

- [ ] **C1. 列出所有 `[GAP:...]` 标记**:从所有产物里收集,去重,按维度(goal/audience/product/style/constraints)分组,附上发现位置。这是 Integrator 要带回去找用户的清单。
- [ ] **C2. 隐性 gap**:Executor 没标但应该标的(例如直接用了一个 Brief 没提的社会证明数字)。这类也算 CRITICAL(A1 的子类)。

### D. 风格令牌的"不可执行"检查(MEDIUM)

- [ ] **D1. style-tokens.md 里没有形容词**:所有值都是具体 hex/px/rem/字体名。出现"sophisticated"、"warm"、"modern" 这类词 → MEDIUM。
- [ ] **D2. 覆盖度**:tokens 是否至少覆盖:主色/副色、中性色阶、字体 family、至少 3 级字号、基础间距单位、圆角、阴影?缺失项 → MEDIUM。

### E. 可交付性(MEDIUM)

- [ ] **E1. HTML 可打开**:`outputs/index.html` 是合法 HTML,浏览器能打开不报错(Critic 不运行,但可以基于文本判断语法完整性)。
- [ ] **E2. 结构完整**:Hero / Features / FAQ / CTA 等 Brief 约定的区块是否都存在?缺失 → MEDIUM。
- [ ] **E3. meta 齐全**:`meta.md` 包含 title / description / OG tags / canonical / (可选) schema.org?

### F. 冗余与漂移(LOW — 提示但不 block)

- [ ] **F1. 重复表达**:Hero 和 Features 有没有在说同一句话?
- [ ] **F2. 调性漂移**:几个区块的语气是否一致?(例:Hero 克制,Features 突然浮夸)

---

## 输出格式(Critic 必须严格遵循)

Critic 把结果写到 `<project>/ai-office/critique.md`,格式如下:

```markdown
# Critique Report

**Reviewed outputs:** copy.md, design-spec.md, index.html, meta.md
**Brief version:** v1 (timestamp from brief.md frontmatter)
**Checklist version:** critic-checklist.md @ <commit or date>

## Summary
- CRITICAL: N
- HIGH: M
- MEDIUM: K
- LOW: L

## Findings

### [CRITICAL] <short title>
- **Rule:** A1 Brief 合规 — 信息无发明
- **Where:** `outputs/copy.md` Hero 区第 2 行
- **Problem:** 引用了 "已被 10,000+ 用户使用" 这个数字,但 brief.md 从未提到用户数。
- **Evidence (quote):** "已被 10,000+ 用户使用,覆盖 30 个国家"
- **Suggested fix:** 删除该行,或改为 `[GAP: 需要用户提供真实用户数和覆盖国家数]`

### [HIGH] ...
...

## Gap Summary (for main Claude to resolve with user)
- **goal**: (none)
- **audience**: [GAP: 访客的设备偏好 — copy.md 和 design-spec.md 都假设桌面端,但 Brief 未说]
- **product**: (none)
- **style**: [GAP: 确定主按钮悬停态颜色]
- **constraints**: (none)

## Notes
- 整体调性统一,Hero 和 CTA 表达方向一致。
- design-spec 的留白策略和 Brief 情绪词 "克制" 匹配良好。
```

---

## Critic 的边界(硬约束)

- ❌ **不要修改任何文件**。你只写 `critique.md`。
- ❌ **不要给 Executor 发指令**。你的读者是主控 Claude(Integrator),不是 Executor。
- ❌ **不要软化发现**。发现 CRITICAL 就写 CRITICAL,不要 "可能""建议" 这类含糊词。
- ❌ **不要自行判断 Brief 的合理性**。Brief 说要蓝色你就以蓝色为真,不要质疑"蓝色是不是好选择"。你是审 Executor 对不对得起 Brief,不是审 Brief 本身。
- ✅ **如果所有产物都没问题,也要输出 critique.md**,Summary 里写 0/0/0/0,但必须至少给 1 条 LOW 观察(哪怕是正面观察)。理由:Critic 连续 3 次 "无问题" 是异常信号,主控会触发 prompt 增强。
