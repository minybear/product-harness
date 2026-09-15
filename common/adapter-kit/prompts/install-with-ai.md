# 使用 AI 安装通用协作资产

在当前业务仓执行安装，使用者应提供已下载的 Hub 路径。

```powershell
$hub = "<ai-collab-hub 的本地绝对路径>"
& "$hub/scripts/install-product.ps1" -HubRoot $hub -ProjectRoot (Get-Location).Path -NonInteractive
```

默认安装通用 Skill、规则、设计指纹工具与宿主入口。不会登记真实产品。
已有资产时按用户选择使用 `-Backup`、`-SkipExisting` 或 `-Force`；三者互斥。
安装保留已有 CLAUDE.md 和 AGENTS.md 正文，只维护自己的顶部标记块。
不要写用户主目录。`.cursor/skills` 与 `.agents/skills` 是本地 junction，不提交。

只有用户明确给出产品 ID 时才使用 `-Product <id>`；缺包时仅拷模板。
明确要求生成产品骨架时增加 `-ScaffoldProduct`，随后按生成提示词核实仓库与模块证据。
不要根据目录名猜产品或预生成模块 Skill。

安装后在业务仓 `tools/design-fingerprint` 执行 `npm ci --ignore-scripts`，安装工具依赖。
检查通用 Skill、规则、工具、入口与 junction，然后重启宿主使其重新加载。
clone 已安装资产的业务仓后，可用同一脚本的 `-RewireOnly` 重建链接。
