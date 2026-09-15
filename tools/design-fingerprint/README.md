# 设计指纹工具

统一计算实现：`fingerprint.cjs`；Node.js 18+。仅执行读取和输出 JSON，不修改设计、快照或审批。

在本目录执行 `npm ci` 安装锁定的 YAML 解析器。核心 hash 计算仅使用 Node 标准库。

从仓库根目录运行：

```text
node tools/design-fingerprint/fingerprint.cjs calculate . docs/项目/tasks/任务/00-需求概览.md
node tools/design-fingerprint/fingerprint.cjs verify . docs/项目/tasks/任务/00-需求概览.md
node tools/design-fingerprint/fingerprint.cjs audit .
node tools/design-fingerprint/fingerprint.cjs file . docs/项目/design/模块/主题-设计.md
node --test tools/design-fingerprint/fingerprint.test.cjs
```

`file` 只计算单个来源文件的原始字节 `content_hash`。`calculate` 生成候选指纹，退出 0 只代表成功计算，不代表审批通过。`verify` 仅在所有指纹、来源自检和覆盖检查匹配时退出 0；旧版、缺失、格式错误或不匹配退出 2。`audit` 扫描 `docs/**/tasks/**/00-需求概览.md`，发现任何不可验证项退出 2。报告中的 `not-applicable` 不是设计/授权准入结论。

## 唯一协议：design-sha256-v1

- `hash_version` 同时写入 03A 文首和 `00.workflow_handoff.design_review`。没有版本绝不默认套用 v1。
- 来源 `content_hash` 保持原契约：**文件原始字节**的 SHA-256。来源 CRLF/LF 或 BOM 改变也算字节变化，不静默迁移。revision 是非空单行字符串，不能用当前 HEAD 替换已登记 revision。
- SHA-256 输出小写十六进制；输入 hash 接受大小写并转小写。路径只接受仓库相对 `/` 路径，拒绝 `..`、反斜线、空段和越界软链接；不改路径大小写或 Unicode 编码。
- 来源按路径 UTF-8 字节顺序排序，禁止重复路径。序列化为下面数组的 `JSON.stringify` 紧凑结果，UTF-8 无 BOM，无末尾换行：

```text
["design-sha256-v1","sources",[[path,source_revision,content_hash],...]]
```

- 03A 严格 UTF-8 解码，移除编码 BOM，CRLF/CR 转 LF。正文取实际 Markdown 二级标题 `## 1.` 起到 EOF；必须依次且仅出现第 1～11 章。围栏代码中的标题不参与边界识别；未闭合围栏拒绝。标题允许 `.`、`、`、`．`，数字后标点后须空白或行尾。
- 正文每行移除末尾 ASCII 空格和 tab，末尾空行统一为一个 LF；不改变内部空白、Unicode、代码块内容或正文中的字段名。第 0 章和文首在正文之外，不参与 hash；不得在正文放需要回填的 hash 自身。正文里的 `reviewed_*` 等字样不会被全局删除。
- 03A 候选 hash 是以下数组的 `JSON.stringify` 紧凑结果的 UTF-8 SHA-256，无 BOM、无额外末尾换行：

```text
["design-sha256-v1","artifact",task_id,artifact_revision,source_set_hash,body]
```

- task_id 和 artifact_revision 从文首读取且必须与任务文档/快照一致。第 11 章也绑定；修改其中来源记录后须重新计算。写入计算结果只能改文首和快照，写后再次 `verify`。
- `hash_gate_pass` 只证明指纹、自检绑定及覆盖一致，**不是实施许可**。下游仍检查设计批准、决策及独立限域授权。待评审文档可 hash-match，但不能因此进入实施。

## 旧档案与异常处理

`legacy-unverifiable` 表示算法证据缺失，不等于正文变化或原值伪造。保留原始 hash、批准人、时间、revision 和原文件，禁止猜多个口径、直接覆盖旧批准、以 mtime 证明内容未变。

1. 读取历史生成命令和批准时的可信版本/备份；只使用有证据的旧算法复算，不枚举口径。
2. 能证明批准内容等价：形成旧值→v1 候选值迁移记录，列批准内容证据、工具版本及文件原始 SHA-256；经该任务适用的评审授权后回填，不能仅因工具输出成功继承批准。
3. 不能证明：保留历史，重新对当前 03A 限域评审；只在发现真实来源缺口时回设计，不能重新访谈。
4. 缺文件、未知版本或解析失败：保持业务阶段及原 next.skill，报告证据恢复阻塞，只阻断依赖该指纹的动作。

本工具不提供“自动批准”“覆盖旧 hash”或修复业务档案的写入模式。

## 回归证据

`fingerprint.test.cjs` 包含固定 SHA-256 向量、精确序列化输入、跨平台规范化、正文变异、章节误识别、非法路径、重复 YAML、旧版本、审批绑定及覆盖测试。修改协议必须发布新版本，不能改变 v1 的计算结果。
