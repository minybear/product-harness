# 设计自检输出模板

仅在 `check-design` 获得限域落盘授权后写入
`tasks/{任务}/02A-设计自检.md`。每次覆盖必须保留任务全部 published artifacts。

```markdown
# 02A 设计自检

task_id：{task_id}
生成时间：{yyyyMMdd HH:mm:ss}
report_revision：{revision}
范围：全部已发布正式设计

## 总览

| workstream_ids | 来源路径 | 模块 | source_revision | content_hash | checked_revision | checked_hash | check_status | 失败项 |
|---|---|---|---|---|---|---|---|---|---|

## 需设计 workstream 覆盖

| workstream_id | design_required | 覆盖 artifact | 结果 |
|---|---|---|---|

artifact `workstream_ids` 并集必须覆盖全部 `design_required!=false` 的 workstream；缺失映射时整份报告不得转交聚合。

## 来源 {path}

- workstream_ids：
- source_revision：
- content_hash：

### 证据链

| 结论摘要 | 来源 | 结果 | 说明 |
|---|---|---|---|

### 细节闭环

| 检查点 | 结果 | 缺口 |
|---|---|---|

### 说法自洽

| 检查点 | 结果 | 冲突 |
|---|---|---|

## 转交

- 全部来源同时满足 `check_status=pass`、`checked_revision=source_revision`、`checked_hash=content_hash`：`aggregate-design`
- 存在 fail：`design-solution`；禁止融合；不开启需求访谈
```

约束：

- 结果只能是 `pass` 或 `fail`；未核到必须标 `fail`。
- pass 必须同时记录与当前来源相等的 `checked_revision` 和 `checked_hash`。
- 报告中缺少任一 published artifact 时，整份报告无效。
- 局部重检必须重新生成包含全部来源的完整快照；不得让其他 pass 指向不含自身的报告。
- 不得粘贴密钥、生产连接串或大段源码。
- `02A` 不是人审主入口或正式设计基线。
