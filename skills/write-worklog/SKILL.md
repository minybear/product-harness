---
name: write-worklog
version: 0.4.0
description: 阶段完成时写开发日志。关闭 issue 时拆为 draft（initialize manifest + 稳定草稿）与 finalize（verify_issue_close 后收尾）；禁止在 issue 关闭前与 write-issue 形成循环，禁止在 fully_closed 前将任务标为 completed。
---

# 写开发日志（worklog）

worklog 记录“完成了什么、结果如何、沉淀什么”。过程动作写在任务 `06-AI作业追溯.md`；worklog 在阶段完成时汇总并回链。

关闭 issue 时本 Skill 是协调入口：先 draft，再由 `write-issue close`，最后 finalize。

## 归档位置

```text
docs/{项目}/logs/{yyyyMM}/{yyyyMMdd}-{模块}-{标题}.md
```

日期用 `date +%Y%m%d`；模块代码小写。

## 模式

| 模式 | 用途 |
|---|---|
| `draft` | 关闭 issue 前：initialize operation + 稳定草稿 |
| `finalize` | `verify_issue_close=completed` 且 transaction=`finalizing` 后：最终核销与任务/INDEX 收尾 |
| `summary` | 无 issue 关闭事务的普通阶段总结（不关闭 issue） |

## draft（关闭事务入口）

输入：issue_id、expected_issue_revision、完整 `resolution_items`、closing_task_id、授权、close_operation_id。

1. **initialize_operation**  
   - 原子创建 `issues/.transactions/{close_operation_id}/manifest.yaml`，status=`initializing`。  
   - 冻结 issue/base revision、closing task、预期 draft 路径、完整 resolution、authorizations、manifest_hash。  
   - 同 operation 不同 hash → `ISSUE_IDEMPOTENCY_KEY_CONFLICT`。  
   - coordination checkpoints：closing task 00、任务 INDEX、版本 INDEX、`TRACE-{close_operation_id}-initialize`。  
   - 全部复核后 CAS=`initialized`。
2. CAS manifest `initialized→drafting`。
3. 写入稳定 draft 路径，内容含 `close_operation_id` marker 与初始核销表。
4. 回填 `worklog_draft_hash`，CAS=`drafted`。
5. **不**更新任务为 completed；**不**关闭 issue。

resolution 约束：

- 必须覆盖目标 issue 全部 item。
- close 路径 **禁止 keep**；keep 只能表示“本轮不关闭该 issue”。
- action → item_status 映射遵循 `write-issue`：resolve/split/wontfix。

核销表最少列：

| issue_id | item_id | action | item_status | evidence | residual_issue_ids | blocking_after |
|---|---|---|---|---|---|---|

取消 draft/manifest：仅 initialized|drafted，且原授权人或 closing task owner；执行 cancellation checkpoints（含 `TRACE-{close_operation_id}-cancel`）。embedded 后禁止取消。

## finalize

前置：`write-issue` 已完成 `verify_issue_close`，transaction 处于 `finalizing`。

1. 对最终 worklog、logs/README、每个受影响 00/INDEX、trace 分别建 checkpoint 与稳定 marker。
2. 写入关闭后的最终目标状态，移除匹配 `source=issue` blocker。
3. 重试只执行未完成 checkpoint；append-only trace 不重复。
4. **在 `fully_closed=false` 时不得**把任务设为 completed，也不得设 `next.skill=none`。
5. 返回后由 `write-issue` 执行 `verify_end_to_end` 最终 CAS。

## summary（普通完成）

1. 识别关联任务档案；唯一匹配则关联。
2. 确认关键动作已在 trace。
3. **先事实扫描** open/closing 与恢复对象，再读 README；核销范围=当前任务相关谓词命中的 issue，以及本任务验收声称已处理的项目 issue。
4. 对每条给出 close/keep/split：  
   - close → 先 `draft` 再 `write-issue close` 再 `finalize`  
   - keep → 保留 open；若不阻塞当前任务需另走 scope-change  
   - split → 关闭前必须先建成后继
5. 未核销相关 blocking/recovery issue 时，不得整体 completed / `next.skill=none`。
6. 更新 logs/README 与任务快照。

## 日志模板

```markdown
# {yyyyMMdd} {模块} {标题}

## 1. 背景/问题现象
## 2. 方案/根因
## 3. 走过的弯路（有就必须写）
## 4. 效果
## 5. 经验沉淀（至少 1 条）
## 6. 优化建议
## 7. AI 作业追溯
- 关联 task / task_id / 追溯文件 / 摘要字段…
## 8. 关联 issue 核销
| issue_id | item_id | action | item_status | evidence | residual_issue_ids | blocking_after |
|---|---|---|---|---|---|---|
```

关闭事务 draft/finalize 还必须记录：`close_operation_id`、manifest 路径、worklog_draft_path、operation marker。

## 关键要求

- worklog 是阶段总结，不是过程流水账。
- 不得要求“先关闭 issue 再写 worklog”，也不得在 draft 前调用 close。
- 存在其他 ready/waiting-user/blocked workstream 时不得整体完成。
- 项目其他无关 open issue 只进项目摘要，不单独阻止当前任务；但相关 blocking/recovery 对象必须处理。
