# AI 人机协作研发规范

> 版本：V0.5.8-public.2
> 适用范围：AI 参与的软件需求、设计、开发、测试、修复与归档。
> 产品能力通过项目自己的适配器提供。

## 修订记录

| 修订 | 日期 | 摘要 |
| --- | --- | --- |
| V0.5.8-public.1 | 2026-09-15 | 抽取通用流程，移除产品适配器与内部历史，统一通用测试、审查和领域调研。 |
| V0.5.8-public.2 | 2026-11-18 | 增加改动车道。设计补丁先改正文那一节并单独确认，来源核对通过后再改实现。 |

契约变化应更新此表与相关 Skill 版本。

## 1. 文档定位

本规范是 **AI Collab Hub**：定义 AI、人、以及人机协作在研发任务中的作业方式。

它不是完整研发管理平台，也不是全自动 Agent 编排方案。它只解决一个问题：

> 在开发者主要通过 AI 完成需求、设计、开发、测试、修复和文档沉淀时，如何做到可执行、可验证、可追溯。

V0.5 主线继承 V0.4 的输入结构化、授权边界、产品适配、归档和全局进度契约，并增加多份正式设计进入实施前的整合人工评审阶段。V0.5.1 在同一主线下把产品适配从清单升级为可执行契约：

- 唯一风险模型。
- 人机协作模式。
- 角色化辅助审查。
- 必要时 subagent 复核。
- 决策卡与证据索引。
- 可证伪准入标准。
- 爆炸半径、回滚和停止线。

---

## 2. 第一原则

### 2.1 不追求全自动化

AI 负责整理、分析、生成、检查、证据汇总和追溯。

人负责目标确认、边界判断、风险接受、关键授权和最终验收。

### 2.2 不过度设计

只保留能降低风险、提高决策质量、减少返工的步骤。

不能执行、不能验证、不能追溯的条款不写入强制规则。

### 2.3 可追溯但不堆垃圾

追溯记录关键事实、证据索引和决策，不复制大段源码、完整命令输出、长篇聊天记录或重复文档全文。

---

## 3. 作业对象

| 对象   | 定义                                    |
| ---- | ------------------------------------- |
| 任务   | 一次需求、修复、排障、文档、测试或发布准备活动               |
| 风险等级 | R0-R4，决定执行路径和审核强度                     |
| 协作模式 | AI 自动处理、AI 辅助开发、AI 辅助决策、人主导高风险执行、协作排障 |
| 角色审查 | AI 以技术、测试、安全、发布、产品域等视角辅助审查            |
| 决策卡  | 给人快速拍板的短卡片，必须带证据索引                    |
| 追溯记录 | 记录 AI 作业过程、关键结论、证据路径和人工确认             |

---

## 4. AI 作业规范

AI 每次接到任务后，按以下顺序工作：

1. 接收原始输入。
2. 判定本轮通道：只读、不落盘、不改系统则轻量回答后结束，不建档、不访谈、不扫进度、不等风险确认。用户转为要改代码、立项或落盘时，当轮升级完整流程，复用已查事实并出风险卡，不得在轻量通道改文件；AI 建议修改须先问用户，不得自行升级。要改系统、落盘、立项或快照续作则走完整流程。
3. 完整通道：在内部转换为结构化任务卡。
4. 默认向人呈现可读任务摘要；有待决策事项时使用交互式问题卡。
5. 判断风险等级。
6. 选择协作模式。
7. 凡将写文件、改配置、跑命令或调用外部系统：先向决策者展示风险卡（目标/本轮等级、模式、范围、一句依据），等待确认、纠正或制止。同轮不得执行。
8. 判断是否需要角色审查或 subagent。
9. 读取必要上下文。
10. 仅在风险卡已确认（或 R0 只读）后执行已授权动作。
11. 生成结果、证据索引和风险说明。
12. 必要时生成决策卡。
13. 追加 trace，完成后写 worklog 或 issue。

AI 不得：

- 伪造事实。
- 把假设写成已确认事实。
- 无授权修改生产环境、生产数据、证书密钥、计费结算或设备侧生效配置。
- 替用户批准高风险动作。
- 用没有证据索引的决策卡请求审批。

