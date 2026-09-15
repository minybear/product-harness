# 阶段交接快照

仅在任务跨阶段、跨会话、跨工作日或存在两个及以上独立子需求时读取。本文件定义任务档案、方案评估、决策、正式设计发布、整合设计评审和实施之间的连续性契约。

## 状态源与目录职责

- 新版任务状态源是 `docs/{项目}/tasks/{task}/00-需求概览.md` 的“当前工作流快照”；`tasks/README.md` 仅显示摘要，`06-AI作业追溯.md` 只保存历史。
- 旧 `docs/{项目}/plan/{task}/` 只作为兼容读取路径；首次获用户授权迁移后，以 `tasks/` 为唯一状态源，不得维护双份快照。
- `tasks/` 保存需求、分析、候选方案、决策、实施/验证计划和 trace；`design/` 只保存决策确认后的长期设计基线。
- `docs/{项目}/INDEX.md` 和 `tasks/{task}/INDEX.md` 只提供检索入口、当前动作和文档链接；不得复制完整正文或维护第二份状态。当前事实与阶段以 `00-需求概览.md` 为唯一状态源。
- 路由优先级：活跃需求访谈状态 > 当前工作流快照 > 通用 Skill 触发词。先读 INDEX 和快照；仅审计、证据冲突或历史恢复时补读相关 trace。

## 最小结构

```yaml
workflow_handoff:
  updated_at: ""
  current_stage: "requirement-analysis | solution-evaluation | decision | design-publication | design-review | implementation | verification | completed"
  completed_stage: ""
  status: "ready | waiting-user | in-progress | blocked | paused | cancelled | completed"
  next:
    skill: "analyze-requirement | design-solution | make-decision-card | check-design | aggregate-design | implement-change | verify-delivery | write-worklog | write-issue | none"
    action: ""
    auto_continue: false
    user_action_needed: ""
  blockers: []
  design_baseline:
    required: false
    status: "not-required | pending | published"
    artifacts:
      - workstream_ids: []
        path: ""
        module: ""
        title: ""
        source_revision: ""
        content_hash: ""
        check_status: "pending | pass | fail"
        checked_revision: ""
        checked_hash: ""
        check_report: ""
  design_review:
    required: false
    hash_version: "design-sha256-v1"
    status: "not-required | pending | waiting-review | approved | changes-requested | stale"
    artifact: ""
    artifact_revision: ""
    artifact_hash: ""
    source_set_hash: ""
    reviewed_hash: ""
    reviewed_source_set_hash: ""
    change_target: "source | aggregation | empty"
    sources:
      - path: ""
        decision_id: ""
        revision: ""
  design_check_authorization:
    status: "not-granted | granted | revoked"
    scope: []
    authorized_by: ""
    authorized_at: ""
  execution_authorization:
    status: "not-granted | granted | revoked"
    scope: []
    authorized_by: ""
    authorized_at: ""
  bootstrap_exception:
    decision_id: ""
    reason: ""
    scope: []
    expires_when: ""
  workstreams:
    - id: ""
      title: ""
      design_required: true
      status: "ready | waiting-user | in-progress | blocked | paused | cancelled | completed"
      completed_stage: ""
      next_skill: ""
      next_action: ""
      blockers: []
      authorization_needed: ""
```

`next.skill` 必须唯一。`current_stage` 始终保留业务阶段，不能改成 `blocked`；阻塞、暂停和取消只由 `status` 表达。

- `none` 只用于 completed，或已完成 issue 处置的 cancelled。
- paused 必须保留恢复 Skill，不得用 `none` 丢失恢复路径。
- `auto_continue=true` 只允许进入不改文件、不运行命令、不调用外部系统的分析/决策步骤。
- `design_check_authorization` 与 `execution_authorization` 必须限域、可撤销，不能从决策卡、03A 批准或 trace 推断。
- `bootstrap_exception` 只允许自举修复，必须绑定已批准决策、明确 scope 和失效条件。
- `design_required` 缺失的旧快照按 `true` 处理，避免迁移期间漏掉设计门控；显式为 `false` 必须在 `02-方案评估.md` 说明理由。

