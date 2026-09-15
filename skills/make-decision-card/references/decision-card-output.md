# 决策卡输出模板

仅在输出或落盘决策卡时读取。

```yaml
decision_card:
  title: ""
  target_risk_level: "R3 | R4"
  product_adapter_effects:
    product: ""
    product_touchpoints: []
    matched_risk_triggers: []
    defaults_applied: []
    missing_evidence: []
  recommendation: "approve | approve_with_conditions | reject | ask_for_more_evidence"
  recommended_option: ""
  summary: ""
  key_evidence:
    - source: ""
      conclusion: ""
      confidence: "high | medium | low"
  entry_criteria: []
  blast_radius:
    environment: ""
    tenant_scope: ""
    data_scope: ""
    device_scope: ""
    external_system_scope: ""
  rollback_strategy: ""
  stop_conditions: []
  blocking_issues: []
  user_decision:
    required: true
    acting_role: []
    question: ""
  design_baseline:
    required: false
    status: "not-required | pending | published"
    target_documents: []
  handoff:
    current_stage: "decision"
    status: "waiting-user | ready | blocked"
    next_skill: "make-decision-card | design-solution | implement-change | write-issue | ask-user"
    next_action: ""
    auto_continue: false
    blockers: []
    user_action_needed: ""
    workstreams: []
  next_step: "design-solution | implement-change | ask-user | write-issue"
```

约束：决策卡必须短；证据必须可索引；R3/R4 不得缺少影响范围、回滚和停止条件。产品适配器只能提高风险，其默认值只能收紧或经有权角色显式风险接受后调整；`missing_evidence` 未关闭时不得推荐批准执行。未获人工决策时，`handoff.next_skill` 不得越过 `make-decision-card`；确认后若 `design_baseline.required=true`，必须先转 `design-solution` 发布正式设计。
