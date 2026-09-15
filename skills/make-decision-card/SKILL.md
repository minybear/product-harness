---
name: make-decision-card
version: 0.1.6-public.1
description: 为需求访谈已结束的 R3/R4、高风险、跨模块、生产、批量、数据、配置或外部接口任务生成短决策卡，并在确认后路由正式设计发布或实施。不替代审批，不执行变更，不替代需求分析或方案设计。
---

# 决策卡（make-decision-card）

帮助人基于证据快速决策，不替代审批，不执行变更。

决策卡是短入口，不是需求、方案或 trace 的替代品。当前路由以任务 INDEX 和 `00-需求概览.md` 为准。

## 触发

- `ai-collab-start` 或 `design-solution` 判定需要决策卡。
- 目标风险为 R3/R4。
- 涉及生产、批量、不可逆、证书密钥、计费、数据库、配置、生产批量操作或外部接口。
- 用户要求风险评审、拍板或决策卡。

## 准入

- 必须有需求分析或方案摘要，且至少有一个候选方案。
- `requirement_interview.status=continue-interview` 或 `ready-for-confirmation` 时，回到 `analyze-requirement`，不得提前生成决策卡。
- R4 必须包含准入标准、影响范围、回滚、停止条件和人工授权点。
- 必须加载主产品与 touchpoint 适配器；决策卡不得缩小适配器风险等级或放宽其爆炸半径、回滚和停止线默认值。
- 证据不足时回到需求分析或方案设计，不用结论填空。

## 核心流程

1. 读取版本/任务 INDEX、`00-需求概览.md`，再按需读取需求分析、方案相关段落、证据摘要、风险记录和关联 issue；不默认加载完整 trace。
2. 核对适配器 `status/execution_status/owns[]/risk_triggers[]`；把命中的产品触发器和证据要求写入卡片。`missing_evidence` 或所有权冲突必须成为 blocker。
3. 压缩为一页决策入口：推荐结论、关键证据、阻塞项和可接受风险。
4. 明确环境、租户/数据/设备/外部系统影响范围，且不得宽于适配器默认值。
5. 对 R3/R4 补齐准入标准、回滚策略和停止条件；适配器默认项只能收紧或经有权角色显式风险接受后调整。
6. 明确需要哪个角色做出什么决定。
7. 读取任务快照的 `design_baseline.required`；用户授权落盘时更新 `tasks/{任务}/03-决策记录.md` 的顶部当前确认表、`00-需求概览.md`、任务 INDEX，并追加 trace。生成时的原始 YAML 只能作为历史快照保存。

## 输出

- 输出或落盘前读取 `references/decision-card-output.md`。
- 默认只输出一个 fenced YAML 代码块。
- 每条证据必须有来源路径或命令摘要。
- 不复制需求全文、方案全文、源码或长日志。
- `03-决策记录.md` 顶部人工确认表是当前决策状态；生成时的 handoff、status 或 next skill 字段必须明确标为历史快照，不得参与路由。
- 未获得决策时，快照状态必须是 `waiting-user`，`next.skill` 保持唯一且为 `make-decision-card`；不得把“已生成卡片”写成“已批准”。

## 转交

- 用户确认且 `design_baseline.required=true` → `design-solution`，将当前阶段设为 `design-publication`；正式设计未发布前不得实施。
- 用户确认、`design_baseline.required=false` 且实施边界完整 → `implement-change`；只有决策与操作授权均明确时才可实施。
- 用户确认后必须同步当前快照和任务 INDEX 的 `next.skill`；不得因历史卡片仍写着 `make-decision-card` 而重复进入决策卡。
- 证据不足 → `analyze-requirement` 或 `design-solution`，并把缺口写为可恢复的 blocker。
- 风险不可接受或暂不处理 → `write-issue` 或停止，并在快照标记对应子工作流而非笼统结束整个任务。
