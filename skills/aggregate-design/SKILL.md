---
name: aggregate-design
version: 0.5.1-public.1
description: 将同一任务完整来源集合中已自检且指纹匹配的正式设计编译为一个 hash 绑定、自包含、人工必审的 03A。单功能也生成 03A；禁止局部任务级批准、禁止发明契约、禁止新需求访谈。
---

# 聚合详细设计（aggregate-design）

将任务全部已发布正式设计编译为一份可独立阅读、可人工评审、可直接指导实施的完整详细设计。本 Skill 只处理设计文档和阶段状态，不改业务代码、不运行测试、不调用外部系统。

续作快照的 `next.skill` 不是 `aggregate-design` 时，不得因用户说“合并/整改/评审”自行重跑聚合；先回 `ai-collab-start` 恢复当前阶段和授权。

旧名 `prepare-design-review` 只作为用户说法兼容，不是执行入口。

## 产物与权威性

- 唯一产物：`docs/{项目}/tasks/{任务}/03A-聚合详细设计.md`。
- 03A 必须覆盖任务全部 published artifacts；单来源也必须生成。
- 不允许用“指定 workstreams”获得任务级 `waiting-review/approved`。
- `design_baseline.required=true` 时，`workstreams[].design_required` 未显式为 `false` 的子流均视为需设计；artifact `workstream_ids` 并集必须完整覆盖这些 id。
- 聚合完整范围谓词为 `workstream_union_complete=true`；为 false 时禁止生成任务级 `waiting-review/approved`。
- 来源设计是批准结论基线；03A 是完整任务级实施入口。
- 03A 可以重组、去重和统一术语，但不得创造新字段、新规则、新取舍或新授权。
- 人工评审对象只有 03A，不是来源设计或 `02A`。
- 当前状态仍只维护在 `00-需求概览.md`。

## 指纹不变量

聚合准入必须满足每个来源：

- `check_status=pass`
- `checked_revision=source_revision`
- `checked_hash=content_hash`
- artifact `workstream_ids` 并集覆盖全部需设计 workstream

生成、批准和校验统一读取 [fingerprint-tool.md](references/fingerprint-tool.md)，调用固定工具；禁止临时编写另一套算法。新指纹协议为 `design-sha256-v1`，以工具协议定义精确字节。无版本的历史指纹先恢复证据，不套用新算法判定内容漂移，不枚举算法。

生成正文后记录：

- `artifact_revision`
- `hash_version`（03A 文首与 00.design_review 同步）
- `artifact_hash`
- `source_set_hash`

人工批准必须绑定：

- `reviewed_hash=artifact_hash`
- `reviewed_source_set_hash=source_set_hash`

变化规则：

- 来源变化：`design_review=stale`，来源 `check_status=pending`，清空 checked/reviewed 指纹，先回 `check-design`。
- 03A 内容变化但来源未变：`design_review=waiting-review`，清空 `reviewed_hash`，重新人审。
- reviewed 指纹不匹配时，`approved` 无效。

## 触发

- 任务至少发布一份正式设计，完整来源集合全部自检通过且指纹匹配。
- 用户要求聚合设计、完整详细设计、总体技术评审或评审包。
- 单功能、低风险但已发布正式设计的任务同样适用。

未发布正式设计的局部 R0-R2 任务可以 `design_review.required=false`；必须在方案评估中说明。

## 准入

必须同时满足：

- 没有活跃的 `continue-interview/ready-for-confirmation`；需求状态为 `ready-to-draft/not-required`，或明确无需访谈且边界已确认。
- 纳入范围的决策均已批准，来源状态为“有效”。
- `design_baseline.status=published`，并登记任务全部 published artifacts。
- 全部需设计 workstream 已被 artifact `workstream_ids` 并集覆盖。
- `02A` 包含全部来源，且每份来源满足指纹不变量。
- 已获得生成/更新 03A、`00`、任务 INDEX、版本 INDEX 等待项和 trace 的限域文档写入授权。
- 冷启动顺序：版本 INDEX → 唯一任务定位 → 任务 INDEX → `00` → `issues/README.md` → `03` 顶部确认表 → 完整 `02A` → 全部来源。

