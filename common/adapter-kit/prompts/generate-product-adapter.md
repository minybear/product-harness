# 生成产品适配器（product.yaml）

你在一个**已经装完通用层**的业务仓里。读取：

- `.claude/adapter-kit/kit.yaml`
- `.claude/adapter-kit/product.yaml.tpl`
- 若已有 `.claude/product.yaml`，在其上补全，不要换字段名

## 必须做

1. 使用用户指定的产品 ID；未提供时先确认，再核实当前项目的模块和规则。
2. 扫描本仓：模块目录、服务边界、已有 `AGENTS.md` / 技术规范。能查到的填进 `owns` / `does_not_own` / `git_repo` / `docs_root`。
3. `module_skills[]` 这一步先留空数组。模块 Skill 要等「生成模块 Skill」那一步：Agent 先提议、用户确认后再回填。
4. 缺证据的字段保持 `missing_evidence` 或 `incomplete` / `catalog-only`。禁止编造仓库路径、批次上限、停止线。
5. 风险触发器只能升高风险，不能降低通用模型。
6. 不要把其他产品的模块名写进 `module_skills[]`。

## 不要做

- 不要创建 `.claude/skills/{name}/` 目录
- 只使用当前项目的真实规范，不复制其他项目专用规则
- 不要把 `unit-test` / `code-review` 写进 extras；它们已在通用层

## 完成标准

- `.claude/product.yaml` 含 `product_id` 与契约字段
- `status` 与证据匹配（无证据不得写成 complete + executable）
- 向用户列出仍为 `missing_evidence` 的字段
