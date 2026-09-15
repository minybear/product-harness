# 任务卡 YAML 导出

仅当用户明确要求“导出 YAML / 原始任务卡 / 供工具消费 / 写入结构化文件”时读取本文件。字段顺序、禁止顶层重复风险字段、沙盘 notes 与 `decision_card` 默认值以本节为准；入口 Skill 不再重复这些导出细则。

## 标准导出

```yaml
task_card:
  title: ""
  product: "已登记的唯一主产品，如 common | example-app"
  product_touchpoints: []
  product_adapter_status: "complete | incomplete"
  product_execution_status: "executable | blocked-in-this-repo | catalog-only"
  task_type: "consult | investigation | bugfix | feature | refactor | test | doc | config | data | release | incident"
  target_risk_level: "R0 | R1 | R2 | R3 | R4"
  current_turn_risk_level: "R0 | R1 | R2 | R3 | R4"
  collaboration_mode: "AI自动处理 | AI辅助开发 | AI辅助决策 | 人主导高风险执行 | 协作排障"
  allowed_ai_actions:
    read_code: true
    edit_code: false
    run_tests: false
    change_config: false
    change_database_script: false
    call_external_api: false
    deploy: false
    operate_production: false
  next_action: ""
  user_decision_needed: false
  interview_finish_mode: "confirm | auto"
  notes: []
execution_requirements:
  task_archive:
    required: false
    reason: ""
  trace:
    required: false
    reason: ""
  decision_card:
    required: false
    reason: ""
  subagent:
    required: false
    reason: ""
questions: []
next_step: ""
```

## 沙盘导出

```yaml
task_card:
  title: ""
  product: "已登记的唯一主产品，如 common | example-app"
  product_touchpoints: []
  product_adapter_status: "complete | incomplete"
  product_execution_status: "executable | blocked-in-this-repo | catalog-only"
  task_type: "consult | investigation | bugfix | feature | refactor | test | doc | config | data | release | incident"
  target_risk_level: "R0 | R1 | R2 | R3 | R4"
  current_turn_risk_level: "R0 | R1"
  collaboration_mode: "AI辅助决策"
  next_action: ""
  user_decision_needed: true
  interview_finish_mode: "confirm"
  notes: []
execution_requirements:
  task_archive:
    required: false
    reason: "实施时再建"
  trace:
    required: false
    reason: "本轮不落盘"
  decision_card:
    required: true
    reason: "目标任务高风险"
  subagent:
    required: false
    reason: "实施前再复核"
questions: []
next_step: ""
```

## 导出约束

- 顶层字段顺序固定为：`task_card`、`execution_requirements`、`questions`、`next_step`；缩进使用 2 个空格。
- `target_risk_level`、`current_turn_risk_level`、`collaboration_mode` 必须位于 `task_card` 内；禁止顶层 `risk_level`、顶层 `collaboration_mode` 和嵌套风险对象。
- `product` 决定任务档案与默认实施仓，只能一个；`product_touchpoints[]` 去重且不得包含主产品。风险取通用模型、主产品和全部 touchpoint 适配器触发的最高值。
- 产品未登记、`catalog-only`，或当前动作依赖 `incomplete` 适配器缺失字段时，写入 `notes`/问题卡并 fail-closed；不得猜测默认值或实施仓。
- 是否需要 `task_archive`、`trace`、`decision_card`、`subagent` 必须分别输出 `true/false`；理由最多一句。
- 沙盘、dry-run、不落盘等上下文写入 `notes`，不得污染风险枚举或协作模式。R3/R4 目标任务只读或沙盘时，本轮风险可为 R0/R1；R3/R4 默认仍需 `decision_card: true`。
- 续作已有任务档案时，`next_step` 必须与“当前工作流快照”的唯一 `next.skill` 一致；不能因通用触发词重置阶段。
- 人类可读长文本超过约 60 个汉字或 100 个 ASCII 字符时，使用 YAML 折叠块 `>-` 并在语义边界换行；不要拆断单个文件路径、ID 或 URL。
