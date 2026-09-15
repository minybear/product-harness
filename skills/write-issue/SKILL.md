---
name: write-issue
version: 0.4.1
description: 按 schema v2 创建、规范化、变更 scope、关闭与恢复 issue。事实源是 issues/open|closed 文件与协调文件；README/INDEX 是派生索引。关闭必须走 worklog draft → close transaction → finalize，禁止与 worklog 形成循环。
---

# 写问题（issue）

issue 记录待处理问题的身份。跨工作日复用同一问题键；创建与关闭均使用 operation ID，可中断恢复。

权威契约：任务 `03A-聚合详细设计.md` 与 `references/issue-schema-v2.md`。字段名与关闭事务以 03A 为准；**`open|closed` 文件名与 `issue_id` 必须人能读**，以 schema 本节为准（覆盖 03A 中「issue_id=key_hash」的展示约定）。去重仍用 `key_hash`。

## 事实源与派生索引

事实源：

- `issues/open/*.md`（`status=open|closing`）
- `issues/closed/*.md`（`status=closed`）
- `issues/.operations/create/{operation_key_hash}.yaml`
- `issues/.claims/{key_hash}.yaml`
- `issues/.transactions/{close_operation_id}/manifest.yaml`

派生索引：`issues/README.md`、任务/版本 INDEX、`tasks/README.md`。不得用 README 判定身份或完成。

入口/验证/收尾必须轻量扫描事实源并校验 README 漂移；漂移返回 `ISSUE_INDEX_GAP` 并重建，不得假定“无活动 issue”。

## 模式

| 模式 | 用途 |
|---|---|
| `create` | 新建或幂等定位活动/恢复 issue |
| `normalize` | legacy open → schema v2（须用户确认） |
| `scope-change` | 改变 scope/blocking/affected IDs |
| `close` | 消费 drafted manifest，执行九步关闭事务 |
| `recover` | 同 operation 从首个 pending/failed checkpoint 续跑 |

所有写模式需要绑定 issue/task/operation 的用户授权。AI 不得代签风险接受角色。

## create

1. 校验请求必填：`create_operation_id/module/title/source_task_id/scope/blocking/affected_*/items[]`。
2. 计算 `normalized_problem_key`、`create_request_hash`、`key_hash`（见 schema 参考）。
3. 原子创建或校验永久 create-operation binding：
   - 同 operation 不同 key/request → `ISSUE_IDEMPOTENCY_KEY_CONFLICT`
   - 不同 operation 命中未物化 generation → binding=`waiting-dedup`，返回 `ISSUE_CREATE_IN_PROGRESS`
   - 命中已物化活动/恢复 issue → binding=`deduplicated`，返回 `ISSUE_ALREADY_EXISTS`，不改 issue
4. owner 取得 claim generation 后 CAS `claimed→materializing`，原子写入 open 文件：人读 `issue_id` 作文件名、完整 schema v2、`create_transaction=indexing`、全部 create checkpoints。YAML 内同时写 `key_hash`（与 claim 文件名一致）。禁止用 64 位 hash 作为 `open|closed` 文件名。
5. CAS claim=`materialized`。
6. 按 checkpoint 预写 README、source task 00/INDEX、版本 INDEX、必要 tasks README、适用 item blocker、稳定 trace `TRACE-{create_operation_id}-create`。
7. 全部复核后，最后一次 issue CAS 写 `create_transaction=completed`。此后无必写派生文件。
8. 关闭、scope-change 与后续修改必须等待 create completed。
9. **禁止**用 create 向既有 issue 追加 item；新残余走 split。

blocker：indexing 期间 source task 持有 `issue:{id}#create`；completed 后按 `task_blocking_predicate` 写 `issue:{id}#{item_id}`。

## normalize（legacy open）

1. 生成 normalization 草稿：原文片段与建议 `ITEM-LEGACY-NNN`，不得自动合并。
2. 用户确认 item 映射、source task、scope、blocking、风险字段前，返回 `ISSUE_NORMALIZATION_REQUIRED`。
3. 确认后计算 `expected_legacy_hash`，写入 claim `source_content_hash` 与 create request；`identity_strategy=legacy-preserved`，保留原 issue_id/path。
4. 对该 hash CAS，原子重写为 v2 revision 1 + indexing，再完成 create checkpoints。
5. legacy closed 只读；不回填 transaction。

