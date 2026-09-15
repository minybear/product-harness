# ProductHarness

**源于企业真实项目、经产品研发实践验证的 AI Harness 工程。**

ProductHarness 将企业产品研发中积累的协作流程、工程约束和验证机制，整理为可安装、可适配的 Skill、规则、模板与工具，供 Claude Code、Codex 和 Cursor 在现有项目中使用。

它覆盖从需求澄清、方案设计到开发实施、测试审查和交付归档的完整过程：为 AI 提供必要的上下文、明确的执行边界和可检查的完成标准，让团队能够持续推进任务，并追溯每次关键决策与变更。

> An AI harness for product development, shaped and validated through real-world enterprise projects.

项目仓库：[minybear/product-harness](https://github.com/minybear/product-harness)。

## 这里的 Harness 是什么

Harness 是围绕 AI 编码智能体建立的一套工作机制，用来回答五个实际问题：

- **当前做什么**：从需求、任务状态和已确认范围中确定下一步。
- **依据什么做**：加载项目规则、产品适配器和当前有效的设计。
- **可以做到哪一步**：区分分析、设计、实施与发布等动作的授权边界。
- **怎样判断做完了**：用验收标准、测试、审查和设计指纹检查结果。
- **下一次怎样接着做**：保存任务快照、阶段交接和必要的追溯记录。

这些机制随项目资产一起维护，接入开发者已有的智能体和代码仓库。

## 来自真实研发过程的工程机制

| 研发中的问题 | ProductHarness 的做法 |
| --- | --- |
| 需求尚未明确就开始实现 | 先勘察现状、澄清范围和验收标准，再推进方案与实施 |
| 多轮对话后丢失进度、重复讨论 | 以任务快照记录当前阶段、已确认结论和下一动作 |
| 设计更新后仍按旧版本开发 | 用设计指纹绑定来源、整合设计与评审记录，实施前检查一致性 |
| 多模块任务遗漏依赖或交付项 | 分别记录子任务状态，检查设计范围和验收覆盖 |
| 不同项目需要不同工程规范 | 通过产品适配器补充模块约束、风险触发条件和测试要求 |
| 完成结论缺少可复核依据 | 记录实际测试、代码审查、未验证项和交付证据 |

## 产品研发流程

```text
需求澄清 → 方案评估 → 关键决策 → 正式设计
                                  ↓
交付归档 ← 测试与审查 ← 授权实施 ← 设计检查与评审
```

具体路径随任务范围与风险调整。轻量分析可以直接给出结论；涉及正式设计、关键决策或受控操作时，按对应流程完成检查和确认。

## 适合哪些项目

- 在已有代码仓库中使用 AI 开展产品研发的团队。
- 需要跨会话、跨模块持续推进需求的长期项目。
- 对设计一致性、变更范围、测试证据和任务追溯有要求的研发工作。
- 希望沉淀共用流程，同时保留各产品工程约束的团队。

公开版本提取通用研发机制，并提供适配模板。使用时应结合自己的项目结构、技术栈和交付要求完成适配。

## 本地安装（Windows）

需要 Git、Windows PowerShell 5.1 或 PowerShell 7；设计指纹工具和 Node 测试需要 Node.js 18+ 与 npm。
宿主接入脚本使用 Windows junction。目前不提供 macOS/Linux 自动接线。

先获取 Hub：

```powershell
git clone https://github.com/minybear/product-harness.git
```

随后在目标业务仓执行，替换 Hub 路径：

```powershell
$hub = "<product-harness 的本地绝对路径>"
& "$hub/scripts/install-product.ps1" -HubRoot $hub -ProjectRoot (Get-Location).Path -NonInteractive
Push-Location tools/design-fingerprint
npm ci --ignore-scripts
Pop-Location
```

安装 15 个 Skill、2 条规则、设计指纹工具和宿主入口。已有 CLAUDE.md / AGENTS.md 正文保留。
覆盖策略三选一：`-Backup` 备份更新、`-SkipExisting` 只补缺失、`-Force` 覆盖。默认遇到同名资产报错。
`-SkipEntryUpdate` 保留入口文件；`-RewireOnly` 在 clone 业务仓后重建链接。
`.cursor/skills` 和 `.agents/skills` 指向 `.claude/skills`，由安装器加入忽略规则。
安装后重启宿主。

## 通用能力

| 类别 | Skill |
| --- | --- |
| 启动与需求 | ai-collab-start、analyze-requirement、init-project-docs |
| 方案与设计 | design-solution、make-decision-card、check-design、aggregate-design |
| 实施与验证 | implement-change、unit-test、code-review、verify-delivery |
| 记录与归档 | write-plan、write-ai-trace、write-worklog、write-issue |

唯一安装清单：[common/pack.json](common/pack.json)。
规则正文：[协作规范](rules/ai-human-collab-v05.md)、[文档治理](rules/doc-governance.md)。
设计指纹工具：[说明](tools/design-fingerprint/README.md)。公共协议为 `design-sha256-v1`；旧版其他命名协议的批准不能直接沿用，应重新计算与确认。

## 产品适配

默认没有真实产品包。`-Product <用户指定的id>` 在缺包时只提供适配模板；增加 `-ScaffoldProduct` 才写骨架。
模板不意味着获得实施许可，也不会自动猜模块清单。
见 [适配套件](common/adapter-kit/prompts/install-with-ai.md) 和 [扩展格式](products/README.md)。

## 维护与验证

```powershell
npm --prefix tools/design-fingerprint ci --ignore-scripts
npm --prefix tools/design-fingerprint test
node scripts/check-public-content.cjs
pwsh -NoProfile -File scripts/test-install.ps1
```

维护本 Hub 时运行 `scripts/prepare-hub-hosts.ps1` 创建本地宿主链接。测试本身无需这些链接。
未来使用远程安装时，向 `-Repo` 提供实际仓库地址；默认分支为 `main`，也可通过 `-Ref` 指定。

## 分发状态

本项目采用 [Apache License 2.0](LICENSE)。你可以在遵守许可证条款的前提下使用、修改和分发本项目。
第三方依赖许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
抽取边界与验证记录见 [公开整理说明](docs/PUBLIC_EXTRACTION.md)。