旧快照中的 `solution-design` 在读取时按 `solution-evaluation` 处理，并在下一次获授权更新时改写为新值。

## 正式设计基线判定

以下任一条件成立时，`design_baseline.required=true`：

- R3/R4；
- 跨模块协作；
- 新增或变更 REST/RPC/事件/前端消费契约；
- 新增或变更配置模型、数据库/缓存结构、权限模型或长期业务规则；
- 用户明确要求概要设计、详细设计、接口设计或设计基线。

局部 R0-R2 修复可以 `not-required`，但必须在 `02-方案评估.md` 写明理由。正式设计必须在决策确认后由 `design-solution` 发布到 `design/{模块}/`；未发布时不得把需要该基线的工作流交给 `implement-change`。

## 聚合详细设计与整体评审判定

以下任一条件成立时，`design_review.required=true`，且必须先 `check-design` 再 `aggregate-design`：

- 任务已发布至少一份正式设计；
- 用户明确要求整合设计、总体技术评审或评审包；
- 一个端到端流程依赖两份及以上正式设计；
- R3/R4 跨模块任务需要在实施前统一核对接口、配置、数据、异常、回滚或实施顺序。

不得以「单一、独立、低风险」跳过 03A。未发布正式设计的局部 R0-R2 任务仍可 `design_review.required=false`，并在方案评估中写明理由。

只要 `design_baseline.artifacts` 中存在 published artifact，`design_review.required=true` 就是派生不变量。实施/验证不能因旧快照写成 false 而放行。

`check-design` 对完整来源集合做证据链、细节闭环、说法自洽自检，并绑定 `checked_hash/content_hash`。失败退回 `design-solution`；来源变化清空旧 pass 并将 03A 置 stale。写入 `02A/00/INDEX/trace` 前必须有 `design_check_authorization=granted`。

`aggregate-design` 只编译任务全部 `pass` 且指纹匹配的来源。03A 必须记录 `artifact_hash/source_set_hash`；人工批准记录匹配的 `reviewed_hash/reviewed_source_set_hash`。局部 workstream 不得使用任务级批准状态。附条件批准视为 changes-requested。人工批准不等于实施授权。

`design_baseline.required=true` 时，所有 `design_required!=false` 的 workstream 都必须被 artifact `workstream_ids` 并集覆盖；缺失映射按 fail-closed 处理并回 `design-solution`。`check_status` 缺失/非法时不得融合或实施。`design_review.status=changes-requested` 时 `change_target` 只能是 `source|aggregation`，缺失/非法值必须保持 `waiting-user` 并登记 blocker。
该完整范围谓词统一记为 `workstream_union_complete=true`。

设计发布、实施、验证和入口路由调用 [统一指纹工具](../../aggregate-design/references/fingerprint-tool.md) 从当前文件核验。已知版本真实不匹配时当前批准不能放行；旧档案无算法版本、未知版本或解析错误属于证据恢复，保留原批准记录，不直接判定正文变化，不覆盖旧 hash、不重新访谈。具体协议只在工具文档维护。

## 阶段路由

