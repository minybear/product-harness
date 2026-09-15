# 开发实施输出模板

仅在准备实施或完成实施时读取。

准备实施：

```yaml
implementation_plan:
  decision_refs: []
  execution_authorization:
    status: "granted"
    scope: []
    authorized_by: ""
    authorized_at: ""
  bootstrap_exception:
    applicable: false
    decision_id: ""
    scope: []
  authorized_actions: []
  design_baseline_artifacts: []
  design_review_hashes:
    artifact_hash: ""
    reviewed_hash: ""
    source_set_hash: ""
    reviewed_source_set_hash: ""
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
  module_skills_to_use: []
  files_to_read: []
  files_to_change: []
  expected_changes: []
  unit_tests:
    required: false
    planned_classes: []
  risks: []
  rollback_notes: []
  handoff:
    current_stage: "implementation"
    status: "ready | waiting-user | in-progress | blocked"
    next_skill: "implement-change | verify-delivery | ask-user | write-issue"
    next_action: ""
    auto_continue: false
    blockers: []
    user_action_needed: ""
    workstreams: []
  next_step: "apply-change | ask-user | verify-delivery"
```

已实施：

```yaml
implementation_result:
  changed_files: []
  summary: ""
  unit_tests:
    required: false
    files: []
    run_status: "passed | failed | skipped | not_authorized"
  authorization_scope_used: []
  bootstrap_exception_used: false
  source_check_predicate:
    required: "check_status=pass && checked_revision=source_revision && checked_hash=content_hash"
    all_sources_match: false
  freshness_recomputation:
    recomputed_artifact_hash: ""
    recomputed_source_set_hash: ""
    current_content_hashes_match: false
    workstream_coverage_complete: false
  trace_updates: []
  risks_or_assumptions: []
  handoff:
    current_stage: "verification"
    status: "ready | waiting-user"
    next_skill: "verify-delivery | ask-user"
    next_action: ""
    auto_continue: false
    blockers: []
    user_action_needed: ""
    workstreams: []
  next_step: "verify-delivery"
```
