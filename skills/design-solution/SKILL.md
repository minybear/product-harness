---
name: design-solution
version: 0.3.7-public.1
description: 在需求分析后评估可实施方案，并在决策确认后按需发布 docs/{项目}/design/ 正式设计基线。涉及协议/外部系统接口时复用并加深 01 领域证据；涉及门户展示时挂载适配器登记的模块 UI Skill。用于方案比较、技术设计、接口/配置/数据设计和设计发布；正式设计发布后转 check-design，不写业务代码。
---

# 方案评估与正式设计发布（design-solution）

本 Skill 有两个连续但不同的模式：先在任务档案中做**方案评估**，再在必要时把已确认结论发布成 `design/` 下可复用的**正式设计基线**。不写业务代码、不运行测试、不调用外部接口、不操作数据库或部署。

续作先恢复任务快照；正式设计发布时，来源文件的 `content_hash` 必须调用 [统一指纹工具](../aggregate-design/references/fingerprint-tool.md) 的 `file` 命令计算，不得临时约定规范化、换行或摘要口径。该工具只提供指纹，不替代需求、决策和发布授权。

## 准入

- 必须有需求分析，或至少有明确目标、范围和验收标准。
- `requirement_interview.status=continue-interview` 或 `ready-for-confirmation` 时回到 `analyze-requirement`，不得用方案评估替代访谈。
- R3/R4 必须覆盖影响范围、回滚思路和停止条件。
- 必须加载主 `product` 与全部 `product_touchpoints[]` 的适配器。方案只能在 `owns[]` 边界内落位，并以适配器默认值补充爆炸半径、回滚与停止线；缺失值不得猜测。
- 落盘前确认允许创建或更新归档文档。
- 读取 `../write-plan/references/stage-handoff.md`，以任务档案的快照决定当前模式和唯一下一步。
- 冷启动或续作先读取 `docs/{项目}/INDEX.md`、`tasks/{任务}/INDEX.md` 和 `00-需求概览.md`；索引只负责定位，不替代正文状态。
- 续作快照的 `next.skill` 不是 `design-solution` 时，不得自行启动方案或发布模式；退回 `ai-collab-start` 按快照路由。用户动作词不改变当前阶段。

## 领域证据（P1）

涉及协议/数据模型/业务对象接口、编解码、绑定、路由、错误码映射，或变更 领域协议或外部服务 等外部连接行为时，读取 `../analyze-requirement/references/domain-research.md`：

1. **先复用** `01-需求分析.md` 证据索引中的领域摘要，统一术语，不从零科普。
2. 设计需要落地的条款必须有 `confirmed` 证据；仅有 `inferred/unknown` 时先补查代码/文档/规范，或标为开放问题/不纳入范围。
3. 正式设计中的协议字段、状态机、错误语义、重试/幂等、鉴权不得只靠推断；否则 `waiting-user` 或回 `analyze-requirement` 补证据。
4. 未命中领域词且无协议契约变更时，跳过本门控。

## 模式 A：方案评估

适用于 `current_stage=requirement-analysis` 或 `solution-evaluation`。

1. 读取版本/任务 INDEX、`00-需求概览.md`，再读取需求分析、`task_card`、相关证据；不要默认加载完整 trace 或无关任务文档。
2. 按「领域证据（P1）」判断是否需要复用/加深调研；需要时先完成摘要再比较方案。
3. 合并产品适配器：风险取通用模型与全部 `risk_triggers[]` 的最高值；以 `blast_radius_defaults/rollback_defaults/stop_lines` 作为最低边界。字段为 `missing_evidence`、`catalog-only` 或所有权冲突时，先形成开放问题并停止实施路由。
4. 按需读取适配器登记的 `module_skills[]`，按受影响模块取对应 Skill（路由/策略、外部集成、门户页面/弹窗/展示模板各自对应适配器中登记的模块 Skill）。不得为其他仓编造模块 Skill。
5. 简单任务只给 1 个方案，复杂任务最多 3 个；比较改动、影响、测试、回滚和风险。校验强度、兼容老调用还是破坏性变更、鉴权/防重放怎么落地，在本模式比较，并引用 `01` 与勘察证据；不得把这类 A/B 前移到 `ai-collab-start` 或未完成现状勘察的访谈首轮。方案涉及配置变更时，每个选项必须写清 **前端配置入口** 取舍：扩展现有配置页、新增前端表单/菜单，或明确 **仅运维手推** 及运维路径；不得只写“加配置项”而不判前端暴露面。
6. 明确推荐方案、开放问题和每个 workstream 的状态；协议相关取舍必须引用领域证据。推荐方案若需前端配置入口，在 `impacted_modules` 中包含前端/门户模块，并挂载适配器登记的模块 UI Skill 写菜单归属、字段与校验；仅运维手推须在开放问题或风险中说明用户不可自助修改的影响。
7. 按正式设计基线判定规则标记 `design_baseline.required`，并列出未来应发布的设计文档及模块。
8. 用户授权落盘时更新 `tasks/{task}/02-方案评估.md`、任务 INDEX、版本 INDEX、快照和 trace；不得把未确认的候选方案写入 `design/`。

