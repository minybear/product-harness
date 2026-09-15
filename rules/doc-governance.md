# 文档治理铁律（域：doc-governance）

> 本文件是 **doc-governance（文档治理）域**「文档按项目沉淀 + 任务收尾必归档」约束的事实源。
> 本 hub 含多个域，每个域的约束各有一个 `rules/{domain}.md`；本文件只管文档治理这一类。
> Claude Code 通过 `CLAUDE.md` 里的一行 `@引用` 加载它；Codex 通过 `AGENTS.md` 指向 `CLAUDE.md` 加载它。
> 两处内容同源，不要各自另存副本后单独漂移——要改就改这里。

## 优雅降级（先读这条）

本约束配套的 skill 位于本 hub 的 `skills/` 目录（`init-project-docs` / `write-plan` / `write-ai-trace` / `write-worklog` / `write-issue`）。约束与 skill **配套但解耦**：

- 若对应 skill **已安装**，按下文规则直接调用该 skill 完成归档。
- 若某 skill **未安装**，对应规则**自动降级**，不报错、不阻塞：
  1. 仍遵守文档归档的**目录约定**（`docs/{项目}/{tasks|design|logs|issues}`，旧 `plan/` 仅兼容读取，路径见下）；
  2. 归档时**手动**按对应 skill 的模板产出文档（模板见各 `skills/{name}/SKILL.md`）；
  3. 执行前**提示一句**："建议安装 `skills/{name}` 以获得完整流程"，然后继续。

即：约束永远生效，skill 只是让约束执行得更规范。缺 skill ≠ 失效，只是退回手动模式。

---

<!-- agents-snippet:start -->
## 铁律：文档按项目沉淀 + 任务收尾必归档（无条件遵守）

所有设计、计划、日志、issue 按项目归档到 `docs/{项目}/` 下，**不再平铺**。

### 需求访谈优先级（高于归档触发）

若当前任务存在 `requirement_interview.status=continue-interview` 或 `ready-for-confirmation`：

- 只可继续 `analyze-requirement`，读取证据、记录用户回答并输出下一轮问题或结束确认；不得触发 `init-project-docs`、`write-plan`、方案设计、决策卡或实施。
- 用户回答 `Q1/Q2/...`（包括“可以创建目录”“后续落盘”）只记录为访谈事实、目标或后续授权，不是立即创建文件的指令。
- AI 的六项结束门控通过后先进入 `ready-for-confirmation`；默认仍须用户明确说“当前够用 / 结束访谈 / 进入需求分析 / 进入方案”。只有用户预先要求自动结束且风险为 R0-R2 时可自动进入 `ready-to-draft`；R3/R4 不可自动结束。
- 仅 `ready-to-draft` 或无需需求访谈的任务，才进入以下任务档案、方案和实施规则。已有任务档案可追加简短访谈摘要 trace，但不得提前写需求分析或方案。

### 阶段交接连续性（每阶段必须遵守）

需求访谈以外的阶段，以当前任务档案 `tasks/{任务}/00-需求概览.md` 中“当前工作流快照”为状态源；`tasks/README.md` 只显示摘要，`06-AI作业追溯.md` 只保存历史。

