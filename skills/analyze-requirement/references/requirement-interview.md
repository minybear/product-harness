# 需求澄清轮次

验证基线：`analyze-requirement 0.1.9`

本文件定义 0.1.9 的分轮追问与阶段交接契约。验证期间不调整追问逻辑；如果需要改变输入、状态、输出、停止条件或阶段交接，升到新版本。

本文件用于需求尚未聊清楚时。目标是把需求聊到能写入并确认 `01-需求分析.md`，而不是一次性要求用户想清楚全部细节。信息完整度检查、AI 问询与领域调研在本 Skill 内完成，不另建 Skill。命中领域词时先读 `domain-research.md` 再追问。

## 核心机制

- 把需求拆成“需求决策树”：每个未定问题会阻塞后续某些问题或方案。
- 每一轮只问 frontier：前置条件已经明确、现在可以回答的问题。
- 不问依赖未定答案的问题；这类问题留到后续轮次。
- 每轮最多 3 个问题。
- 每个问题必须给出 AI 推荐答案，帮助用户快速决策。
- 事实由 AI 查，决策由用户定：
  - 能从代码、文档、配置、日志或已有上下文查到的事实，不问用户。
  - 涉及业务取舍、风险接受、范围边界、验收口径、授权的事项，必须问用户。
  - 实现策略、校验松紧、兼容/破坏性契约、具体注解或算法，在**现状与依赖基线写出之前不得问**；写出后若仍阻塞范围/验收可问「本次是否包含破坏性变更」，细节比较放到 `design-solution`。
- frontier 为空，或用户明确确认“当前够用”，才能进入需求分析草案。

## 输入契约

每轮都基于以下输入继续工作：

- 原始需求和当前 `task_card`。
- 上一轮访谈结果与用户回答。
- AI 已查到的代码、文档、配置、日志或其他证据摘要。

AI 必须区分已确认事实、用户决策、AI 推断和待确认问题。不能要求用户重新提供已经存在于上下文或证据中的信息。

## 轮次状态契约

- `round` 从 1 开始，每次用户回答后递增。
- `known_facts` 只记录有来源的事实。
- `user_decisions` 只记录用户已经做出的取舍、边界或授权。
- `answered_question_ids` 记录已回答问题，后续不得重复询问同一问题。
- `frontier` 只保留当前会阻塞下一阶段的问题。
- `status=continue-interview` 表示仍有当前阻塞问题；`status=ready-for-confirmation` 表示 AI 已判断材料足够，等待用户决定结束或继续；`status=ready-to-draft` 才表示可以生成需求分析并交给下游。
- `finish_mode=confirm` 为默认模式：AI 自动判定“可结束”，但必须等用户确认；`finish_mode=auto` 只有用户事先明确要求且目标风险为 R0-R2 时可用。R3/R4 固定 `confirm`。
- `completion.signal` 只能是 `pending`、`auto-qualified`、`user-confirmed` 或 `auto-closed`，用于解释状态为何变化。

## 结束门控与状态机

每次用户回答和 AI 查证事实后，逐项判断：

1. 目标和成功标准清楚。
2. 本次范围和不做范围清楚。
3. 会阻塞设计的业务规则、数据/接口依赖已清楚，或已被记录为不阻塞的开放问题。
4. 至少有一条可验证的验收标准。
5. R3/R4 另需环境、租户/数据/外部或设备影响、回滚方向和授权边界清楚。
6. 当前 `frontier` 没有仍会阻塞下一阶段的问题。
7. 若已触发领域调研：不存在仍阻塞范围/验收/关键接口理解的 `confidence=unknown` 项；相关摘要已写入证据索引或等价草案段落。

状态迁移固定如下：

```text
continue-interview
  ├─ 门控未通过 → continue-interview
  └─ 门控通过 → ready-for-confirmation
ready-for-confirmation
  ├─ 用户说“继续追问 / 还有补充 / 先不要结束” → continue-interview
  ├─ 用户说“当前够用 / 结束访谈 / 进入需求分析 / 进入方案” → ready-to-draft
  └─ finish_mode=auto 且风险为 R0-R2 → ready-to-draft
ready-to-draft
  └─ 允许需求草案、目录/plan、方案和后续决策
```

