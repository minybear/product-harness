# 方案评估输出模板

仅在需求分析后的方案评估、或写入任务档案 `02-方案评估.md` 时读取；它不是 `design/` 下的正式设计模板。

```yaml
solution_evaluation:
  title: ""
  recommended_option: ""
  domain_research:
    required: false
    reused_from_01: false
    deepened: false
    blocking_unknowns: []
  options:
    - id: "A"
      summary: ""
      changes: []
      impacted_modules: []
      module_skills_to_use: []
      data_or_config_impact: []
      frontend_config_entry:
        required: false
        decision: "extend-existing | new-page | ops-only | n/a"
        target_page: ""
        config_namespace: ""
        rationale: ""
      external_impact: []
      protocol_or_network_impact: []
      evidence_refs: []
      test_strategy: []
      rollback_strategy: ""
      risks: []
      pros: []
      cons: []
  decision_needed: true
  open_questions: []
  design_baseline:
    required: false
    reason: ""
    target_documents:
      - module: ""
        path: "docs/{项目}/design/{模块}/{主题}-设计.md"
        scope: ""
  handoff:
    current_stage: "solution-evaluation"
    status: "ready | waiting-user | blocked"
    next_skill: "make-decision-card | design-solution | implement-change | ask-user | analyze-requirement"
    next_action: ""
    auto_continue: false
    blockers: []
    user_action_needed: ""
    workstreams: []
  next_step: "make-decision-card | design-solution | implement-change | ask-user | analyze-requirement"
```

约束：简单任务只输出一个方案；最多三个方案；每个方案保留改动、影响、测试、回滚和风险。涉及 领域协议或外部服务 等协议或网元契约时，先按 `../analyze-requirement/references/domain-research.md` 复用并加深 `01` 证据；`blocking_unknowns` 非空时不得把推断写成推荐契约。R3/R4 必须指向 `make-decision-card`；决策确认后若 `design_baseline.required=true`，唯一下一 Skill 必须是 `design-solution`，不得跳过正式设计发布。
