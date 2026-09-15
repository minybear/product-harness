---
name: init-project-docs
version: 0.1.1-public.1
description: 在需求访谈已结束或用户明确结束访谈后，检查并补齐 docs/{项目}/ 的 INDEX、tasks、design、logs、issues 标准骨架。项目目录已存在不得视为骨架就绪；只补缺失项，不覆盖已有文件。访谈回答不得触发创建。只建骨架，不写需求分析或方案正文。
---

# 初始化项目文档骨架（init-project-docs）

为当前项目在 `docs/` 下建一套标准文档骨架。所有设计、计划、日志、issue 都按项目归档到 `docs/{项目}/` 下，不再平铺。

## 触发方式（优先自动识别）

1. **AI 自动识别（推荐）**：会话中判断出正在做某个项目（如文件导入、账号设置），且标准骨架**不完备**（`docs/{项目}/` 不存在，或 INDEX / `tasks` / `design` / `logs` / `issues` 任一缺失）→ 列出**缺失项**给用户看，**询问确认后**再补齐。不得因项目目录已存在、或其中已有平铺文档/`tasks/`，就跳过检查。
2. **用户直接指令**：用户说"在 docs 下给 XX 项目建目录"或"补齐文档骨架" → 按完备判定检查并补缺，已存在的跳过。
3. **被 `write-plan` 调用**：建任务档案前若骨架不完备，本 Skill 先补齐再交回 `write-plan`。已获任务落盘授权时，补缺视为同一授权内的幂等操作，不必再单独确认，但仍须汇报补了哪些。

## 访谈门控

- 若当前有 `requirement_interview.status=continue-interview` 或 `ready-for-confirmation`，不得自动识别、列出或创建项目骨架，先回到 `analyze-requirement`。
- `Qn` 的回答即使含有“可以创建 {项目} 目录”，也只记录为后续目录目标，不是创建命令。
- 只有访谈已为 `ready-to-draft`，或用户以独立指令明确“结束访谈并创建目录”时，才可执行本 skill 的目录确认/创建流程。

## 标准骨架

```
docs/{项目}/
    INDEX.md             # 项目级检索入口
    tasks/               # 任务档案：需求到验证的全过程与唯一续作入口
        README.md
    design/              # 正式设计基线：长期稳定，约束"怎么做"
        README.md        # 文档索引 + 状态（谁负责/是否最新）
    logs/                # 开发日志：每个功能/修复完成后必写，按月归档
        README.md
    issues/              # 开发中发现的问题：带完整上下文，供冷启动
        README.md        # 派生索引；事实源是 open/closed 与协调目录
        open/
        closed/
        .claims/         # problem-key claim（可空目录说明）
        .operations/
            create/      # create operation binding
        .transactions/   # close operation manifest
```

- `{项目}` 命名：小写、kebab-case，能一眼对应业务（如 `task-board`、`file-import`、`account-settings`）。已有中文或历史目录名时复用该名，不得另建平行项目目录。
- 已存在的目录/文件**跳过，不覆盖**（幂等）。平铺在 `docs/{项目}/` 根下的旧文档保留不动。

### 骨架完备判定

以下**全部**存在才视为完备；`docs/{项目}/` 存在本身不够：

- `INDEX.md`
- `tasks/README.md`
- `design/README.md`
- `logs/README.md`
- `issues/README.md`
- `issues/open/`
- `issues/closed/`
- `issues/.claims/`
- `issues/.operations/create/`
- `issues/.transactions/`

缺任一项即为不完备，必须补齐该项。不得把「已有 `tasks/`」或「根目录已有若干 md」当成骨架就绪。

## 工作流程

1. **识别项目名**：从当前任务/对话判断项目（如用户说"做文件导入"，项目名 `file-import`）。判断不了 → 问用户项目名。
2. **按完备判定逐项检查**：记录已存在与缺失清单。已完备则汇报「骨架已齐，未改文件」并结束。
3. **列出缺失项**（自动识别且尚未获落盘授权时，先展示再确认；方式 2/3 可直接补）：

   ```
   我检测到当前在做「{项目}」，docs/{项目}/ 文档骨架还不完整。
   将补齐以下缺失项（已存在的会跳过、不覆盖）：

     （只列出缺失的路径，例如 design/README.md、logs/、issues/open/）

   是否补齐？（可改项目名）
   ```
