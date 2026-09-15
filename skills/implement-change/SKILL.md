---
name: implement-change
version: 0.3.8-public.1
description: 在需求访谈结束、需求分析、方案、必要决策、正式设计基线及必要的整合设计评审完成后，按授权边界实施代码或文档变更。本轮须已向决策者展示风险卡并获确认；未确认或范围扩大不得改文件。不改需求或方案，不自评代码审查通过。
---

# 开发实施（implement-change）

续作先恢复既有快照和本会话有效授权；用户已明确授权当前范围时不因新一轮消息重复要求启动风险卡。只有范围扩大、授权缺失/撤销或风险变化才补充确认。指纹准入必须调用 [统一工具](../aggregate-design/references/fingerprint-tool.md)；无版本旧值走证据恢复，不猜算法、不重开需求。

只在明确授权范围内完成代码、配置、测试或文档变更。

## 触发

- 用户明确授权开发、修复、重构或文档修改。
- `design-solution` 推荐进入实现。
- `make-decision-card` 已获得用户确认。
- `aggregate-design` 已获得人工对当前 hash 绑定 03A 的整体评审结论。

## 准入与边界

- 必须有 `task_card` 和明确授权边界。
- 续作快照的 `next.skill` 必须是 `implement-change`；否则先回 `ai-collab-start` 恢复当前阶段，不因动作词跨阶段实施。
- 本轮必须已经向决策者展示过风险卡（等级、协作模式、范围、依据），且用户已确认继续或纠正后再次确认。同轮刚出卡尚未得到回复、用户制止、或范围比已确认范围扩大时，回到 `ai-collab-start` 重新出卡，不得改文件。用户说「改成 X」不能代替风险卡确认。
- 必须加载主 `product` 与全部 `product_touchpoints[]` 的产品适配器并校验当前仓：
  - 主产品 `execution_status=executable` 且 `git_repo` 命中当前仓，才可继续实施。
  - `blocked-in-this-repo` 必须停止，返回适配器声明的 `git_repo/docs_root`；字段为 `missing_evidence` 时保持 `waiting-user`。
  - `catalog-only`、产品未登记，或当前动作依赖 `status=incomplete` 的缺失字段时必须 fail-closed，不得编造代码路径、模块 Skill、批量上限、回滚或停止线。
  - touchpoint 只叠加风险与所有权；若 `owns[]/does_not_own[]` 冲突，先回需求分析澄清归属，不得自行跨仓实施。
- `requirement_interview.status=continue-interview` 或 `ready-for-confirmation` 时不得实施，必须回到 `analyze-requirement`。
- R2 及以上必须有需求分析或方案摘要。
- R3/R4 必须有用户确认的决策卡，且 `execution_authorization.status=granted`；两者缺一不可。
- 若任务快照 `design_baseline.required=true`，必须存在状态为 `published` 的正式设计文件；否则回到 `design-solution`，不得实施。
- 准入前必须从当前文件重算，而不是仅比较快照字段：
  - 调用统一指纹工具重算 `current_content_hash`、`recomputed_source_set_hash` 和 `recomputed_artifact_hash`，要求它们分别与已登记指纹匹配。
  - 从当前 03A 第 1～11 章重算 `recomputed_artifact_hash`，要求其等于 `artifact_hash=reviewed_hash`。
  - 自举例外只可跳过“自身 03A 已批准”条件，不能跳过来源当前 hash、完整范围或授权 scope。
- 只要存在任一 published artifact，不论 `design_review.required` 当前值为何，都必须校验：
  - `design_review.status=approved`
  - `reviewed_hash=artifact_hash`
  - `reviewed_source_set_hash=source_set_hash`
  - 每个来源同时满足 `check_status=pass`、`checked_revision=source_revision`、`checked_hash=content_hash`
  - `workstreams[].design_required` 未显式为 `false` 的子流全部包含在 artifact `workstream_ids` 并集中
  - 来源集合未变化