准入失败按原因唯一转交：

| 缺口 | 下一 Skill/动作 |
|---|---|
| 决策未批准 | `make-decision-card` |
| 来源未发布或状态无效 | `design-solution` |
| `02A` 缺失、来源 pending 或 checked 指纹不匹配 | `check-design` |
| 来源已 fail | `design-solution` |
| `check_status` 缺失/非法 | `invalid_check_status=blocked`；fail-closed 保持当前阶段并登记 blocker，不猜测路由 |
| workstream 覆盖不完整 | `design-solution` 补齐来源或映射 |
| 写入授权缺失 | 当前 Skill `waiting-user` |
| 任务/路径不唯一 | `blocked` / 询问用户 |

## 来源读取

1. 只从 `00.design_baseline.artifacts` 取得完整范围；不扫描 `design/`，不接受局部范围参数；校验 `workstream_ids` 并集覆盖全部需设计 workstream。
2. 重新计算来源当前 `current_content_hash`，并与 `content_hash/checked_hash` 比较。
3. 读取每份来源全文、完整 `02A` 和 `03` 顶部确认表。
4. 记录路径、workstream、决策、revision、content hash 和目标章节。
5. `01/02` 或代码证据只用于消除歧义；未批准内容不能写成契约。

## 聚合工作流

1. **锁定完整范围**：纳入任务全部 published artifacts，计算 `source_set_hash`。
2. **统一语言**：统一角色、模块、接口、字段、状态、错误码、配置和缓存键。
3. **建立人审导览**：用一句“怎么读”说明第 1～10 章各自回答的问题，并注明第 11 章只供追溯与 freshness 核验。
4. **建立总体设计**：按“概述 → 系统架构 → 逻辑流程”先回答做什么、系统怎么拆、链路怎么跑。
5. **展开每个 workstream**：按“问题与目标 → 设计思路与边界 → 改动落点 → 流程与失败路径 → 关键契约 → 验收与回滚”组织，不为凑固定小节重复内容。
6. **建立契约总览**：第 5 章只汇总接口、关键字段、表/状态/缓存、配置和错误表现；详细规则在对应功能章节只写一次。
7. **执行一致性检查**：边界、所有权、隔离、默认值、重试/幂等、缓存、兼容、安全、可观测、回滚、顺序和测试。
8. **执行来源覆盖检查**：证明每份来源全部实施章节进入正文。
9. **分类发现**：
   - `aggregation-gap`：来源已有内容未进入 03A；留在本 Skill 重编，不修改来源。
   - `source-gap`：来源自身缺少实施必需契约；相关来源置 `fail`，回 `design-solution`。
   - `source-conflict`：来源互相矛盾；相关来源置 `fail`，回 `design-solution`。
10. **生成 03A**：使用模板，写 `artifact_revision/artifact_hash/source_set_hash`。
11. **更新状态并等待评审**：先 `00`，再任务 INDEX、版本 INDEX 等待项，最后 trace；生成不等于批准。

## 每个 workstream 的必填内容

以下是**内容覆盖要求，不是固定小节目录**。优先合并成 5～6 个自然段、小表或流程图；禁止为了逐项打勾生成 12 个空壳小节。

1. 需求目标、用户场景、包含和排除范围。
2. 现状与问题根因。
3. 模块、组件、类/资源/文件和职责。
4. 主流程、分支和异常流程；跨模块流程用 Mermaid。
5. API/RPC/事件：路径/方法、调用方、权限、请求、响应、错误和兼容。
6. 数据与状态：表、字段、所有权、状态、缓存、生命周期和隔离。
7. 配置：namespace、key、类型、枚举、默认值、非法值、刷新和回退。
8. 业务规则：优先级、条件、幂等、重试、回退、并发和边界。
9. 安全与隐私：鉴权、数据范围、敏感字段和脱敏。
10. 可观测性：日志、指标、告警和排障证据。
11. 兼容、迁移、灰度、回滚和停止条件。
12. 实施步骤、依赖、文件落点和验证用例。

