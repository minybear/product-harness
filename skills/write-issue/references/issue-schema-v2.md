# issue schema v2 与协调文件契约

权威实施契约见任务 `03A-聚合详细设计.md` §5.2 / §5.6–§5.10。本文件是 Skill 运行时模板摘要；字段名、复数形式与枚举必须与 03A 一致。

## 1. issue 文件（事实源）

路径：

- 活动：`docs/{项目}/issues/open/{issue_id}.md`
- 已提交关闭：`docs/{项目}/issues/closed/{issue_id}.md`

正文前置 YAML（或等价 front-matter）必须可机读。新 issue 固定 `schema_version: 2`。`issue_id` 与 `open|closed` 文件名相同且必须人能读；另存 `key_hash` 供去重。

必填分组：identity、scope、create、items（≥1）、close_transaction（新建为 `status=none`）、审计字段。详见 03A §5.2.9。

目录/状态合法组合：

- `open/` + `status=open|closing`
- `closed/` + `status=closed`
- schema v2 且 `close_transaction.status!=completed` 的 closed 文件仍是恢复对象

`legacy_closed=true` 仅当：位于 closed、status=closed、缺 `schema_version/close_transaction`、无同 ID open 副本。README 不参与身份判定。

## 2. create operation binding

路径：`docs/{项目}/issues/.operations/create/{lowercase-sha256(create_operation_id)}.yaml`

状态：`bound | assigned | waiting-dedup | deduplicated | abandoning | abandoned`

## 3. problem-key claim

路径：`docs/{项目}/issues/.claims/{key_hash}.yaml`

状态：`claimed | materializing | materialized | abandoning | abandoned`

普通 `issue_id` 必须人能读，并作为 `open|closed` 下的文件名：`ISSUE-{yyyymmdd}-{module}-{slug}.md`（slug 为小写 kebab，从标题缩写；同日同模块冲突时追加 `-{key_hash 前 8 位}`）。去重身份仍是 `key_hash`（problem key 的 SHA-256）；`.claims/{key_hash}.yaml` 与 `.operations/create/{sha256(create_operation_id)}.yaml` 保持哈希文件名，只作协调锁，不给人浏览。legacy normalization 本代可用 `legacy-preserved` 保留原 ID。

## 4. close manifest

路径：`docs/{项目}/issues/.transactions/{close_operation_id}/manifest.yaml`

状态：`initializing | initialized | drafting | drafted | embedding | embedded | cancelling | cancelled`

`manifest_hash` 只覆盖 immutable request（issue/base revision/closing task/预期 draft 路径/resolution/authorizations）。

## 5. Canonical hash

1. 字符串 Unicode NFC。
2. module locale-independent lowercase；title 去首尾并折叠空白；ID 去首尾保留大小写。
3. affected IDs 去重后 UTF-8 字节序排序；approvals/evidence 按 `(role,by,at,evidence-hash)`；items 按 item_id。
4. RFC 8785 canonical JSON → UTF-8 SHA-256（小写 hex）。
5. `normalized_problem_key` = `{module,title,source_task_id}`。
6. `create_request_hash` = `{normalized_problem_key,scope,blocking,affected_task_ids,affected_workstream_ids,scope_approvals,items,source_content_hash}`；普通 create 的 `source_content_hash=""`。

## 6. Blocker ref

```text
issue:{issue_id|pending}#{item_id|binding:{operation_key_hash}|claim:{key_hash}|create|transaction|manifest:{close_operation_id}}
```

只增删 `source=issue` 的 blocker。

## 7. 稳定错误码

`ISSUE_NOT_FOUND`、`ISSUE_AMBIGUOUS`、`ISSUE_SCHEMA_INVALID`、`ISSUE_SCOPE_INVALID`、`ISSUE_INDEX_GAP`、`ISSUE_DUPLICATE_CONFLICT`、`ISSUE_REVISION_CONFLICT`、`ISSUE_OPERATION_CONFLICT`、`ISSUE_IDEMPOTENCY_KEY_CONFLICT`、`ISSUE_CLAIM_CONFLICT`、`ISSUE_CREATE_IN_PROGRESS`、`ISSUE_CREATE_OPERATION_ABANDONED`、`ISSUE_ALREADY_EXISTS`、`ISSUE_ALREADY_CLOSED`、`ISSUE_MANIFEST_CANCEL_FORBIDDEN`、`ISSUE_ITEMS_NOT_TERMINAL`、`ISSUE_SPLIT_INCOMPLETE`、`ISSUE_WONTFIX_APPROVAL_REQUIRED`、`ISSUE_SCOPE_APPROVAL_REQUIRED`、`ISSUE_NORMALIZATION_REQUIRED`、`ISSUE_TRANSACTION_INCOMPLETE`。
