---
name: code-review
version: 0.2.0
description: 按安全、需求覆盖和最简实现三方面审查当前 diff，提供可复核的问题及验证证据。由 verify-delivery 调用。
---

# 代码审查

1. 确定授权内的变更文件与验收标准；有正式设计时使用当前已批准版本。
2. 阅读项目实际存在的工程约束及适配器 `review_extras[]`，不依赖特定公司的技术规则。
3. 按 `references/security-checklist.md`、`references/coverage-checklist.md` 和 `references/simplicity-checklist.md` 审查。
4. 每个问题提供文件、行号、触发条件、影响及建议；分为 Blocker / Major / Minor。
5. 使用 `references/review-output.md` 输出证据与未验证项，避免仅凭编写代码就声称完成独立审查。
6. 阻塞问题返回 `implement-change`；需要人工决定时明确具体事项。要求人审的流程，人工确认前不得标为审查通过。

UI 验收由项目自己的 UI 约束补充。无问题时明确说明审查范围和验证限制，不制造凑数问题。
