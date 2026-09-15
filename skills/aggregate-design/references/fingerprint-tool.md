# 设计指纹统一入口

本仓库计算实现与协议唯一入口：仓库根目录 `tools/design-fingerprint/README.md`。详细序列化只在那里维护。

从仓库根目录执行：

```text
node tools/design-fingerprint/fingerprint.cjs calculate . <任务00的仓库相对路径>
node tools/design-fingerprint/fingerprint.cjs verify . <任务00的仓库相对路径>
```

生成：先完成 03A 正文和文首 task_id/artifact_revision，以及 `00.design_review.artifact/artifact_revision`，调用 calculate。将输出 `hash_version/source_set_hash/artifact_hash` 写入 03A 文首及 `00.design_review`，然后 verify。来源 content_hash 与 checked_hash 仍须由正式发布和完整自检获得，不能让 calculate 替代自检。

批准：verify 成功后才按真实用户批准回填 reviewed_hash/reviewed_source_set_hash；再 verify。工具不授予审批或实施权限。

实施/验证/续作：调用 verify，检查退出码及报告。hash-match 之后仍检查当前批准、决策和独立限域授权。

没有 hash_version → legacy-unverifiable；未知版本、缺文件、解析失败 → 证据不足。保留原状态、原指纹、原批准；仅阻断依赖该证据的动作，先恢复旧生成命令/批准时内容或准备限域迁移评审。不能将“不能复算”直接当“正文变了”，不得枚举算法、按 mtime 下结论或覆盖旧批准。无需重开需求访谈或重做无关设计。

v1 与旧版不兼容，禁止将旧 hash 改成候选值并沿用原 approved。新任务和显式迁移后的任务使用 v1；已有任务先审计并记录迁移证据。