### 改动车道

要改文件时先分车道。R3/R4 没有快车道。

| 车道 | 条件 | 动作 |
| --- | --- | --- |
| 快车道 | 不改目标、范围、验收、对外契约和已锁定决策；风险仍是 R0–R2 | 只改实现。不重开访谈、不改设计、不重新聚合 |
| 设计补丁 | 规则变了，目标和范围没变 | 只改正文里对应的那一节，单独确认后再改实现 |
| 需求补丁 | 目标、范围、验收或对外契约变了 | 沿用现有流程，只追加变更 |

设计补丁的确认和改代码不能并进同一轮，也不能用风险卡或路由问答代替。只追加变更记录、正文仍是旧规则，这一节不算改完。确认前以及来源核对未通过前，不改业务代码。不得用「限域补丁」或「未走核对」代替复检。追溯写快照已更新时，同一动作必须改了任务快照。

### 4.1 用户呈现与内部结构分层

- 结构化任务卡、访谈状态和证据路径用于 AI 路由、授权与追溯，不默认原样展示给用户。
- **风险等级、协作模式和本轮范围必须展示**，不是可隐藏的内部状态。写文件或跑命令前必须停一轮等人确认、纠正或制止。
- 默认交互使用简短任务摘要、行动前风险卡和每轮最多 3 张问题卡；每张卡应包含问题、推荐项、可选项和确认原因。
- 多 issue / 多 workstream 共用一张**行动前风险卡**时，必须并列各 ID，并写出每项范围、本轮风险上限、回滚/停止线（若适用）。一句「这几单一起做」不能省略分项；批准只覆盖卡上列出的 ID。这不是 §10 决策卡，也不另造合并决策产物。
- 用户可直接自然语言回答，也可用 `Q1：...；Q2：...` 回复；Skill 不承诺提供宿主界面的点击按钮或下拉框。
- 用户明确要求导出 YAML、原始任务卡或供工具消费时，才展示结构化内容；长文本使用 YAML `>-` 折叠块，多个路径使用列表，不拆断单个路径、ID 或 URL。

### 4.2 需求访谈结束门控

需求访谈不是“回答完当前问题就结束”。AI 每轮回答或查证后，依次确认：目标与成功标准、范围与非范围、阻塞的业务/数据/接口依赖、验收标准、R3/R4 的环境/租户/数据/外部或设备影响及回滚和授权边界、当前 frontier 是否已清空。

- 未通过任一项，状态为 `continue-interview`，只能继续澄清。
- 六项均通过时，默认转为 `ready-for-confirmation` 并展示结束确认卡；用户说“当前够用 / 结束访谈 / 进入需求分析 / 进入方案”才进入 `ready-to-draft`。
- 仅用户预先要求自动结束且任务为 R0-R2 时，门控通过可直接进入 `ready-to-draft`；R3/R4 必须人工确认，且第 5 项不能绕过。
- `continue-interview` 与 `ready-for-confirmation` 高于“新需求建目录”“需要任务档案”“生成决策卡”等通用路由。此时不得创建项目骨架、任务档案、需求分析或方案，也不得进入决策卡或实施。
- 用户对 `Q1/Q2/...` 的回答（包括“可以建目录”“后续落盘”）仅是访谈数据或后续授权；只有在 `ready-to-draft` 后的独立落盘指令才能创建目录或文档。已有任务档案可以追加简短访谈 trace。
- 本项目不以独立 PRD Skill 或 `docs/PRD.md` 作为需求阶段门控。`analyze-requirement` 写入的 `01-需求分析.md` 是人工确认基线；确认范围/优先级/验收后，或用户明确“进入方案”后，再交给 `design-solution`。信息完整度评估与 AI 问询留在 `analyze-requirement` 内，不拆成多个 Skill。
- 命中 领域协议或外部服务 等领域协议或外部系统术语时，先按 `domain-research` 查阅证据再分析；阻塞性 `unknown` 不得进入需求确认。方案与正式设计发布复用并加深同一证据，不得把推断升格为协议契约。
- 涉及前端/门户页面或展示时，由适配器登记的模块 UI Skill 约束信息层级、实施红线与走查；遵循项目已有设计系统。
- 开发阶段编码后由通用 `unit-test`（并应用适配器的 `unit_test_extras[]`） 补跑单测；验证阶段由通用 `code-review`（并应用适配器的 `review_extras[]`） 按安全、需求覆盖、最简实现三轴审查，且必须人审。

