# 验证交付输出模板

仅在输出验证结果或交付判断时读取。

```yaml
verification_result:
  changed_files: []
  product_adapter_check:
    product: ""
    product_touchpoints: []
    current_repo_match: false
    ownership_match: false
    matched_risk_triggers: []
    defaults_match_approved_scope: false
    missing_evidence: []
  design_baseline_artifacts: []
  design_review_hashes:
    artifact_hash: ""
    reviewed_hash: ""
    source_set_hash: ""
    reviewed_source_set_hash: ""
    source_hashes_match: false
    recomputed_artifact_hash: ""
    recomputed_source_set_hash: ""
  freshness_recomputation:
    sources:
      - path: ""
        snapshot_content_hash: ""
        current_content_hash: ""
        match: false
    workstream_coverage_complete: false
  source_check_predicate:
    required: "check_status=pass && checked_revision=source_revision && checked_hash=content_hash"
    all_sources_match: false
  bootstrap_exception:
    used: false
    scope_match: false
  checks:
    - name: ""
      command: ""
      status: "passed | failed | skipped | not_authorized"
      summary: ""
  portal_ui_walkthrough:
    required: false
    status: "passed | failed | skipped | not_rendered"
    score: ""
    blockers: []
  unit_tests:
    required: false
    run_status: "passed | failed | skipped | not_authorized"
    classes: []
  code_review:
    required: false
    independent_of_implement_session: true
    human_review: "pending | approved | changes-requested | skipped"
    security: "pass | fail | skipped"
    requirement_coverage: "pass | fail | skipped"
    simplicity: "pass | fail | skipped"
    blockers: []
  acceptance:
    status: "passed | failed | partial | pending_user_review"
    evidence: []
  residual_risks: []
  issue_scan:
    fact_sources_scanned: false
    readme_consistency: "pass | ISSUE_INDEX_GAP | ISSUE_DUPLICATE_CONFLICT"
    project_summary_objects: []
    task_blocking_predicates:
      - "task_blocking | binding_task | claim_task | create_task | manifest_task | closing_task"
    recovery_objects: []
    blocker_refs: []
    blocks_current_task: false
  issues_to_create: []
  worklog:
    required: true
    mode: "draft | finalize | summary"
    reason: ""
  handoff:
    current_stage: "verification | completed"
    status: "ready | waiting-user | blocked | paused | cancelled | completed"
    next_skill: "write-worklog | write-issue | implement-change | ask-user | none"
    next_action: ""
    auto_continue: false
    blockers: []
    user_action_needed: ""
    workstreams: []
  next_step: "write-worklog | write-issue | ask-user | done"
```

约束：不复制完整命令输出；未授权的验证标记为 `not_authorized`，不能写成通过。issue 门禁必须以事实扫描为准，不能只读 README。有代码 diff 时 `code_review.human_review` 未 `approved` 不得把验收写成 passed。
