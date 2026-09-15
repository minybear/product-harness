# 生成产品模块 Skill

你在一个**已经装完通用层**的业务仓里。安装器**不知道**本仓有哪些模块，因此不会预告任何 Skill 路径。

读取：

- `.claude/adapter-kit/kit.yaml`
- `.claude/adapter-kit/module-skill/SKILL.md.tpl`
- `.claude/product.yaml`（若有）

## 强制顺序（不可颠倒）

### A. 勘察

扫描本仓代码与文档，识别需要「模块挂载 Skill」的边界（服务、包、协议、门户等）。  
`unit-test` 与 `code-review` 已在通用层，**不要**再提议生成它们。

### B. 提议（先停下来等用户）

只输出一张建议表，**此时不要写文件**：

| 建议 Skill 目录名 | 覆盖的本仓模块/路径 | 建议的文件（SKILL.md 及是否需要 references） | 依据 |

禁止用其他产品的目录名凑数。没有把握的行标为「建议确认」。

### C. 用户确认后再生成

用户明确同意名单后，才按 `SKILL.md.tpl` 写入：

`.claude/skills/{name}/SKILL.md`

以及用户确认过的 references。内容必须来自本仓事实；形态可以参考「模块开发 Skill」（判断 / 分层 / 验收 / 输出结构），但不得复制其他产品的包名、类名、集成策略正文。

### D. 回填

把已生成且用户确认的 Skill 名写入 `.claude/product.yaml` 的 `module_skills[]`。

## 不要做

- 不要在用户确认前创建 Skill 目录
- 只使用用户指定的产品 ID 与当前项目已验证的模块和规则；不得复用其他产品的专用资产。
- 不要生成通用流程 Skill（analyze-requirement 等已安装）