## 模式 B：正式设计发布

适用于 `current_stage=design-publication`，且 `design_baseline.required=true`。

1. 读取任务 INDEX、`00-需求概览.md`、相关 `02-方案评估.md` 和已确认的 `decision_ref`：
   - R3/R4：`03-决策记录.md` 顶部已批准决策。
   - R0-R2：持久化的轻量方案确认；不得只从聊天或历史 trace 推断。
2. 若设计含协议/外部系统契约，按「领域证据（P1）」复核：将写入正文的条款升为 `confirmed` 或排除出范围。
3. 按 `references/design-publication.md` 为每个受影响模块创建或更新 `docs/{项目}/design/{模块}/{主题}-设计.md`，并更新 `design/README.md`、版本 INDEX 和任务 INDEX。
4. 正式设计只写已确认的范围、契约、配置/数据、兼容性、回滚、验证和变更控制；不保留 A/B/C 候选、访谈问题或完整 trace。协议依据写入设计中的证据/依据小节，与 `01` 摘要对齐。配置章节必须对齐 `01` 的前端入口决策：需前端入口时在「数据、配置与兼容性」写配置键/命名空间、读写路径、目标菜单/页面、字段校验与权限；仅运维手推须写维护角色与不发版改值路径。含前端/门户展示或配置页时按适配器登记的模块 UI Skill 写入信息层级、数据归属、模板策略、状态与样式边界。
5. 每份设计记录来源 `task_id`、`decision_ref`、状态和 `source_revision`。发布后调用统一工具 `file` 计算原始文件字节 SHA-256，并原子写入 artifact：
   - `workstream_ids[]/path/module/title`
   - `source_revision/content_hash`
   - `check_status=pending`
   - 清空 `checked_revision/checked_hash/check_report`
   - 校验 `workstreams[].design_required` 未显式为 `false` 的子流均被 artifact `workstream_ids` 并集覆盖；缺口未关闭时不得发布完成
6. 只要存在至少一份 published artifact，必须在同一次状态迁移中设置：
   - `design_review.required=true`
   - `design_review.status=pending`
   - 清空旧 `artifact_hash/source_set_hash/reviewed_hash/reviewed_source_set_hash`
   - `next.skill=check-design`
   实施和验证不得依赖可能错误的 `required=false` 放行。
7. `check-design` 落盘需要独立的限域 `design_check_authorization`。若用户在发布授权中明确同时授予，则写入授权范围后转 ready；否则 `check-design` 保持 waiting-user，不得自动写 `02A/00/INDEX/trace`。
8. 凡已发布正式设计，都必须先自检再融合完整任务 03A；不得以单功能或低风险跳过。缺少决策、关键事实、领域 confirmed 证据、指纹或授权时保持 `waiting-user/blocked`，并按原因写唯一下一步。
9. 发布后将 `02-方案评估.md` 标记为评估归档，只保留候选方案、取舍理由和未决事项；实施读取正式设计，不重复读取整篇方案评估。

## 输出与转交

- 方案评估输出或落盘前读取 `references/solution-design-output.md`；正式设计发布前读取 `references/design-publication.md`。
- 默认对话只输出一个简短 YAML 结果；正式设计正文仅在获得落盘授权时写入目标文件。
- 方案超过 3 个，说明需求尚未收敛，回到 `analyze-requirement`。
- 领域证据不足且阻塞契约 → `analyze-requirement` 或 `waiting-user`，不得用推断发布正式设计。
- R0-R2 且 `design_baseline.required=false` → `implement-change`，但新操作授权不足时为 `waiting-user`。
- R3/R4、批量、生产、不可逆或需拍板 → `make-decision-card`；卡片未获批不得发布正式设计或实施。
- 决策获批且需要正式设计 → `design-solution`（`design-publication`）；正式设计发布后 → `check-design` → `aggregate-design` → 人工批准 hash 绑定的 03A；未发布正式设计且实施边界完整才转 `implement-change`。
- 暂不处理的阻塞问题 → `write-issue`，只阻塞受影响 workstream。
- 聚合前读取路径为：任务 INDEX → `00-需求概览.md` → 全部相关 `design/{模块}/` → `03-决策记录.md` 顶部确认表。聚合批准后，实施默认读取 `03A-聚合详细设计.md`，单功能来源只用于审计和 freshness 核验。