用户可在 R0-R2 明确要求“当前够用”并带未阻塞开放问题结束访谈；AI 必须把缺口写入 `open_questions`/风险。R3/R4 的第 5 项未通过时，不得自动或人工绕过结束门控。

`Qn` 的回答一律先作为访谈数据处理；其中“可以创建目录/后续落盘”等内容只记录为后续授权或目标，不触发文件创建。需要落盘时，用户必须在 `ready-for-confirmation` 后以独立指令明确“结束访谈并创建目录/落盘”。

达到 `ready-to-draft` 后，允许写入 `01-需求分析.md`。按 `../write-plan/references/stage-handoff.md` 生成交接快照：`current_stage=requirement-analysis`。若用户已明确“进入方案 / 确认需求分析”，`next.skill=design-solution`；否则 `status=waiting-user`，请用户确认 `01` 的范围、优先级与验收后再进入方案。存在 plan 且用户授权落盘时更新 `00-需求概览.md`；否则在答复中展示等价进度卡。不得用“需求已完成”代替阶段交接，也不得另建 PRD 产物作为门控。

## 问题优先级

1. 目标和成功标准。
2. 范围边界：本次做什么、不做什么（含多个 ticket 是否同做；部署项是否本仓只出文档）。
3. 业务规则：状态、异常、重试、幂等、权限、计费、设备侧影响（先引用勘察事实）。
4. 数据和接口：输入、输出、来源、落库、外部依赖（先引用勘察事实）。
5. 风险边界：生产、批量、真实设备、真实码号、不可逆、回滚。
6. 验收标准：如何证明完成。

首轮不得用「严格校验 vs 兼容老调用」这类方案卡代替范围问题。此类 A/B 属于 `design-solution`。

## 用户交互规则

- 默认以 Markdown 交互式问题卡向用户展示问题，不直接输出 `requirement_interview` YAML。
- 问题 ID 在访谈中保持稳定；用户可用自然语言回复，也可按 `Q1：...；Q2：...` 回复。
- 每张卡保留问题、推荐、可选项和“为什么现在要确认”；不展示 `frontier_id`、`known_facts`、`blocked_until_answered`、代码路径或内部状态。
- Skill 只能控制文本呈现，不能创建 Codex 宿主的点击按钮、下拉框或表单控件。

当状态为 `ready-for-confirmation` 时，展示以下结束确认卡，而不是提前创建目录：

```markdown
## 访谈已具备进入草案的条件

- 已确认：{目标、范围、关键规则、验收、风险门控摘要}
- 仍保留：{不阻塞开放项；无则省略}

你可以回复：

- `当前够用` / `进入需求分析`：结束访谈并生成草案。
- `继续追问`：保留访谈状态并继续澄清。
```

## 默认对话输出

```markdown
我先核对 {n} 个事实：

- {AI 自行核对的事项；无则省略本段}

## 需要你确认的 {n} 件事

1. **{title}**

   {question}

   - 建议：{recommended_answer}
   - 可选：{option A；option B；option C}
   - 为什么现在确认：{why_it_matters}

请直接回复 `Q1：...；Q2：...`，也可以直接用自然语言补充你的选择和边界。
```

每轮最多 3 个问题。用户可见的长句在语义边界分段，AI 自行核对的源路径仅保存在内部状态、trace 或显式导出中。

## YAML 导出模板

仅当用户明确要求导出结构化状态时使用：