## scope-change

1. `keep` **不是**本模式，也不改变 scope/blocking。
2. 校验 scope 合法组合：
   - `project`：affected 数组皆空；`blocking=true` 需 project owner 批准
   - `task`：`affected_task_ids` 非空；workstream 数组空
   - `workstream`：唯一 task + 非空 workstream IDs
3. 缩小范围或解除 blocking 需受影响 task owner；security/compliance 追加对应角色。
4. 用 issue revision CAS；记录 old/new、理由、证据、approvals、changed_by/at。
5. 重算受影响 task/INDEX；不得删除项目摘要中的 issue。

## close

前置：

- `create_transaction=completed`
- 唯一 `closing_task_id`
- `write-worklog draft` 已建立 **drafted** manifest（含完整 `resolution_items`）
- 稳定 worklog draft 路径、operation ID、expected revision
- resolution 覆盖全部 item，且 **不含 keep**

固定顺序（前置 initialize 由 write-worklog 完成）：

1. `begin_transaction`：manifest `drafted→embedding`；issue 写 `status=closing`、transaction=`preparing`、冻结 base revision。
2. `resolve_items`：应用 resolve/wontfix；暂存 split。
3. `create_split_successors`：后继 `create_operation_id={close_op}:{item_id}:{ordinal}`；全部事实与索引成功后再标 split。
4. `commit_closed_file`：写 closed 临时内容 → rename → 清理 open；双副本仅同 operation 且 closed revision 更高时清理。
5. `rebuild_issue_index`
6. `verify_issue_close`：通过后才允许 worklog finalize。
7. `finalize_worklog_and_tasks`：由 write-worklog finalize 写各 target checkpoint。
8. `verify_end_to_end`：最后单次 CAS 写 `consistency_check=pass`、step completed、`transaction.status=completed` → `fully_closed`。

任一步失败保持当前 phase，写 step/checkpoint failed；同 operation 从首个 pending/failed 继续。transaction 不使用含糊 failed 终态。

item 映射：

| action | 结果 | 前置 |
|---|---|---|
| resolve | resolved | evidence 非空 |
| split | split | 全部后继事实+索引存在 |
| wontfix | wontfix | 风险级别/类别 + 角色并集批准 |
| keep | 禁止用于 close | — |

风险角色：R0-R2 normal → task owner；R3 → domain/project owner；R4 → project owner + 系统责任人；security/compliance → 对应 owner；多条件取并集。

返回：`close_transaction.operation_id/current_revision/next_pending_step/fully_closed`。

关闭后分别重算来源 task 与 closing task：只清除匹配 blocker ref，再按剩余 blocker 与业务阶段恢复；不得直接写 completed。

## recover

同 operation 读取最新 transaction/manifest/claim/binding，从首个 pending/failed checkpoint 续跑。不同 operation → `ISSUE_OPERATION_CONFLICT`。已 fully_closed 且不同 close op → `ISSUE_ALREADY_CLOSED`。

manifest 取消：仅 `initialized|drafted` 可在授权下进入 `cancelling`；唯一系统取消例外是 embedding 后 revision 冲突且无同 operation transaction。embedded 后禁止取消。

## 任务恢复算法

1. 扫描事实 issue、未完成 binding/claim/manifest/transaction。
2. 计算谓词并集：`task_blocking`、`binding_task`、`claim_task`、`create_task`、`manifest_task`、`closing_task`。
3. 只增删 `source=issue` blocker。
4. issue blocker 清空后按当前阶段、其他 blocker、授权重算；禁止恢复陈旧 completed。

## 禁止

- 仅因关联 issue、发布新版本、写 worklog 或任务 completed 而关闭。
- 用 README 代替事实扫描。
- 在 fully_closed 前宣称任务完成或 `next.skill=none`。
- 无证据 reopen 已提交 closed。
- 隐式 append items。