### 4.3 阶段交接与续作恢复

每个阶段结束时都必须交接，而不是只写“转下游 Skill”。有任务档案时，`tasks/{任务}/00-需求概览.md` 的“当前工作流快照”是状态源；`tasks/README.md` 仅显示摘要，`06-AI作业追溯.md` 仅保存历史。

- 快照至少包含已完成阶段、当前阶段与状态、唯一下一 Skill、下一动作、阻塞项、需要用户做的事；`next.skill` 非 `none` 时，AI 不得把任务表述为已完成。
- 落盘后必须同轮更新 `00` 与 INDEX 并补 trace，使最新实施类记录能被快照解释；只写 trace 视为状态非法。不是每次落盘都升 `current_stage`。
- 快照推进绑定工作完成，不绑定 git commit。人代提交时 AI 当轮仍须记账。
- 续作或新会话先恢复快照中的 `next.skill`，然后再读取最近 trace；不得仅凭“代码、文档、R3”等关键词重新判断阶段。
- 带任务编号、任务链接或“继续 / 接着 / 这个需求”时，先按版本 INDEX → 事实 issue → 唯一任务目录 → 任务 INDEX → `00` 恢复阶段、workstreams、`next.skill`、阻塞项和仍有效授权；范围与授权未变时不得因“改/合并/修复”等动作词重开需求分析或设计。
- 设计指纹统一使用业务仓 `tools/design-fingerprint/fingerprint.cjs`（协议 `design-sha256-v1`）。无版本、未知版本或无法计算时保留原阶段与批准，只阻断依赖该指纹的动作并转证据恢复；不得直接判正文变化、枚举算法、按 mtime 下结论或覆盖旧批准。
- 下一 Skill 只有在不写文件、不运行命令、不调用外部系统时，才能在原任务范围内自动继续；`check-design` 写 `02A/00/INDEX/trace` 必须有快照中的限域 `design_check_authorization`。
- 多个独立子需求必须按 workstream 记录 ready、waiting-user、blocked、in-progress 或 completed。一个子项的未决信息不得阻塞另一个已就绪子项。
- R3/R4 方案评估完成后，下一 Skill 必须是 `make-decision-card`；决策卡未生成或未获批时，不能交给实施。实施完成后必须交给验证，验证通过后才交给 worklog/完成状态。
- 正式设计基线适用于 R3/R4、跨模块、接口/配置/数据契约变更和用户明确要求的设计；决策确认后先由 `design-solution` 发布 `design/{模块}/` 正式设计，未发布时不得实施。
- 凡已发布正式设计，必须先由 `check-design` 对完整来源集合做 hash 绑定自检，再由 `aggregate-design` 生成覆盖全部来源、带 artifact/source-set hash 的 `03A-聚合详细设计.md`；单功能也出 03A。需设计 workstream 必须被 artifact `workstream_ids` 并集完整覆盖。人工批准必须绑定 reviewed hash，局部 workstream 不得复用任务级批准。实施、验证和路由前必须从当前文件重算 source/source-set/artifact hash，不能只信任快照；状态缺失或非法一律 fail-closed。自检失败退回 `design-solution`，不得开启新需求访谈。R3/R4 实施还必须同时有已批准决策卡和独立限域 `execution_authorization`。
- 为修复门控自身而使用的自举例外必须在快照记录已批准决策、scope 和失效条件；不得扩展到业务任务，独立复核通过后立即失效。

### 4.3.1 文档索引与上下文预算

任务路由采用渐进式读取，不默认把整个任务档案装入上下文：