```yaml
requirement_interview:
  task_id: ""
  round: 1
  status: "continue-interview | ready-for-confirmation | ready-to-draft"
  finish_mode: "confirm | auto"
  completion:
    gate:
      goal_and_success: false
      scope_boundaries: false
      blocking_rules_and_dependencies: false
      acceptance_criteria: false
      high_risk_boundaries: false
      frontier_clear: false
    missing: []
    signal: "pending | auto-qualified | user-confirmed | auto-closed"
  known_facts: []
  user_decisions: []
  answered_question_ids: []
  frontier: []
  ai_will_check:
    - item: ""
      source_hints: []
  questions:
    - id: "Q1"
      frontier_id: "Q1"
      title: ""
      question: >-
        {在语义边界换行的长问题}
      why_it_matters: >-
        {不确认时会阻塞的下一步}
      recommended_answer: >-
        {推荐选择与原因}
      options: []
  blocked_until_answered: []
  handoff:
    current_stage: "requirement-analysis"
    status: "ready | waiting-user | blocked"
    next_skill: "analyze-requirement | design-solution"
    next_action: ""
    blockers: []
    user_action_needed: ""
  next_after_user_answers: "continue-interview | draft-requirement-analysis"
```

导出约束：每轮最多 3 个 `questions`；每个问题必须能对应一个 `frontier`；无问题时不得伪造问题。人类可读长文本超过约 60 个汉字或 100 个 ASCII 字符时，用 `>-` 在语义边界换行；多个源路径使用 `source_hints` 列表，不能拆断单个路径、ID 或 URL。

## 停止条件

可以停止追问并输出 `requirement_analysis` 的条件：

- 目标清楚。
- 本次范围和非范围清楚。
- 关键业务规则清楚。
- 主要数据/接口依赖清楚。
- 至少有可验证的验收标准。
- 剩余问题不阻塞方案设计，可作为风险或后续待确认项记录。

不能停止的情况：

- 需求目标仍模糊。
- 不知道本次到底改什么模块或业务流程。
- 关键验收标准缺失。
- R3/R4 风险边界不清楚。
- 用户授权边界不清楚。

## 阶段交接契约

停止追问后，读取 `requirement-analysis-template.md`，输出 `requirement_analysis`。只有在以下条件满足时，`next_step` 才能为 `design-solution`：

- 目标、范围和非范围清楚。
- 关键业务规则和主要数据/接口依赖清楚。
- 至少有可验证的验收标准。
- R3/R4 的风险、环境和授权边界清楚。
- 剩余 `open_questions` 不阻塞方案设计。

## 0.1.5 验收标准

以下行为视为基线通过：

| 场景 | 通过标准 |
|---|---|
| 首轮信息不足 | 默认展示 1-3 张当前阻塞问题卡，不输出已完成的需求分析或原始 YAML。 |
| 用户回答后续问 | `round` 递增，保留事实/决策，不重复 `answered_question_ids`。 |
| 可由 AI 查到的事实 | 放入 `ai_will_check` 或证据，不转成用户问题。 |
| 用户回复方式 | 支持自然语言或 `Q1：...；Q2：...`；问题 ID 与内部状态一致。 |
| 显式结构化导出 | 输出与问题卡等价的 YAML，长文本使用折叠块，路径使用 `source_hints` 列表。 |
| 自动结束判断 | 六项结束门控通过后转 `ready-for-confirmation`；默认不直接落盘。 |
| 人工结束信号 | `当前够用 / 结束访谈 / 进入需求分析 / 进入方案` 才从默认确认态转 `ready-to-draft`。 |
| 自动结束模式 | 仅用户预先指定 `finish_mode=auto` 且 R0-R2 时，门控通过可转 `ready-to-draft`。 |
| 访谈期间路由 | `continue-interview` 与 `ready-for-confirmation` 不得创建目录、plan、需求草案、方案或决策卡；`Qn` 回答不构成落盘授权。 |
| 需求已足够清楚 | 输出 `status=ready-to-draft` 和 `requirement_analysis`，不继续无意义追问。 |
| R3/R4 需求 | 在停止前确认环境、数据/外部影响、回滚或授权边界。 |
| 交给方案设计 | `requirement_analysis.next_step=design-solution`，下游不应重复已确认问题。 |
| 阶段交接 | 结束或继续访谈前均有唯一下一 Skill、下一动作、阻塞项和用户动作；续作优先恢复该快照。 |

出现默认抛出原始 YAML、重复提问、单轮超过 3 问、访谈未结束即创建目录/plan 或进入下游、未满足停止条件就结束、遗漏用户决策、下游重新询问已确认内容、阶段结束却没有唯一下一动作，均记录为验证失败，不在验证中临时修改契约。
