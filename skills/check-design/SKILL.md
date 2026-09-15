---
name: check-design
version: 0.2.1
description: 在正式设计发布后、融合 03A 前，对完整来源集合执行带内容指纹的 AI 自检（证据链、细节闭环、说法自洽）。自检失败退回 design-solution；禁止融合、禁止新需求访谈、禁止沿用旧 pass。
---

# 设计自检（check-design）

来源指纹统一由 [指纹工具](../aggregate-design/references/fingerprint-tool.md) 计算；来源 content_hash 为原始文件字节 SHA-256。旧聚合 hash 无法复现不自动触发来源重设计，先恢复算法和批准证据。

续作快照的 `next.skill` 不是 `check-design` 时，不得自行开始自检；先回 `ai-collab-start` 恢复任务路由。自检失败只回来源设计门控，不开启新需求访谈。

对任务全部已发布正式设计执行融合前自检。本 Skill 不生成 03A，不发明契约，不把实现 HOW 或现网偏差升级成新需求。

## 产物与不变量

- 产物：`docs/{项目}/tasks/{任务}/02A-设计自检.md`。
- 每次写入必须包含任务全部 published artifacts；不得用局部重检覆盖掉其他来源证据。
- 每个来源记录 `source_revision/content_hash/checked_revision/checked_hash/check_status/check_report`。
- `pass` 仅在 `checked_revision=source_revision` 且 `checked_hash=content_hash` 时有效。
- `design_baseline.required=true` 时，`workstreams[].design_required` 未显式为 `false` 的子流均视为需设计；artifact `workstream_ids` 并集必须完整覆盖这些 id。
- 完整范围谓词记为 `workstream_union_complete=true`；只有该谓词成立才可生成任务级自检结论。
- 来源内容或 revision 变化后必须原子执行：
  - `check_status=pending`
  - 清空 `checked_revision/checked_hash`
  - `design_review.status=stale`
  - 清空 `reviewed_hash/reviewed_source_set_hash`
  - `next.skill=check-design`
- `02A` 是过程材料，不是正式设计，也不是人工评审对象。

## 触发

- `design-solution` 发布或修正正式设计后。
- 来源指纹变化导致 03A `stale` 后。
- 用户说「整合评审 / prepare-design-review」且快照显示来源未自检时，由 `ai-collab-start` 映射到本 Skill。

自检失败不会再次路由到本 Skill；必须先回 `design-solution` 修正来源。

## 准入

必须同时满足：

- 没有活跃的 `continue-interview/ready-for-confirmation`；需求状态为 `ready-to-draft/not-required`，或快照明确记录无需访谈且边界已确认。
- 纳入范围的决策已批准，正式设计状态为“有效”。
- `design_baseline.status=published`，并登记任务全部 published artifacts。
- 每个 artifact 有非空 `workstream_ids[]/path/source_revision/content_hash`；一份来源可覆盖多个 workstream。缺失映射或指纹时置 `pending`，不能沿用旧 `pass`。
- `workstream_ids` 并集未覆盖全部需设计 workstream 时不进入自检，转 `design-solution` 补齐来源或映射。
- 快照存在 `design_check_authorization.status=granted`，授权范围只包含：
  - `02A-设计自检.md`
  - `00-需求概览.md`
  - 任务 INDEX
  - 版本 INDEX 中本任务的等待项
  - `06-AI作业追溯.md`
- 冷启动顺序：版本 INDEX → 唯一任务定位 → 任务 INDEX → `00` → `issues/README.md` → `03` 顶部确认表。

准入失败按原因唯一转交：

| 缺口 | 状态/下一 Skill |
|---|---|
| 决策未批准 | `make-decision-card` |
| 来源未发布或状态无效 | `design-solution` |
| 指纹缺失 | `design-solution` 补齐发布元数据 |
| 需设计 workstream 覆盖不完整 | `design-solution` 补齐来源或 `workstream_ids` 映射 |
| 既有 `check_status` 缺失/非法 | `invalid_check_status=blocked`；保持当前阶段、登记 blocker，再修复状态证据 |
| 限域授权缺失 | 当前 Skill `waiting-user`，不得写文件 |
| 路径损坏或任务不唯一 | `blocked` / 询问用户 |

## 自检清单

三项全部必做。任一项失败，该来源整体 `fail`。未核到即失败，不能写成通过。同会话允许执行，但必须逐项给证据。

### 1. 证据链

通过：规则、契约、取舍能指到已确认需求、已批准决策、现存代码/配置或原型；每条结论记录来源路径。

失败：结论无来源；未核到却标通过；用未批准访谈猜测填契约。

### 2. 细节闭环

通过：已写出的接口含调用方、路径/方法、请求、响应、错误、权限；配置含类型、默认值、非法值和回退；数据含所有者、生命周期和隔离；流程含异常分支。不适用必须写“无/不适用 + 原因”。

失败：只写接口名、配置 key、对象名，或缺错误语义/默认值却当完整。

本项不核对字段能否被现网 DTO/API 承载；发布映射门属于后续独立能力。

### 3. 说法自洽

通过：同一任务所有来源以及单份内部的名称、错误语义、所有者、默认值、包含/排除范围一致。

失败：同名字段多套含义；一处要求 03A，另一处允许单功能跳过。

## 工作流

1. 只从 `00.design_baseline.artifacts` 获取完整来源集合，不扫描 `design/` 猜范围；先验证 `workstream_ids` 并集覆盖全部需设计 workstream。
2. 重新计算每份来源 SHA-256 得到当前 `current_content_hash`；更新 `content_hash`，并比较已有 `checked_hash`。
3. 读取每份来源全文和 `03` 顶部已批准决策；按需读取代码或 `01` 已确认段落。
4. 按 `workstream_ids + path` 逐份执行三项检查；失败只影响该来源映射的 workstreams。
5. 按模板覆盖写完整 `02A`；报告包含全部 artifacts 和本次 `report_revision`。
6. 对通过来源写入 `checked_revision/source_revision`、`checked_hash/content_hash` 和 `pass`；失败来源写 `fail`，不得保留旧 checked 指纹。
7. 先更新 `00`，再同步任务 INDEX、版本 INDEX 等待项，最后追加 trace。
8. 执行转交；不要求人确认自检结果，不打开新需求访谈。

## 禁止

- 没有 `design_check_authorization` 就自动落盘。
- 只重检部分来源却覆盖完整报告。
- 在来源设计文首写过程状态。
- 生成或更新 03A。
- 把未检查项标为 pass。
- 把自检失败重新路由到 `check-design`。
- 在 workstream 覆盖不完整时生成任务级完整自检结论。

## 状态与转交

- 全部来源 `pass` 且指纹匹配：
  - `next.skill=aggregate-design`
  - `status=ready`
  - 不等待人确认自检。
- 任一来源 `fail`：
  - 仅关联 workstream 标记失败/阻塞
  - `next.skill=design-solution`
  - 其他独立 workstream 不被笼统阻塞
  - 默认动作是“修正来源设计”，不是“补充新需求”。
- 来源变化：按不变量回 `pending/stale → check-design`。

## 和其他 Skill 的关系

- 来源未发布、缺失或失败：`design-solution`。
- 全部通过后融合完整任务 03A：`aggregate-design`。
- 记录过程：`write-ai-trace`。