- 先读 `docs/{项目}/INDEX.md` 和任务 `INDEX.md`，再读 `00-需求概览.md` 恢复当前阶段与唯一 `next.skill`。
- 聚合前读取完整来源集合、02A 指纹和决策确认摘要；聚合批准后，实施默认读取从当前文件重算后与 reviewed hash 匹配的 `03A-聚合详细设计.md`，来源只用于审计、争议或 freshness。
- `INDEX.md` 只记录链接、状态、子工作流、阻塞和短摘要，不复制正文；不得为了“方便检索”再生成一份完整需求或方案汇总。
- 当前状态唯一以 `00-需求概览.md` 快照为准。决策卡生成时的 handoff、`tasks/README.md`、`design/README.md` 和 trace 都是索引/历史材料，不能覆盖当前状态。
- 决策批准并发布正式设计后，方案评估文档只保留候选取舍和未决事项。单功能来源基线保存在 `design/{模块}/`；需要聚合时，由 03A 将其编译为完整任务级实施契约。
- `03A-聚合详细设计.md` 必须包含总体架构、全部 workstream、统一契约字典、组合约束、实施顺序、风险回滚和验证矩阵。来源变化时 pass 失效并 stale；03A 自身变化时清空 reviewed hash。聚合遗漏在 `aggregate-design` 内修正，来源缺口/冲突才回 `design-solution`。

### 4.3.2 全局进度播报与停滞提醒

- 只要任务存在两个及以上 `workstreams`，入口、续作或项目相关回复前必须读取版本 INDEX、任务 INDEX 和 `00-需求概览.md`，并逐项展示所有子流的阶段、状态、下一动作和等待事项。
- `waiting-user` / `blocked` 子流必须进入“需要你处理”区，写明缺少的事实、审批或授权，以及可直接回复的动作；在事项解决前，后续相关回复必须继续提醒。
- 任务级唯一 `next.skill` 只表示本轮优先恢复动作，不代表全部子流状态；不能因为部分子流已发布正式设计，就隐藏其他停在方案评估或需求分析的子流。
- 本规则保证下一次项目对话主动播报；用户没有发送新消息时，Skill 不会自行唤醒。空闲期通知需另配 Monitor/Automation。

### 4.4 任务档案与正式设计基线

`tasks/` 与 `design/` 解决的是不同问题，不能互相代替：

- `tasks/{任务}/` 保存需求概览、需求分析、方案评估、决策记录、聚合详细设计、实施/验证计划和 AI 追溯，是一项工作从开始到结束的唯一续作入口。
- `design/{模块}/` 保存已确认、可复用、长期有效的单功能/单模块来源基线；不得包含候选 A/B/C、未决问题、完整访谈或过程 trace。
- `04-实施计划.md` 才是严格意义的计划；旧顶层 `plan/` 是历史兼容路径，新任务不得再写入。
- `03A-聚合详细设计.md` 是凡已发布正式设计即生成的完整任务级实施契约和人工评审对象；必须记录 artifact/source-set hash，批准记录 reviewed hash。来源链接只用于追溯，不得替代正文。
- 小型局部 R0-R2 任务可以不发布正式设计，但必须在方案评估中说明；其他满足基线条件的任务先发布正式设计再实施。

---

## 5. 人工作业规范

人不需要从零完成所有角色审查，但必须在关键点做决策。

人需要负责：

- 确认目标和范围。
- 修正 AI 结构化任务卡中的误解。
- 对关键方案拍板。
- 接受或拒绝风险。
- 授权高风险执行。
- 验收结果并决定是否关闭任务。

审核采用角色制，不强制不同自然人。一个人可以承担多个角色，但每次确认必须写明 acting_role。

```yaml
user_decision:
  acting_role:
    - "技术负责人"
  decision: "approve | approve_with_conditions | reject | ask_for_more_evidence"
  conditions: []
  risk_acceptance: []
  timestamp: ""
```

---

## 6. 人机协作模式

