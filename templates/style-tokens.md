---
version: v1
derived_from: brief.md v1
created: <ISO timestamp>
---

# Style Tokens — <项目名>

> **所有值必须是具体的 hex / px / rem / 字体名。**
> **禁止出现形容词**("温暖""现代""克制"这些属于 Brief,不属于 tokens)。
> Brief Keeper 从 brief.md 的 style 维度转译而来。
> Executor 和 Critic 都以此为唯一标准;off-token 的硬编码值会被 Critic 标 CRITICAL。

---

## 1. 颜色 (colors)

### 主色系 (brand)
| token | value | 用途 |
|---|---|---|
| `color-brand-primary` | `#3A2618` | 主按钮、品牌强调、logo 区 |
| `color-brand-primary-hover` | `#2A1810` | 主按钮 hover |
| `color-brand-accent` | `#D4A574` | 次要强调、高亮数字、icon |

### 中性色阶 (neutral,至少 5 级)
| token | value | 用途 |
|---|---|---|
| `color-neutral-0` | `#FFFFFF` | 背景最浅 |
| `color-neutral-50` | `#FAF8F5` | 次要背景、section 交替底 |
| `color-neutral-200` | `#E5DFD5` | 分隔线、禁用描边 |
| `color-neutral-500` | `#8B8378` | 次要文本、辅助信息 |
| `color-neutral-900` | `#1A1713` | 主文本 |

### 语义色 (optional,只在需要时填)
| token | value | 用途 |
|---|---|---|
| `color-success` | `#2F7A4E` | 成功态、完成 |
| `color-warning` | `#B88A2E` | 警告、注意 |
| `color-error` | `#A83232` | 错误、删除 |

---

## 2. 字体 (typography)

### 字族 (family)
| token | value |
|---|---|
| `font-family-serif` | `"Noto Serif SC", "Source Han Serif", Georgia, serif` |
| `font-family-sans` | `"Inter", "PingFang SC", -apple-system, sans-serif` |
| `font-family-mono` | `"JetBrains Mono", Menlo, Consolas, monospace` |

**默认正文字族:** `font-family-serif`
**默认 UI / 数字字族:** `font-family-sans`

### 字号层级 (scale,至少 4 级)
| token | size | line-height | weight | 用途 |
|---|---|---|---|---|
| `text-display` | `48px` | `1.15` | `700` | Hero 主标题 |
| `text-h1` | `32px` | `1.25` | `700` | 区块主标题 |
| `text-h2` | `24px` | `1.3` | `600` | 子标题 |
| `text-body` | `16px` | `1.6` | `400` | 正文 |
| `text-caption` | `13px` | `1.5` | `400` | 辅助说明、label |

### 字重 (weights)
- regular: `400`
- medium: `500`
- semibold: `600`
- bold: `700`

---

## 3. 间距 (spacing)

**基础单位:** `4px`(所有间距必须是它的整数倍)

| token | value | 典型用途 |
|---|---|---|
| `space-1` | `4px` | 相邻图标和文字 |
| `space-2` | `8px` | 小组件内边距 |
| `space-3` | `12px` | |
| `space-4` | `16px` | 段落间距 |
| `space-6` | `24px` | 组件间距 |
| `space-8` | `32px` | |
| `space-12` | `48px` | 区块内垂直节奏 |
| `space-16` | `64px` | 区块之间 |
| `space-24` | `96px` | 大区块之间(如 Hero → Features) |

**容器最大宽度:**
- `container-narrow`: `680px` (窄正文)
- `container-default`: `1080px` (默认)
- `container-wide`: `1280px` (宽屏展示)

---

## 4. 圆角 (radius)

| token | value | 用途 |
|---|---|---|
| `radius-none` | `0px` | |
| `radius-sm` | `4px` | 小按钮、tag |
| `radius-md` | `8px` | 卡片、输入框 |
| `radius-lg` | `16px` | 大卡片、modal |
| `radius-full` | `9999px` | 圆形头像、胶囊按钮 |

---

## 5. 阴影 (shadow)

| token | value | 用途 |
|---|---|---|
| `shadow-none` | `none` | |
| `shadow-sm` | `0 1px 2px rgba(26, 23, 19, 0.05)` | 细微抬起 |
| `shadow-md` | `0 4px 12px rgba(26, 23, 19, 0.08)` | 卡片悬浮 |
| `shadow-lg` | `0 12px 32px rgba(26, 23, 19, 0.12)` | modal / popover |

---

## 6. 动效 (motion,optional)

| token | value | 用途 |
|---|---|---|
| `duration-fast` | `150ms` | hover / 按钮响应 |
| `duration-base` | `250ms` | 一般过渡 |
| `duration-slow` | `400ms` | 区块切换 |
| `easing-standard` | `cubic-bezier(0.4, 0, 0.2, 1)` | 默认缓动 |

---

## 7. 断点 (breakpoints)

| token | value | 用途 |
|---|---|---|
| `bp-sm` | `640px` | 手机横屏以上 |
| `bp-md` | `768px` | 平板 |
| `bp-lg` | `1024px` | 桌面 |
| `bp-xl` | `1280px` | 大屏 |

---

## 8. 语气词汇 (voice,这是文案约束,不是视觉)

> 这一节是给 Copywriter 的硬约束。虽然不是 CSS token,但同样"可验证":
> Critic 会检查 outputs/copy.md 有没有出现禁用词、是否落在推荐词范围内。

**推荐词 (来自 brief):**
- <从 brief style 维度里抽:例 克制 / 手作 / 产地 / 原生 / 慢>

**禁用词:**
- <例:震撼 / 爆款 / 限时 / !!! / 速溶 / 便宜>

**称呼:**
- <例:用"你",不用"您",不用"亲"、"小伙伴">

**句长倾向:**
- <例:短句为主,最长不超过 20 字;避免四字成语堆砌>

---

## 转译规则(Brief Keeper 工作流)

生成这份文件时,Brief Keeper 必须:

1. **读 brief.md 的 style 维度**,抽出所有情绪词和参考链接
2. **对每个情绪词,做一次"可执行翻译"**,例:
   - "克制" → 低饱和配色 + 大字号克制(不超过 48px)+ 大量留白(section 间距 ≥ 96px)
   - "手作感" → 衬线字体 + 暖中性色 + 不规则排版 + 少用大阴影
   - "专业" → 基础字号 16px + 高对比度文本色 + 使用明确的层级
3. **遇到完全不能转译的词,标 `[GAP: 情绪词 "XX" 无法转译为具体值,需要用户给参考]`**,不要瞎填
4. **引用 brief 里的既有规范**(如果有 logo / 品牌色 / 字体),直接采用,不要自己再设计一遍
