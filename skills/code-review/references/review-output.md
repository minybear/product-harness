# 审查输出

```markdown
## 代码审查（三轴）

**范围**：本次 diff / 文件列表
**对照**：03A revision … / 01 验收
**人审**：待确认（AI 不能单独通过）

| 轴 | 结论 | 摘要 |
|---|---|---|
| 安全 | pass / fail |  |
| 需求覆盖 | pass / fail |  |
| 最简实现 | pass / fail |  |

### Blocker
1. `path:line` — 轴：安全|覆盖|最简
   - 现在：
   - 应改：
   - 依据：redlines / 03A § / 本清单

### Major
…

### Minor
…

### 通过项
- ✅
```

默认对话不要甩 YAML。`verify-delivery` 机器摘要用：

```yaml
code_review:
  required: true
  independent_of_implement_session: true
  human_review: "pending | approved | changes-requested"
  security: "pass | fail | skipped"
  requirement_coverage: "pass | fail | skipped"
  simplicity: "pass | fail | skipped"
  blockers: []
```