| 模式       | 适用风险  | AI 做什么         | 人做什么         | 输出物                     |
| -------- | ----- | -------------- | ------------ | ----------------------- |
| AI 自动处理  | R0/R1 | 分析、生成、轻量修改、归档  | 行动前确认或纠正风险；R0 可事后看 | 回答、文档、trace 摘要          |
| AI 辅助开发  | R2    | 设计、编码、测试、总结    | 行动前确认风险与范围，事后 review | 变更说明、测试结果、worklog       |
| AI 辅助决策  | R3    | 多视角审查、证据汇总、决策卡 | 批准、驳回或要求补证据  | decision card、trace     |
| 人主导高风险执行 | R4    | 方案、检查清单、回滚、停止线 | 授权并主导或逐步确认执行 | 执行卡、回滚卡、审批记录            |
| 协作排障     | R2-R4 | 收集证据、列假设、缩小范围  | 提供环境、确认操作边界  | 排障记录、假设清单、issue/worklog |

---

## 7. 风险模型

V0.5 使用唯一风险模型。产品适配层只补充产品特有风险，不重复通用字段。

```text
风险等级 = 任务类型 × 影响环境 × 数据影响 × 外部系统 × 设备侧影响 × 可回滚性 × 爆炸半径
```

| 等级  | 定义                        | 执行规则                     |
| --- | ------------------------- | ------------------------ |
| R0  | 只读问答、代码解释、文档查询            | 摘要标明 R0，可直接回答；落盘前仍须风险卡确认 |
| R1  | 文档、小配置、低风险小改              | 先展示风险卡，确认后可执行，记录摘要、文件和验证结果 |
| R2  | 普通业务代码变更                  | 先展示风险卡，确认后可开发测试，人 review 后验收 |
| R3  | 数据、权限、外部接口、设备侧影响          | AI 辅助决策，必须有决策卡           |
| R4  | 生产、批量、高不可逆、证书密钥、计费、生产批量操作 | 人主导高风险执行，必须有完整决策卡、回滚和停止线 |

### 7.1 风险升级规则

任一条件满足即升级：

- 生产环境：至少 R3。
- 生产数据写入、迁移、删除：R4。
- 证书、密钥、签名、计费结算：R4。
- 不可回滚或回滚未验证：至少 R3。
- 爆炸半径超过单租户或小批量：至少 R3。
- 产品特有风险不写死在通用表中；加载主产品与全部 `product_touchpoints[]` 的适配器后，取通用风险与各适配器 `risk_triggers[]` 的最高等级。
- 任一适配器未登记、状态为 `catalog-only`，或缺少当前动作所需证据时，不得据此降低风险；进入实施前按适配器状态 fail-closed。

---

## 8. 角色化审查

角色是审查视角，不强制对应不同自然人。

| 风险    | 审查视角                      |
| ----- | ------------------------- |
| R0/R1 | 不强制角色审查                   |
| R2    | 技术负责人视角 + 测试负责人视角         |
| R3    | 技术 + 测试 + 安全或产品域专家        |
| R4    | 技术 + 测试 + 安全 + 发布 + 产品域专家 |

角色审查输出：

```yaml
role_review:
  role: "tech | test | security | release | product-domain"
  conclusion: "pass | pass_with_risk | block"
  key_findings: []
  missing_evidence: []
  required_actions: []
  risk_acceptance_needed: true
```

---

## 9. Subagent 使用规则

默认不启用 subagent。先使用主 AI + 角色化审查模板。

必要时可以启用 subagent：

| 场景             | 规则             |
| -------------- | -------------- |
| R0/R1          | 不启用            |
| R2 普通代码变更      | 默认不启用，除非影响核心模块 |
| R3 高风险方案       | 可启用            |
| R4 生产、批量、不可逆   | 建议启用           |
| 主 AI 结论不确定     | 可启用            |
| 涉及安全、计费、证书、设备侧 | 可启用            |
| 用户明确要求复核       | 启用             |

subagent 只提供独立评审意见，不拥有审批权。

```yaml
subagent_review:
  role: "security | test | architecture | product-domain | release"
  conclusion: "pass | pass_with_risk | block"
  key_findings: []
  missing_evidence: []
  disagreement_with_main_agent: []
  required_actions: []
```

---

## 10. 决策卡