| 已完成阶段 | 常规下一 Skill | 何时停止等待用户 |
|---|---|---|
| 需求访谈 | `analyze-requirement`（写/确认 `01`）或 `design-solution` | 访谈未结束、落盘未授权、仍有阻塞 frontier，或 `01` 尚未确认 |
| 需求分析 | `design-solution` | `01` 未获用户确认，或仍有阻塞方案评估的开放项 |
| 方案评估 R0-R2 | `implement-change` 或 `design-solution` | 需正式设计基线或新操作授权 |
| 方案评估 R3/R4 | `make-decision-card` | 决策卡需要人工结论 |
| 决策卡获批 | `design-solution` 或 `implement-change` | 基线待发布，或独立实施授权不完整 |
| 正式设计发布 | `check-design` | 基线未发布 |
| 设计自检通过 | `aggregate-design` | 自检失败回 `design-solution`；指纹不匹配重新自检 |
| 聚合详细设计评审通过 | `implement-change` | reviewed hash 不匹配、来源过期、完整性不通过或独立实施授权不完整 |
| 实施完成 | `verify-delivery` | 验证命令/环境未获授权 |
| 验证通过 | `write-worklog` | 关闭 issue 时先 draft；尚待人工验收或交付确认 |
| 验证失败/风险不可接受 | `implement-change` 或 `write-issue` | 超出授权或需要风险接受 |
| worklog draft 完成 | `write-issue`（close） | 需关闭相关 issue |
| write-issue close 完成 verify_issue_close | `write-worklog`（finalize） | transaction 未 fully_closed |
| worklog finalize / fully_closed | `none` | 无未完成工作流，且相关 blocking/recovery issue 已 fully_closed 或合法转出 |

## 交接规则

1. 每个阶段结束前更新或呈现快照，明确已完成内容、唯一下一动作和需要谁做什么。落盘后必须更新快照中能被续作读取的字段（至少 `next.action` / workstream 状态 / 已完成说明），使最新实施类 trace 可被 `00` 解释；禁止 trace 单飞。升 `current_stage` 仅在阶段迁移时。快照跟工作完成，不跟 git commit。
2. `next.skill` 非 `none` 时不得以“任务已完成”结束答复；只能说明当前阶段完成。
3. 多个可独立推进的子需求必须列入 `workstreams`；一个子流的 blocker 不得覆盖另一个已 `ready` 的子流。
4. `waiting-user` 必须写清楚可直接回复的动作，例如“批准 DC-01 并授权发布正式设计”或“提供 MIB OID 清单”。
5. 每次阶段迁移在 trace 中记录完成阶段、下一 Skill、阻塞项、用户动作和正式设计基线状态；不要复制完整快照。
6. 续作优先恢复 `next.skill`；只有快照过期、与新指令冲突或证据失效时才重新评估并说明原因。
7. 状态迁移更新顺序固定为：`00` → 任务 INDEX → 版本 INDEX 等待项 → trace。
8. issue blocker 引用固定为 `issue:{issue_id|pending}#{item_id|binding:{op}|claim:{key}|create|transaction|manifest:{close_op}}`；只增删 `source=issue` blocker；issue 清空后按剩余 blocker 与业务阶段重算，不得直接写 completed。
9. 验证通过后若需关闭 issue，下一 Skill 是 `write-worklog`（draft），不是直接 `write-issue close`。

多个 `workstreams` 时，阶段交接还必须更新版本/任务 INDEX 的“需要你处理”区，并在下一次项目相关回复中逐项播报全部子流。任务级唯一 `next.skill` 只表示优先动作，不能替代并行子流的等待状态。项目活动 issue 必须出现在项目摘要；当前任务只被精确相关 blocker 阻塞。

默认读取路径：版本 INDEX → 任务 INDEX → `00-需求概览.md` → 当前阶段所需正文。聚合阶段读取全部纳入范围的正式设计；聚合批准后，实施阶段默认读取 `03A-聚合详细设计.md`，相关 `design/{模块}/` 和 `03-决策记录.md` 仅用于审计、争议或 freshness 核验；`02-方案评估.md`、README 和 `06-AI作业追溯.md` 仅按需查阅。

## 默认用户呈现

```markdown
## 当前进度

- 已完成：{completed_stage}
- 当前：{current_stage}（{status}）
- 正式设计：{design_baseline.status；仅 required=true 时展示}
- 整体评审：{design_review.status；仅 required=true 时展示}
- 下一步：{next.action}
- 需要你：{next.user_action_needed；无则省略}
- 阻塞：{blockers；无则省略}
```

只有用户明确要求结构化导出时才输出完整 YAML；默认只展示上述简短进度卡。