- 每个阶段结束前必须记录或展示：已完成阶段、当前状态、唯一 `next.skill`、下一动作、阻塞项和需要用户做的事；`next.skill` 非 `none` 时不得以“任务已完成”收尾。
- 新会话或用户说“继续 / 接着 / 这个需求”时，先恢复该快照的 `next.skill`，不能按“代码 / 文档 / R3”等通用词重新猜阶段。
- 只有下一阶段不落盘、不运行命令、不调用外部系统时，才可在原任务范围内自动继续；代码、测试、配置、数据库、部署和生产动作仍需各自授权。
- 一个任务档案含多条独立子需求时，必须分别记录 ready、waiting-user、blocked、in-progress 或 completed；一个子项的 blocker 不得笼统阻塞其他已就绪子项。
- `tasks/` 保存需求、分析、方案评估、决策、聚合详细设计、实施/验证计划与 trace；`design/` 保存决策确认后的来源基线。凡发布至少一份正式设计，都必须先做 hash 绑定的 `check-design`，再生成覆盖完整来源集合的 `03A-聚合详细设计.md`；单功能也出 03A。人工批准必须绑定当前 artifact/source-set hash，批准后还需独立实施授权。
- 详细字段和路由见 `write-plan/references/stage-handoff.md`；阶段迁移同时在 trace 记录摘要。
- 落盘（改了代码/文档/配置，或执行了会改变任务结论的命令）后，必须在同一动作内更新 `00` 快照与任务/版本 INDEX，并补 `06`，使最新实施类 trace 能被当前 `00` 解释。只写 trace 不改快照视为状态非法，续作前先修快照。这不是每次落盘都升 `current_stage`：小改可只更新 `next.action` / workstream 状态 / 已完成说明，但不得让 `00` 仍写“尚未实施”。
- 快照推进绑定工作完成（文件已改、结论已达成），不绑定 git commit。降级由人在 IDE 提交时，AI 仍须在改文件当轮记账；人补 commit 后只回填证据。

### 文档索引与渐进式读取（强制）

每个项目维护版本级 `docs/{项目}/INDEX.md`，每个任务维护 `tasks/{任务}/INDEX.md`。索引只保存状态、链接、子工作流和短摘要，不复制需求、方案、决策或 trace 正文。

- 新会话或用户说“继续”时，先读版本 INDEX、任务 INDEX，再读 `00-需求概览.md` 恢复唯一 `next.skill`。
- 默认读取路径为：`INDEX → task INDEX → 00 → reviewed hash 与当前 hash 匹配的 03A`；来源 design 与 03 顶部确认表仅用于审计、争议或 freshness 核验。`01/02` 只在需要事实或方案依据时读取，`06-AI作业追溯.md` 只在审计或历史恢复时读取。
- 当前状态只以 `00-需求概览.md` 的工作流快照为准；`tasks/README.md`、`design/README.md`、`03A-聚合详细设计.md`、决策卡生成快照和 trace 不得形成第二状态源。
- 决策批准并发布来源设计后，`02-方案评估.md` 只保留候选取舍和未决事项；需要聚合时，03A 将全部来源编译为自包含的任务级实施契约。
- `03-决策记录.md` 顶部维护当前人工确认结果；原始决策卡或生成时 handoff 必须显式标为历史快照，不能继续参与阶段路由。
- 阶段迁移、决策确认、正式设计发布和授权变化必须同步更新 `00` 与任务 INDEX，并在 trace 中追加摘要。
- 版本 INDEX 和任务 INDEX 必须有“需要你处理”区；新增、解决或转移 `waiting-user` / `blocked` 事项时同步更新该区，不得只把阻塞状态留在历史 trace 或正文段落中。
- 只要任务存在多个 `workstreams`，相关回复必须逐项播报全部子流状态；任务级唯一 `next.skill` 只能表示当前优先动作，不能隐藏其他子流。

### 0. 项目文档骨架（访谈结束后按需建立）

需求访谈已结束或无需访谈时，若 `docs/{项目}/` 不存在，用 `init-project-docs` skill 建骨架：**AI 识别当前项目 → 列出将创建的目录给用户看 → 询问确认后创建**。骨架：

```text
docs/{项目}/INDEX.md       版本级检索入口
docs/{项目}/tasks/    任务档案（需求到验证的全过程与唯一续作入口）
    INDEX.md           任务级检索入口（每个任务目录）
docs/{项目}/design/   正式设计基线（长期稳定，约束怎么做）
docs/{项目}/logs/     开发日志（每个功能/修复必写，按月归档）
docs/{项目}/issues/   待处理问题（open/、closed/、.claims/、.operations/create/、.transactions/）
```

### 1. 功能/修复完成 → 写开发日志