决策卡是决策入口，不是完整证据库。

规则：

- 决策卡要短。
- 必须有证据索引。
- 不复制大段代码、长日志或完整聊天记录。
- 没有证据索引的决策卡不能用于审批。
- R3/R4 的决策卡必须包含爆炸半径、回滚和停止线。

```yaml
decision_card:
  task_id: ""
  risk_level: "R0 | R1 | R2 | R3 | R4"
  collaboration_mode: ""
  recommendation: "approve | approve_with_conditions | reject | ask_for_more_evidence"
  summary: ""
  key_evidence:
    - type: "requirement | design | code | test | security | performance | rollback | trace"
      conclusion: ""
      source: "path#anchor or command summary"
      confidence: "high | medium | low"
  blocking_issues: []
  missing_evidence: []
  acceptable_risks: []
  blast_radius:
    scope: ""
    limit: ""
  rollback:
    strategy: ""
    verified: false
    evidence: ""
  stop_conditions: []
  details_index:
    requirement: ""
    design: ""
    trace: ""
    test_report: ""
    issues: []
  user_decision_required:
    acting_role: []
    decision_options:
      - approve
      - approve_with_conditions
      - reject
      - ask_for_more_evidence
```

---

## 11. 可证伪准入标准

准入标准用于判断任务是否允许进入下一阶段。每条准入标准都必须能判断通过或失败，不能只写“质量通过”“安全通过”“性能满足”。

```yaml
entry_criteria:
  name: ""
  applies_to: "R2 | R3 | R4"
  pass_condition: ""
  evidence_required: []
  fail_action: "block | ask_for_more_evidence | allow_with_risk_acceptance"
  waiver_allowed: true
  waiver_requires_role: []
```

最低准入标准：

| 准入标准   | 适用  | 最低证据                |
| ------ | --- | ------------------- |
| 需求准入标准 | R2+ | 目标、范围、非目标、验收标准      |
| 设计准入标准 | R2+ | 方案、影响范围、风险、替代方案     |
| 测试准入标准 | R2+ | 测试命令、结果摘要、未覆盖项      |
| 安全准入标准 | R3+ | 权限、敏感数据、密钥、外部接口检查结论 |
| 发布准入标准 | R4  | 灰度范围、回滚、停止线、审批记录    |

无法提供证据时，不得写“已通过”，只能写 `missing_evidence` 或 `waived`。

---

## 12. 爆炸半径

R3/R4 必须声明爆炸半径。

```yaml
blast_radius:
  environment: ""
  tenant_scope: ""
  data_scope: ""
  user_scope: ""
  device_scope: ""
  external_system_scope: ""
  rollout_scope: ""
  max_batch_size: ""
```

默认规则：

- R0/R1：不得有生产影响。
- R2：默认只在本地、开发、测试或预发环境验证。
- R3：必须限定租户、模块、数据、接口或设备范围。
- R4：必须分批、灰度、观察，不能默认全量。

产品特有的默认范围由产品适配器 `blast_radius_defaults` 补充；适配器不得删除或放宽上述通用规则。

---

## 13. 回滚与停止线

### 13.1 回滚

“有回滚方案”不等于“回滚可行”。

```yaml
rollback:
  strategy: ""
  owner_role: ""
  executable_steps: []
  data_recovery: ""
  verification_method: ""
  tested: false
  evidence: ""
  limitations: []
```

规则：

- R2：至少有代码回退或配置回退说明。
- R3：必须有回滚步骤和验证方法。
- R4：必须有回滚演练或等价验证；无法回滚必须显式风险接受。

### 13.2 停止线

停止线定义“观察到什么就必须暂停、回滚或升级处理”。

```yaml
stop_conditions:
  - metric: ""
    threshold: ""
    observation_window: ""
    action: "pause | rollback | escalate"
    owner_role: ""
```

R4 没有停止线不得执行。

---

## 14. 追溯与归档

追溯由配套机制 `归档 Skill 与约束 V1.2` 执行。

必须使用：