- `check_status` 缺失/非法时执行 `invalid_check_status=blocked`；workstream 覆盖不完整、当前文件 hash 未重算或不匹配时同样 fail-closed，不得进入实施或猜测下一设计 Skill。
- 校验失败时唯一回流：
  - 任一来源 `check_status=fail` → `design-solution`
  - 来源变化、`check_status=pending`、缺失完整 `02A`、checked revision/hash 不匹配 → `check-design`
  - 03A 未生成、仅正文变化、waiting-review → `aggregate-design`
  - changes-requested → 仅按合法 `change_target=source|aggregation` 路由；缺失或非法值时 fail-closed，保持 `waiting-user` 并登记 blocker
- `execution_authorization` 必须记录授权人、时间和限域 scope；只能执行 scope 内动作。03A 批准、决策卡或历史 trace 都不能推导实施授权。
- 唯一例外：快照有已批准、未过期、scope 命中当前文件的 `bootstrap_exception`。例外不得扩展到其他任务或业务代码，并必须在独立复核通过后失效。

## 核心流程

1. 读取任务档案的当前快照、任务卡、产品适配器、决策批准状态、`execution_authorization` 和可选 `bootstrap_exception`。先校验产品执行状态、当前仓、所有权与授权 scope，再读取实施入口。
2. 从当前来源和 03A 文件计算 `current_content_hash/recomputed_source_set_hash/recomputed_artifact_hash`，完成 freshness 与 workstream 覆盖校验。
3. 若存在当前 hash 匹配且已批准的 03A，以其为默认完整实施入口；来源设计只在争议、freshness 或 gap 定位时读取。自举例外任务按例外中明确的正式设计和 scope 实施。
4. 识别模块开发规范，真正改代码前读取适配器登记的对应模块 Skill：
   - 路由/策略、RPC/REST、领域服务、集成策略类改动 → 适配器中登记的对应模块 Skill。
   - 外部集成、外部接口、运行配置类改动 → 适配器中登记的对应模块 Skill。
   - 前端/门户页面/样式/弹窗 → 适配器登记的模块 UI Skill。
   - 后端契约与前端同时涉及时，先定接口/定义再改前端模板；不得在前端补业务 ID 分支抵消后端缺口。
   - 多模块同时涉及时，先底层外部契约/实现，再上层调用。
5. 读取最小必要上下文，列出小步修改清单和目标文件。
6. 使用局部、可回滚改动，避免无关重构。改了业务代码且授权未排除测试时，读取通用 `unit-test`（并应用适配器的 `unit_test_extras[]`）：为本次行为补单测；跑测另需命令授权。
7. 每个有意义动作必须在同一轮更新 `00` 快照、任务/版本 INDEX，并追加 `06-AI作业追溯.md`。只写 trace 不改快照视为状态非法。不是每次落盘都升 `current_stage`：小改可只更新 `next.action` / workstream 状态 / 已完成说明，但不得让 `00` 仍写“尚未实施”。
8. 快照推进绑定工作完成（文件已改、结论已达成），不绑定 git commit。降级由人在 IDE 提交时，AI 仍须在改文件当轮记账；人补 commit 后只回填证据。完成后按 `00 → 任务 INDEX → 版本 INDEX 等待项 → trace` 的顺序交接给 `verify-delivery`（含通用 `code-review`（并应用适配器的 `review_extras[]`））；验证命令未授权时明确为 `waiting-user`。本会话刚写的业务代码不得在同轮宣称代码审查通过。

## 输出

- 准备实施或已实施时读取 `references/implementation-output.md`。
- 默认只输出一个 fenced YAML 代码块。
- 输出变更文件、授权动作、风险、回滚说明和 trace 更新，不复制源码。
- 阶段结果必须说明实施了哪个子工作流、下一验证动作和尚需授权；`next.skill` 非 `none` 时不得写成任务完成。

## 转交

- 实施完成 → `verify-delivery`。
- 发现超出范围的问题 → `write-issue`，并只阻塞受影响子工作流。
- 完成后由 `verify-delivery` 决定是否写 worklog 和把整体任务标为完成。
