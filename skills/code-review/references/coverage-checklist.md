# 需求覆盖轴

对照物优先级：hash 匹配的 `03A` 验收矩阵 > 已确认 `01` 验收 > 实施授权 scope。不得用聊天里的新想法扩范围。

对每个相关验收项标注：`covered` / `partial` / `missing` / `out-of-scope`。

| 查 | 失败含义 |
|---|---|
| 03A/01 主路径是否有对应代码 | missing → Blocker |
| 设计中的错误/降级/权限分支 | 缺关键失败路径 → Major 或 Blocker |
| 单测是否覆盖上述行为 | 无测且行为非纯展示 → Major |
| diff 是否超出 workstream/授权 | 多余功能 → Major（过度实现，同时记最简轴） |
| 接口字段/错误码是否与契约一致 | 漂移 → Blocker |

UI 行为以项目已登记的界面约束与验收标准为准。