- `write-plan`：创建或维护需求目录。
- `write-ai-trace`：追加 AI 作业事件。
- `write-worklog`：阶段完成总结。
- `write-issue`：登记待处理问题，并在修复或后续基线覆盖后按关闭流程核销。

追溯应记录：

- 原始输入摘要。
- 结构化任务卡摘要。
- 关键决策。
- 文件路径。
- 命令和结果摘要。
- 测试结论。
- 风险和假设。
- 人工确认。
- issue / worklog 链接。

### 14.1 issue 生命周期

issue 记录待处理问题；身份事实来自 issue 文件与协调文件，README/INDEX 是派生索引。关闭必须可恢复、可审计，不能自动消失。

- `write-issue` 负责 create / normalize / scope-change / close / recover；`write-worklog` 在关闭路径拆为 draft 与 finalize。
- 新 issue 使用 schema v2 与 item 账本；create/close 使用 operation ID、claim/binding/manifest 与 checkpoint。
- 关闭顺序固定：worklog draft（initialize manifest）→ issue close transaction → worklog finalize；仅 `fully_closed` 后 transaction blocker 失效。
- keep 不是 item 终态，也不改变 scope/blocking；缩小范围或解除 blocking 须独立 scope-change 批准。
- 项目摘要展示全部活动/恢复对象；当前任务只被精确谓词并集阻塞。无关项目 issue 不阻止当前任务完成。
- 后续任务“关联 issue”、发布新版本、或把来源任务标为 completed，都不构成关闭。
- 版本 INDEX 的“需要你处理”必须列出活动 issue 与恢复对象；入口必须先事实扫描再校验 README。
- 任务不得在相关 blocking/recovery issue 未 fully_closed 或合法转出时进入 `next.skill=none`。

追溯不应记录：

- 大段源码。
- 完整命令输出。
- 长篇聊天记录。
- 重复粘贴文档全文。
- 无意义流水账。

---

## 15. 产品适配器契约

Harness 只定义一次通用阶段、风险代数和字段形状。每个产品通过薄适配器补充产品所有权、风险触发器和执行默认值；不得复制 `analyze-requirement`、`design-solution`、`aggregate-design`、`implement-change` 等阶段 Skill。

### 15.1 任务卡中的产品语义

- `product`：主产品，只能一个；决定任务档案 `docs_root` 和默认实施仓。
- `product_touchpoints[]`：本任务实际触及的其他已登记适配器；去重后可为空。
- 风险等级取通用模型、主产品和全部 touchpoint 触发结果的最高值。
- `common` 只用于 Harness、规则、Skill 和共享治理资产，不自动加载 任何产品专用 风险。
- 跨产品触点不改变任务档案归属；所有权冲突时必须先澄清 `owns[]/does_not_own[]`，不得重复加码或自行选择实施仓。

### 15.2 适配器最小契约

```yaml
product_adapter:
  product_id: ""
  status: "complete | incomplete"
  execution_status: "executable | blocked-in-this-repo | catalog-only"
  git_repo: ""
  docs_root: ""
  hub_domain: ""
  owns: []
  does_not_own: []
  risk_triggers:
    - domain: ""
      condition: ""
      min_level: "R3 | R4"
      evidence_required: []
  blast_radius_defaults:
    environment: ""
    tenant_scope: ""
    data_scope: ""
    device_scope: ""
    external_system_scope: ""
    rollout_scope: ""
    max_batch_size: ""
  rollback_defaults: []
  stop_lines: []
  module_skills: []
  unit_test_extras: []
  review_extras: []
```

约束：

- `status=incomplete`：允许需求分析和方案收集，但缺失字段涉及当前动作时必须写 `missing_evidence`。
- `execution_status=executable`：仅表示产品可实施；仍须满足阶段、风险和授权门控。
- `blocked-in-this-repo`：当前仓只能分析和设计；`implement-change` 必须停止并给出 `git_repo/docs_root`。
- `catalog-only`：只登记产品存在，不得生成假适配章、假代码路径或进入实施。
- `risk_triggers[]` 只能提高风险，不得降低通用模型结果。
- 产品默认值若为空，不得由 AI 猜测；需要该值的动作保持 `waiting-user`。

