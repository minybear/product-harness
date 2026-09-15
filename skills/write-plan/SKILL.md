---
name: write-plan
version: 1.7.3-public.1
description: 为已完成需求访谈或无需访谈的需求维护 docs/{项目}/tasks/ 任务档案、版本/任务索引与可恢复阶段交接。建档前须按 init-project-docs 核验并补齐项目骨架；项目目录已存在不得跳过。Skill 名 write-plan 仅为兼容旧路由；新任务不得写入顶层 plan/。不发布正式设计，不替代需求分析。
---

# 维护任务档案（write-plan）

本 Skill 名保留 `write-plan` 以兼容现有路由；实际职责是维护一项需求/修复的**任务档案**。`tasks/` 是任务身份和过程文档的唯一根目录，`04-实施计划.md` 才是严格意义上的计划。

## 第一原则

- 一个需求只对应一个 task 目录；日期只用于首次命名，跨工作日必须复用。
- `00-需求概览`、`01-需求分析`、方案评估、决策记录、聚合详细设计、实施/验证计划和 trace 都是任务过程材料，放在 `tasks/`；`design/` 保存聚合所依赖的单功能/单模块来源基线。
- `design/` 只保存已确认、可复用、长期有效的正式设计；不得复制候选方案、未决问题、完整访谈或 trace。
- 若需正式设计基线，由 `design-solution` 在决策确认后发布；本 Skill 只初始化/维护任务档案和快照。
- 建档或续作落盘前，必须按 `init-project-docs` 的骨架完备判定检查 `INDEX` / `tasks` / `design` / `logs` / `issues`；不完备则先转该 Skill 补齐，不得因 `docs/{项目}/` 已存在或已有 `tasks/` 而只建任务目录。
- 版本级 `docs/{项目}/INDEX.md` 和任务级 `tasks/{任务}/INDEX.md` 是检索入口；索引只写路由、状态、链接和短摘要，不复制正文。
- `requirement_interview.status=continue-interview` 或 `ready-for-confirmation` 时立即停止，回到 `analyze-requirement`；`Qn` 回答不是建档授权。

## 阶段交接快照

读取 `references/stage-handoff.md` 和 `references/document-index.md`。有任务档案时，`00-需求概览.md` 的“当前工作流快照”是唯一当前状态源；`INDEX.md` 只做检索路由，`tasks/README.md` 只显示摘要，`06-AI作业追溯.md` 只记录历史。

- 新建 task 时初始化快照、正式设计基线、设计自检授权、聚合评审和实施授权；续作先恢复唯一 `next.skill`。
- 每次跨阶段、阻塞恢复、阶段完成、决策确认、正式设计发布、用户授权变化或落盘实施时更新快照和 README 摘要；禁止只追加 trace。快照跟工作完成，不跟 git commit。
- 每次上述状态变化同步更新任务 `INDEX.md`；版本级 `docs/{项目}/INDEX.md` 在新增任务或新增正式设计时更新。
- 两条及以上独立子需求使用 `workstreams`，一个 blocker 不得笼统阻塞其他已就绪子项。
- 版本 INDEX 和任务 INDEX 必须同步维护“需要你处理”区；每个 `waiting-user` / `blocked` 子流都要写清等待内容和用户可直接回复的动作。
- 未获落盘授权时只展示等价进度卡，不创建或更新 task 文件。

## 目录结构

```text
docs/{项目}/
├── INDEX.md                                   # 版本级检索入口
├── tasks/                                      # 任务档案：随任务推进
│   ├── README.md                               # 任务索引和摘要状态
│   └── {createdDate}-{模块}-{需求名}/
│       ├── INDEX.md                            # 当前任务检索入口
│       ├── 00-需求概览.md                      # 身份、背景、范围、验收、快照
│       ├── 01-需求分析.md                      # 澄清结论、事实、假设、风险
│       ├── 02-方案评估.md                      # 候选方案、取舍、推荐、正式设计需求
│       ├── 02A-设计自检.md                     # 融合前自检（check-design，按需覆盖写）
│       ├── 03-决策记录.md                      # 决策卡、人工确认、条件与证据
│       ├── 03A-聚合详细设计.md                 # 自包含实施契约与人工评审（凡已发布正式设计即生成）
│       ├── 04-实施计划.md                      # 拆分、依赖、授权与验收点
│       ├── 05-验证计划.md                      # 验证范围、策略和必要用例
│       └── 06-AI作业追溯.md                    # AI 过程和阶段迁移历史
├── design/                                     # 仅已确认的长期设计基线
│   └── {模块}/{主题}-设计.md
├── logs/
└── issues/
```

小任务至少创建 `00/01/02/06`；`03/03A/04/05` 仅在存在决策、整体评审、实施或验证工作时创建。`design/` 文件由 `design-solution` 按需发布，`02A` 由 `check-design` 生成，`03A` 由 `aggregate-design` 在自检通过后生成；凡已发布正式设计都必须自检并出 03A，均不在建档时预创建。

## 旧目录兼容与迁移

- `docs/{项目}/plan/{createdDate}-{模块}-{需求名}/` 是旧版任务档案路径，只读定位优先级低于 `tasks/`。
- 新任务一律创建在 `tasks/`；不得新建顶层 `plan/` 任务目录。
- 迁移旧任务需要用户明确授权：移动整个任务目录到 `tasks/`，更新索引和可点击链接，保留 `plan/README.md` 的迁移说明；不得复制出两份可同时续作的状态源。

