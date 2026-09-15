# 生成产品技术规则

你在一个**已经装完通用层**的业务仓里。通用规则已经安装，不要重复生成：

- `ai-human-collab-v05.md`
- `doc-governance.md`

读取：

- `.claude/adapter-kit/kit.yaml`
- `.claude/adapter-kit/product-rule.md.tpl`
- `.claude/product.yaml`（若有）

## 强制顺序

### A. 勘察

读本仓技术规范、模块边界、红线类文档。判断哪些约束应成为 **产品规则**（随本产品安装，而不是通用协作流程）。

### B. 提议（先停下来等用户）

只输出建议的规则文件名与职责，**不要写文件**。  
先勘察当前项目已有规范，再建议必要规则文件；确认后才写入。

### C. 用户确认后再生成

按 `product-rule.md.tpl` 写入 `.claude/rules/{file}.md`。只写本仓证据。若用户要求更新 `CLAUDE.md`，只追加 `@./.claude/rules/{file}.md` 标记块，不覆盖整份入口。

## 不要做

- 不要把通用协作规范抄进产品规则
- 只使用用户指定的产品 ID 与当前项目已验证的模块和规则；不得复用其他产品的专用资产。
- 不要在未确认时写规则文件