### 15.3 通用资产与项目适配器

`common` 表示本 Hub 的流程、规则和共享治理资产。默认安装不登记任何真实产品。
业务项目的产品 ID、代码仓、文档根、所有权、风险与模块 Skill 必须由该项目提供证据。

## 16. 创建项目适配器

使用 `common/adapter-kit/product.yaml.tpl` 定义项目适配器。
模板默认 `incomplete` / `catalog-only`，没有预设产品、仓库、批量上限或模块 Skill。
安装器的 `-Product <id> -ScaffoldProduct` 只生成模板；使用者完成证据与范围确认后才能启用实施。
适配器仅补充项目约束，不复制通用阶段 Skill。

---

## 17. 规范到执行映射

| 规范要求                                                    | 执行方式                        |
| ------------------------------------------------------- | --------------------------- |
| 原始输入生成任务卡、加载产品适配器、恢复阶段并路由                               | `ai-collab-start` 0.5.3     |
| 真实需求分析、产品所有权/缺证据门控、领域调研、`01` 确认与交接                      | `analyze-requirement` 0.1.9 |
| 应用产品默认值的方案评估与正式设计发布（复用/加深领域证据；门户展示挂载适配器登记的模块 UI Skill） | `design-solution` 0.3.4     |
| R3/R4 或关键拍板（绑定产品风险触发与默认值）                               | `make-decision-card` 0.1.5  |
| 融合前自检完整正式设计集合                                           | `check-design` 0.2.0        |
| 编译 hash 绑定的自包含 03A 并等待人审                                | `aggregate-design` 0.5.0    |
| 授权后的开发实施与产品仓门控                                          | `implement-change` 0.3.3    |
| 产品适配复核、测试、验收、review 和交付判断                               | `verify-delivery` 0.4.3     |
| 门户页面设计约束、实施红线与走查                                        | 适配器 `module_skills[]` 登记的模块 UI Skill |
| 开发后单元测试生成与执行                                            | `unit-test` + 适配器 `unit_test_extras[]` |
| 开发后三轴代码审查（安全/需求覆盖/最简实现）                                 | `code-review` + 适配器 `review_extras[]` |
| 新需求先建或复用任务档案、持久化快照                                      | `write-plan` 1.7.0          |
| 每次 AI 作业与阶段交接可追溯                                        | `write-ai-trace` 1.5        |
| 完成后写总结、核销关联 issue 并关闭对应工作流                              | `write-worklog` 1.5         |
| 发现问题登记并阻塞对应工作流；处理完成后逐条核销关闭                              | `write-issue` 1.5           |
| 决策卡带证据索引                                                | `make-decision-card`        |
| R3/R4 角色化审查                                             | AI 角色审查模板，必要时 subagent      |
| R4 回滚和停止线                                               | 决策卡必填                       |

---

## 18. 最小实施路径

V0.5 实施时按以下路径执行：

```text
原始输入
  ↓
结构化任务卡
  ↓
分轮需求访谈（结束门控 + 默认人工确认）
  ↓
需求分析
  ↓
方案评估
  ↓
决策卡（R3/R4 或需要拍板）
  ↓
人工确认关键决策
  ↓
正式设计发布（按需）
  ↓
check-design（完整来源集合 + checked hash）
  ↓
aggregate-design（完整范围 + artifact/source-set hash；单功能也出）
  ↓
人工确认当前 hash 对应的 03A
  ↓
独立实施授权
  ↓
开发实施
  ↓
验证交付
  ↓
trace / worklog / issue 归档
```

每个箭头都要更新阶段交接快照。低风险任务可以轻量执行，高风险任务必须进入决策卡和人工确认。落盘后 `00`、INDEX 与 trace 必须同轮记账，trace 不得单独前进；升阶段只在阶段迁移时发生。快照推进绑定工作完成，不绑定 git commit。

---

## 19. 后续迭代

- 用合成示例和可公开的测试反馈改进通用流程。
- 产品适配器在各自项目维护，进入公共包前单独审查。
- 从问题记录、验证证据和工作总结中修订规范。