## 续作定位规则

创建新 task 前按以下优先级查找：

1. 用户显式提供的 task 路径、旧 plan 路径、目录名或 `task_id`。
2. `docs/{项目}/tasks/README.md` 中进行中、未完成或待确认任务。
3. `docs/{项目}/tasks/*/00-需求概览.md` 的标题、模块、关键词。
4. 旧 `docs/{项目}/plan/README.md` 与 `plan/*/00-需求概览.md`（仅兼容读取）。
5. 当前会话刚创建或刚引用的任务目录。

- 唯一匹配：复用该 task，更新相关文件并追加 trace。
- 多个候选：列出候选让用户确认。
- 找不到且明确是新需求：创建新 task。
- 找不到但用户说“继续 / 接着 / 上次 / 这个需求”：必须询问，不得新建。

## 工作流程

1. 检查访谈门控；仅 `ready-to-draft` 或无需访谈时继续。
2. 识别项目、模块、需求标题、任务类型和产品域。
3. **骨架核验**：按 `init-project-docs` 完备判定检查项目骨架。不完备则先执行该 Skill 补齐（已获本 Skill 落盘授权时不必再单独确认），再继续本流程；已完备不得重复创建。
4. 按“续作定位规则”查找 task；新建时写入 `docs/{项目}/tasks/{createdDate}-{模块}-{需求名}/`。
5. 初始化任务 `INDEX/00/01/02/06`，按需要增加 `03/04/05`；更新版本 INDEX 与 `tasks/README.md`。
6. 每次生成或更新结果文档后追加 `06-AI作业追溯.md`，包含阶段交接摘要。
7. 更新 `00-需求概览.md` 的快照、正式设计基线、整合设计评审状态、任务 INDEX 和 `tasks/README.md` 摘要。
8. 回复 task 路径、当前阶段、唯一下一动作、已更新文件和追溯入口；`next.skill` 非 `none` 时不得宣称任务完成。若本轮补过骨架，一并列出补齐项。

## README 状态表

```markdown
# {项目} · 任务索引

| task_id | 创建日期 | 最后更新 | 模块 | 需求 | 当前阶段 | 下一 Skill | 正式设计 | 阻塞/等待 | 目录 |
|---|---|---|---|---|---|---|---|---|---|
```

## 关键文档要点

### 索引和默认读取

- 新会话或用户说“继续”时，按 `docs/{项目}/INDEX.md → tasks/{task}/INDEX.md → 00-需求概览.md` 恢复任务。
- 实施时优先读取已批准的 `03A-聚合详细设计.md`；单功能 `design/{模块}/` 和 `03-决策记录.md` 只在审计、争议或 freshness 核验时读取。`01/02` 只在需要事实或方案依据时读取，`06` 仅审计或历史恢复时读取。
- 阶段状态只维护在 `00-需求概览.md`；历史 handoff、决策卡原文、README 和 trace 不得写入或推断当前 `next.skill`。
- 决策确认并发布正式设计后，更新 `02-方案评估.md` 的归档状态和正式设计链接，避免把最终设计复制两份。
- 只要存在多个 `workstreams`，续作或相关回复必须先输出全局进度卡，逐项显示状态；任务级唯一 `next.skill` 不能隐藏其他等待中的子流。

`00-需求概览.md` 必须包含目标、背景、范围、不做范围、验收标准、当前工作流快照、正式设计基线和整合设计评审状态：

```yaml
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
  status: "not-required | pending | waiting-review | approved | changes-requested | stale"
  hash_version: "design-sha256-v1"
  artifact: ""
  artifact_revision: ""
  artifact_hash: ""
  source_set_hash: ""
  reviewed_hash: ""
  reviewed_source_set_hash: ""
  change_target: ""
  sources: []
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
```

`workflow_handoff.workstreams[]` 同时维护 `design_required: true|false`。字段缺失的旧任务按 `true` 处理；显式 `false` 必须有方案依据。正式设计准入按所有需设计 workstream 与 artifact `workstream_ids` 并集做覆盖校验，不能用 artifact 数量代替。

`02-方案评估.md` 只记录候选方案、比较、推荐结论、开放问题和是否需发布正式设计；不得把长期接口/配置/数据规范冒充为未确认方案。

`03-决策记录.md` 记录决策卡、确认人、条件、风险接受与证据索引。正式设计发布后，设计文件必须反向标注其来源 `task_id` 和决策记录。

`03A-聚合详细设计.md` 是由任务完整来源集合编译出的自包含任务级实施契约。人工批准必须绑定 `artifact_hash/source_set_hash`；来源变化后标记 `stale`，先自检再生成和评审。

新建或显式迁移的任务使用 `design-sha256-v1`，由统一指纹工具生成/核验。没有 `hash_version` 的历史任务先走证据恢复，不能猜算法、覆盖旧批准或因动作词重新开需求。

## 关键要求

- 先找已有 task，再决定是否新建。
- 先核验并补齐项目骨架，再写任务档案；不得只建 `tasks/`。
- 先任务过程文档，后代码；决策后的正式设计按需发布到 `design/`。
- 任务目录是续作入口，`design/` 是稳定知识基线；两者不得互相替代。
- 需求含糊时先澄清，不靠 AI 猜。