不适用项必须写“无/不适用 + 原因”。

## 人工评审可读性约束

- 第 1～10 章面向人审与实施，使用业务结果和工程动作语言；第 11 章承载来源、hash、覆盖映射等审计细节。
- 文首必须有“怎么读这份文档”，告诉评审者先看范围、架构、流程和功能设计；第 11 章默认可跳过。
- 第 1 章先给“要交付的功能”表，列出效果、主要改动位置和对应功能章节，再说明做与不做。
- 第 2 章使用轻量 C4 风格的系统上下文、容器/模块关系；存量增量必须明确是否换技术栈、拆服务、改数据库或部署拓扑，但不强制另产 `architecture.md` 或 ADR。
- 第 3 章按真实独立链路拆流程；无共享事务的功能不得强行串成一张总流程图。
- 第 4 章每个 workstream 先讲问题、思路和改动位置，再讲流程、失败路径与契约；标题用人能理解的功能结果，不直接使用晦涩 workstream id。
- 第 5 章只做跨功能查阅总表，不复制第 4 章的长协议；安全与监控、实施顺序、风险回滚、验收分别放第 6～9 章。
- 正文不得要求评审者打开来源设计才能理解。来源路径、指纹、章节覆盖只放第 11 章；正文允许少量 `§X.Y` 内部引用，但同一结论应完整写在一个位置，其他位置只做一句摘要。
- 治理术语、hash 算法和 fail-closed 规则不得贯穿业务正文；它们应压缩在第 0、10、11 章，且不能因此删减或改变门控语义。
- 表格用于快速比较，Mermaid 用于系统关系或关键时序；简单事实直接用短段落或列表，不为形式强行画图。
- 标题、表头和说明优先使用中文业务语言；必须保留的字段名、错误码、配置键和状态值使用代码格式。

## 自包含门控

出现以下任一情况，不得进入 `waiting-review`：

- 链接代替实施正文。
- 任一来源章节未映射。
- 接口、配置、数据、异常、实施或验证不完整。
- 只写跨模块流程，不写内部流程。
- 自行发明来源没有的结论。
- 来源或 03A 指纹缺失。
- 来源集合不完整。
- 存在 `source-gap/source-conflict`。

`aggregation-gap` 只允许保持 `design_review=pending` 并在本 Skill 内重编。

## 人工评审与状态

- 生成且门控通过：
  - `design_review.status=waiting-review`
  - 保存 `artifact_revision/artifact_hash/source_set_hash`
  - `current_stage=design-review`
  - `status=waiting-user`
  - `next.skill=aggregate-design`
- 人工批准前重新计算 03A 和来源集合 hash：
  - 匹配时写 `reviewed_hash/reviewed_source_set_hash`，状态 `approved`
  - 不匹配时拒绝批准并按变化类型回流
- “附条件批准”统一视为 `changes-requested`；条件关闭并重新评审前不得 `approved`。
- `changes-requested` 必须记录：
  - `change_target=aggregation` → 本 Skill 重编。
  - `change_target=source` → `design-solution`，修正后 `check-design`。
- `changes-requested` 的 `change_target` 缺失或非法时必须 fail-closed：保持 `status=waiting-user`，登记 blocker，不猜测重编或回源。
- 批准后 `next.skill=implement-change`，但 `execution_authorization.status` 仍须独立为 `granted`。

## 禁止

- 局部 workstream 使用任务级 03A 路径或批准状态。
- 未重算 hash 就接受人工批准。
- 来源失败却继续聚合。
- 把 gap 当成新需求访谈。
- 03A 批准推导出实施授权。

## 和其他 Skill 的关系

- 尚未自检或来源变化：`check-design`。
- 来源缺失、失败或冲突：`design-solution`。
- 决策未批准：`make-decision-card`。
- 03A 已批准且另获实施授权：`implement-change`。
- 记录过程：`write-ai-trace`。