4. **确认后或已授权时补齐**：只创建缺失目录与缺失的 `INDEX.md` / README；已存在则跳过。任务级 `INDEX.md` 由 `write-plan` 在创建具体任务时生成。
5. 回复补了哪些、跳过了哪些。

> 若用户是直接指令（方式 2）或 `write-plan` 已获落盘授权（方式 3），可跳过第 3 步询问，但仍要汇报补齐结果。

## 各 README.md 索引内容

**docs/{项目}/INDEX.md**：项目级检索入口

```markdown
# {项目} · 文档入口
> 先读本文件，再进入当前任务 INDEX；本文件只保存入口、状态和读取路径，不复制正文。

| 区域 | 入口 | 用途 |
|---|---|---|
| 任务 | [tasks/README.md](./tasks/README.md) | 任务摘要 |
| 正式设计 | [design/README.md](./design/README.md) | 已确认设计 |
| 日志 | [logs/README.md](./logs/README.md) | 完成记录 |
| 问题 | [issues/README.md](./issues/README.md) | 待处理问题 |

## 需要你处理

（由 `write-plan` 按任务和子流状态维护；任何 `waiting-user` / `blocked` 事项必须在这里或任务 INDEX 中列出。）
```

**tasks/README.md**：任务索引 + 当前状态

```markdown
# {项目} · 任务索引
> 一项需求/修复一个目录：`docs/{项目}/tasks/{yyyyMMdd}-{模块}-{需求名}/`。其中保存需求、评估、决策、实施/验证计划和 trace；产出用 `write-plan` skill。

| task_id | 需求 | 模块 | 当前阶段 | 下一 Skill | 正式设计 | 阻塞/等待 | 目录 |
|---|---|---|---|---|---|---|---|
| （暂无） | | | | | | | |
```

**design/README.md**：正式设计索引 + 状态表

```markdown
# {项目} · 正式设计索引
> 只登记决策确认后发布的接口、配置、数据和详细设计；候选方案与 trace 留在 `tasks/`。每份文档标注状态（有效/待更新/已废弃）。

| 文档 | 状态 | 负责人 |
|---|---|---|
| （按需添加：接口设计 / 配置设计 / 数据设计 / 详细设计） | | |
```

**logs/README.md**：日志归档规则 + 状态

```markdown
# {项目} · 开发日志索引
> 每个功能/修复完成后必写一条：docs/{项目}/logs/{yyyyMM}/{yyyyMMdd}-{模块}-{标题}.md。产出用 write-worklog skill。

| 月份 | 日志数 | 备注 |
|---|---|---|
| （暂无） | 0 | |
```

**issues/README.md**：派生索引（事实源是 open/closed 与协调目录）

```markdown
# {项目} · 问题索引
> 身份事实来自 open/closed 文件与 `.claims` / `.operations/create` / `.transactions`；本 README 只做派生索引。产出用 write-issue skill；关闭顺序为 worklog draft → issue close → finalize。

| Issue | 优先级 | 模块 | 状态 | 登记日期 |
|---|---|---|---|---|
| （暂无） | | | | |
```

## 关键要求

- **先检查再补齐**：每次触发都必须按完备判定逐项核验；项目目录已存在不是跳过条件。
- **先展示后创建**（自动识别且尚未获落盘授权）：只列出缺失项并确认，不要默默创建，也不要列出已存在路径假装要新建。
- **幂等**：重复执行只补缺，不覆盖已有文件，不搬迁或改写根目录平铺旧文档。
- **建完即提示**：骨架就绪后，提醒用户后续日志/issue/任务档案分别用 `write-worklog` / `write-issue` / `write-plan` skill 归档；正式设计由 `design-solution` 在决策确认后发布。新建任务时同时生成任务级 `INDEX.md`。