用 `write-worklog` skill，写到 `docs/{项目}/logs/{yyyyMM}/{yyyyMMdd}-{模块}-{标题}.md`。核心是沉淀"走过的弯路 + 经验 + 优化建议"三段，用数据说话，不只写"OK"。关闭 issue 时先 draft，再 `write-issue close`，最后 finalize。

### 2. 发现待处理问题 → 写 issue

用 `write-issue` skill，写到 `docs/{项目}/issues/open/`（schema v2）。身份事实是 issue 文件与协调目录；`issues/README.md` 只做派生索引。issue = 事前待接手，log = 事后已做完，别混。关闭必须 `fully_closed`，不能因关联/发布/completed 自动消失。

### 3. 访谈结束的新需求 → 建任务档案

仅在 `ready-to-draft` 或无需需求访谈时，用 `write-plan` skill 写到 `docs/{项目}/tasks/{createdDate}-{模块}-{需求名}/`。核心是 `00-需求概览`、`01-需求分析`、`02-方案评估` 和 `06-AI作业追溯`；`03-决策记录`、`03A-聚合详细设计`、`04-实施计划`、`05-验证计划` 按需创建。先文档后代码。

候选方案和决策过程不得冒充正式设计。决策确认后，满足正式设计条件的任务由 `design-solution` 发布来源基线到 `docs/{项目}/design/{模块}/`；发布后先由 `check-design` 自检，再由 `aggregate-design` 生成自包含的任务级聚合详细设计。聚合文档不得创造新结论，来源变化后必须标记 stale、回 pending 自检并重新生成。

### 4. AI 作业可追溯 → 追加 trace

用 `write-ai-trace` skill，写到当前需求目录的 `06-AI作业追溯.md`。每次 AI 参与需求沟通、生成结果文档、执行开发/修复动作、运行命令/测试、产生风险假设、发生人工确认或发现 issue，都必须追加追溯事件。

追溯至少记录：

- 原始输入
- 结构化任务卡
- AI 返问记录
- 用户补充内容
- AI 执行动作
- 文件变更
- 命令执行结果
- 测试结果
- 风险与假设
- 人工审核记录
- 交付物路径
- 新增/关联 issue

### 5. 跨工作日续作 → 复用同一需求目录

日期只用于首次建档命名，不是需求身份。同一需求跨工作日继续推进时，必须先查找并复用已有 `docs/{项目}/tasks/{createdDate}-{模块}-{需求名}/`，只追加 `06-AI作业追溯.md` 和更新相关文档，不得因为日期变化新建目录。旧 `plan/` 仅兼容读取，迁移必须获得用户授权且不能保留双份状态源。

查找优先级：

1. 用户显式提供的 task 路径、旧 plan 路径、需求目录名或 task_id。
2. `docs/{项目}/INDEX.md` 与任务目录 `INDEX.md`。
3. 当前会话刚创建或刚引用的 task。
4. `docs/{项目}/tasks/README.md` 中进行中/未完成任务。
5. `docs/{项目}/tasks/*/00-需求概览.md` 中的标题、模块、关键词。
6. 旧 `docs/{项目}/plan/`（仅兼容读取）。

无唯一匹配时，必须询问用户确认。

### 约束

- 日期一律用 `date +%Y%m%d` 取**当天真实日期**，不要用上下文里可能过期的日期。
- 目录名日期是首次建档日期；跨天续作不改目录名、不新建目录。
- 模块代码小写，优先使用当前仓库的模块名；判断不了模块时问用户。
- 改了代码、文档、配置或执行了测试/命令后，必须在同一动作内更新 `00` 快照与任务/版本 INDEX，并补 `06-AI作业追溯.md`。只写 trace 不改快照视为状态非法。不是每次落盘都升 `current_stage`。
- 快照推进绑定工作完成，不绑定 git commit。人代提交时，AI 当轮仍须记账；提交后只回填证据。
<!-- agents-snippet:end -->
