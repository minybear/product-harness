---
name: verify-delivery
version: 0.4.6-public.1
description: 在代码、文档或配置变更后执行或规划验证，核对任务验收与已发布设计基线；issue 门禁用事实扫描与精确谓词并集，通过后转 write-worklog（关闭 issue 时先 draft）。不扩大范围继续开发，不顺手做新需求或未授权修复。
---

续作指纹核验必须调用 [统一工具](../aggregate-design/references/fingerprint-tool.md)。无版本旧值、未知版本或计算错误先恢复证据，保留原业务阶段和 next.skill；只阻断依赖该证据的动作，不把异常直接当设计变化，不重开需求。hash-match 不替代设计批准和实施/验证授权。

# 验证交付（verify-delivery）

判断本轮结果是否可交付，不扩大范围继续开发。

## 触发

- `implement-change` 完成后。
- 用户要求验证、测试、review、收尾或交付。
- 文档、方案、代码或配置变更需要阶段性验收。

## 准入与边界

- 必须知道本轮变更或待交付物。
- 续作快照的 `next.skill` 必须是 `verify-delivery`；否则先回 `ai-collab-start` 恢复当前阶段，不因“验收/审查”动作词跨阶段。
- 必须重新加载主 `product` 与全部 `product_touchpoints[]` 适配器，确认当前仓、所有权、风险触发器及设计中采用的产品默认值未漂移；`blocked-in-this-repo/catalog-only/missing_evidence` 不得被验证结果绕过。
- 若任务需要正式设计，必须确认 `design_baseline.status=published` 且产物存在；否则回 `design-solution`。
- 验证准入必须从当前文件重算 freshness：
  - 调用统一指纹工具重算 `current_content_hash`、`recomputed_source_set_hash` 和 `recomputed_artifact_hash`，要求它们分别与已登记指纹匹配。
- 只要存在任一 published artifact，不论 `design_review.required` 当前值为何，都必须确认：
  - `design_review.status=approved`
  - `reviewed_hash=artifact_hash`
  - `reviewed_source_set_hash=source_set_hash`
  - 每个来源同时满足 `check_status=pass`、`checked_revision=source_revision`、`checked_hash=content_hash`
  - `workstreams[].design_required` 未显式为 `false` 的子流全部包含在 artifact `workstream_ids` 并集中
  - 当前来源集合未变化
- `check_status` 缺失/非法时执行 `invalid_check_status=blocked`；workstream 覆盖不完整、当前文件 hash 未重算或不匹配时同样 fail-closed，不能把验证标记为通过或猜测下一设计 Skill。
- 校验失败时唯一回流：来源 `fail` → `design-solution`；来源变化、pending、缺失完整 `02A` 或 checked revision/hash 不匹配 → `check-design`；仅 03A 未生成、变化或待评审 → `aggregate-design`；changes-requested 仅按合法 `change_target=source|aggregation` 路由，缺失或非法值时保持 `waiting-user` 并登记 blocker。
- 自举纠偏任务只有在 `bootstrap_exception` 已批准、scope 命中且未过期时，才能用正式设计和沙盘证据代替自身 03A；例外必须在独立复核通过后失效。
- 自举例外不能跳过来源当前 hash、完整 workstream 覆盖或授权 scope。
- 运行命令、测试和外部调用必须得到授权。
- 未授权时只生成验证计划和人工验证建议。
- 不顺手做新需求、无关重构或未授权修复。

## 核心流程

1. 汇总变更文件、交付物和验收标准。
2. 从当前来源和 03A 文件计算 `current_content_hash/recomputed_source_set_hash/recomputed_artifact_hash`；通过后才使用 03A 的验收矩阵。
3. 复核产品适配器：实施仓命中、变更落在 `owns[]`、实际范围不超过已批准的 adapter defaults，且 `risk_triggers[]` 所需证据齐全。适配器变化导致风险或默认值变化时，当前批准失效并回相应设计/决策阶段。
4. 按授权执行测试、静态检查，或标记为未授权/未验证。含前端/门户 UI 的 workstream 读取适配器登记的模块 UI Skill；无截图/样例 HTML/页面渲染证据时标「未走查」，不得把视觉验收写成通过。
5. 有代码 diff 时读取通用 `code-review`（并应用适配器的 `review_extras[]`）：只评安全、需求覆盖、最简实现；人审未确认前不得把代码审查写成通过。单测执行结论与通用 `unit-test`（并应用适配器的 `unit_test_extras[]`） 输出对齐，未跑不得冒充 passed。
6. 记录命令摘要、结论、失败项和残余风险。
7. 判断验收状态：通过、失败、部分通过或待人工确认。
8. **issue 门禁（事实优先）**：
   - 扫描 `issues/open|closed`、未完成 create binding/claim、create/close transaction、close manifest；再轻量校验 README。
   - 计算当前任务谓词并集：`task_blocking_predicate` ∪ `binding_task` ∪ `claim_task` ∪ `create_task` ∪ `manifest_task` ∪ `closing_task`。
   - `blocking=false` 且当前 task 既非 source create 也非 closing task 时，不因其他任务的未完成 transaction 被阻塞。
   - 项目其他活动/恢复对象只进项目摘要；`index-gap/duplicate-conflict` 进“需要你处理”，无关 gap 不篡改当前业务阶段。
   - 相关 blocking/recovery 未处理前，不得把整体交付标为完成，也不得 `next.skill=none`。
9. 未解决新问题 → `write-issue create`；命中既有活动/恢复 issue 只返回路径。验收通过且需关闭 issue → **`write-worklog draft`**（不是直接 close）。
10. 阶段迁移按 `00 → 任务 INDEX → 版本 INDEX 等待项 → trace` 同步。

## 输出

- 输出前读取 `references/verification-output.md`。
- 默认只输出一个 fenced YAML 代码块。
- 不复制完整命令输出，只记录命令、结果和关键错误摘要。
- 验收通过只表示当前子工作流通过；仍有其他 `workstreams` 时保留其下一动作。只有全部工作流完成、相关 blocking/recovery issue 已 `fully_closed` 或合法转出，且 worklog 已 finalize 时，`next.skill` 才能为 `none`。

## 转交

- 验收通过或阶段完成 → `write-worklog`（关闭 issue 时先 `draft`）。
- 有未处理问题 → `write-issue`，快照标记受影响子工作流 `blocked`。
- 验证失败且仍在授权范围内 → `implement-change`；否则快照为 `waiting-user`，明确唯一待确认动作。
