# 需求分析输出模板

仅在需要输出结构化需求分析草案，或写入 `01-需求分析.md` 时读取本文件。

本项目用 `01-需求分析.md` 作为需求阶段人工确认基线，不另产 `docs/PRD.md`，也不依赖独立 PRD Skill。

## 默认可读草案

默认以 Markdown 输出需求分析草案。**必出且前置**的只有：背景与目标、现状与依赖、范围、验收标准；其余章节仅在需求确有必要时追加。做过现状勘察（含领域调研）时，**必须追加证据索引**。不要把内部状态、长路径或 YAML 原样抛给用户。

草案或落盘后，若用户尚未明确“进入方案 / 确认需求分析”，下一动作应是请用户确认范围、优先级与验收口径，而不是直接开始写方案。

仅当用户明确要求“导出 YAML / 原始分析状态 / 供工具消费 / 写入结构化文件”时，使用下方 YAML。

## YAML 导出

```yaml
requirement_analysis:
  status: "ready-to-draft | waiting-confirmation | confirmed"
  title: ""
  product: "已登记的唯一主产品，如 common | example-app"
  product_touchpoints: []
  task_type: "feature | bugfix | investigation | refactor | test | doc | config | data | release | incident"
  # 必填
  goal: ""
  in_scope: []
  out_of_scope: []
  acceptance_criteria: []
  current_state_and_dependencies:
    affected_scope: []       # 受影响模块/服务/代码落点
    current_state: ""        # 现有实现 / 是否已有实现
    dependency_list: []      # 依赖现有能力 + 波及下游
    fe_be_interaction: ""    # 前端/UI 层、配置前端入口
  # 以下按需；无内容则省略字段或置空数组
  confirmed_facts: []
  user_decisions: []
  actors: []
  user_scenarios: []
  business_rules: []
  data_objects: []
  interfaces: []
  non_functional_requirements: []
  config_and_frontend_entry:
    applies: false
    # applies=true 时必填 decision；涉及运行配置/开关/阈值即应评估
    decision: "new-entry | extend-existing-page | ops-only | not-applicable"
    entry_scope: ""          # 如需或扩展现有页：由该项目适配器/局部规则提供
    config_keys: []          # 配置键/命名空间（形态由技术栈决定）
    rationale: ""            # 为何需要/不需要前端入口
    scoped_by_tenant: false  # 是否按租户/环境分域编辑
  open_questions: []
  risks: []
  domain_research:
    triggered: false
    terms: []
    # 命中后按 domain-research.md 填充摘要
  evidence:
    - source: ""
      summary: ""
      confidence: "confirmed | inferred | unknown"
  handoff:
    current_stage: "requirement-analysis"
    status: "ready | waiting-user | blocked"
    next_skill: "design-solution | ask-user"
    next_action: ""
    auto_continue: false
    blockers: []
    user_action_needed: ""
    workstreams: []
  next_step: "ask-user | design-solution | write-plan"
```

## `01-需求分析.md` 结构

### 必出且前置（每次都必须写）

```markdown
# 01 需求分析

> 本文是本任务需求阶段的人工确认基线。确认范围与验收后进入方案评估；不另建 PRD。

## 1. 背景与目标

## 2. 现状与依赖

### 2.1 受影响面

### 2.2 现状

### 2.3 依赖清单

### 2.4 前后端交互面

## 3. 范围

### 3.1 本次包含

### 3.2 本次不包含

## 4. 验收标准
```

### 按需追加（有内容才写；不要为空章节占位）

在第 4 章之后按出现顺序继续编号，例如：

```markdown
## 5. 角色与场景

## 6. 业务规则

## 7. 数据对象

## 8. 接口与外部依赖

## 9. 配置与前端入口

> 涉及新增/变更运行时配置时必须写；不涉及配置则整章省略。

- 配置项：配置键 / 默认值 / 是否按租户/环境分域（形态由该项目技术栈决定）
- 前端入口决策：`需要新入口` / `扩展现有配置页` / `仅运维手推`
- 理由与验收：谁维护、如何验证保存后生效；仅运维手推须说明为何不暴露给用户

## 10. 非功能要求

## 11. 待确认问题

## 12. 风险与假设

## 13. 证据索引
```

选用规则：

| 可选章 | 何时追加 |
|---|---|
| 角色与场景 | 多角色、多路径或交互不直观时 |
| 业务规则 | 有状态、权限、幂等、异常或计费等规则时 |
| 数据对象 | 涉及表、缓存、DTO 或归属字段时 |
| 接口与外部依赖 | 有 API/RPC/事件/外部系统影响时 |
| 配置与前端入口 | 新增/变更运行时配置（配置项、租户级配置、开关、阈值、模板名等）时**必须追加** |
| 非功能要求 | 有性能、兼容、安全、可观测等约束时 |
| 待确认问题 | 仍有会阻塞方案的开放项时 |
| 风险与假设 | 有需明示的假设或残余风险时 |
| 证据索引 | 做过现状勘察（含领域调研）时**必须追加**；或需要回链代码/文档证据时 |

### 证据索引（领域调研时的写法）

命中 领域协议 等词并完成调研后，在证据索引中按 `domain-research.md` 写入短摘要，例如：

```markdown
## 4. 证据索引

### 文件导入格式

- 是什么：项目接收并验证的结构化文件格式。
- 与本需求关系：新增导入功能需要明确字段、编码与失败反馈。
- 关键约束：以项目已确认的接口契约为准。
- 证据：
  - source: {项目内接口契约路径}
    summary: {实际读到的字段与错误处理规则}
    confidence: confirmed

```

## 写作约束

- **必须输出**：`1. 背景与目标`、`2. 现状与依赖`、`3. 范围`（含包含/不包含）、`4. 验收标准`；四者始终放在文档最前。
- 做过现状勘察（含领域调研）时，**必须**追加证据索引；`inferred/unknown` 不得写成已确认事实。
- **禁止**为空的可选章生成“无 / 不适用”占位；没有内容就整章省略。
- 只记录有助于开发、测试、决策和追溯的信息。
- 不复制完整聊天记录、完整接口文档、长日志或大段源码。
- `open_questions` 最多 5 个，优先保留会阻塞方案设计或开发授权的问题。
- `handoff` 使用 `../write-plan/references/stage-handoff.md` 的语义；每个独立子需求在 `workstreams` 中保留自己的下一动作。
- YAML 中人类可读长文本超过约 60 个汉字或 100 个 ASCII 字符时，使用 `>-` 在语义边界换行；不要拆断单个路径、ID 或 URL。
- 信息完整度、问询、场景澄清与领域调研结果直接写入本文，不拆到其他需求 Skill。
- 现状与依赖勘察细则见 `current-state-recon.md`；领域调研细则见 `domain-research.md`。
