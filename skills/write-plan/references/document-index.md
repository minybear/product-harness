# 文档索引契约

本参考只定义索引的最小结构和读取路径。索引不是需求摘要的第二份正文。

## 目录

```text
docs/{项目}/INDEX.md
docs/{项目}/tasks/README.md
docs/{项目}/tasks/{task}/INDEX.md
docs/{项目}/design/README.md
```

## 状态职责

| 内容 | 唯一事实源 | 索引如何处理 |
|---|---|---|
| 当前阶段、状态、唯一 `next.skill` | task `00-需求概览.md` | 镜像链接和一句话摘要 |
| 需要用户处理的事项 | 版本/任务 INDEX 的“需要你处理”区 | 等待输入、授权、阻塞原因、open issue 和可直接回复动作 |
| 任务/正式设计清单 | 版本 INDEX、tasks/README、design/README | 登记路径和状态，不复制正文 |
| 已批准决策 | `03-决策记录.md` 顶部确认表 | 登记决策编号和批准条件 |
| 来源正式设计 | `design/{模块}/*.md` | 已批准来源、审计、争议和 freshness 入口 |
| 最终完整实施契约与人工评审 | hash 匹配且已批准的 `03A-聚合详细设计.md` | 默认实施入口、完整性/freshness 和评审状态 |
| 候选方案和需求证据 | `01/02` | 仅按需读取 |
| 历史 AI 过程 | `06-AI作业追溯.md` | 仅审计或历史恢复时读取 |

## 默认读取

```text
版本 INDEX → 任务 INDEX → 00 → 已批准且 hash 匹配的 03A
```

只有以下情况才追加读取：

- 审计、争议、freshness 或 03A 标记 gap：读取对应来源 design 与 `03` 顶部确认表。
- 需要事实、证据或未决问题：读 `01-需求分析.md`。
- 需要候选方案和取舍理由：读 `02-方案评估.md`。
- 需要追查历史判断、人工确认或异常：读 `06-AI作业追溯.md`。

## 更新规则

- 新建任务：同时创建或更新版本 INDEX、tasks/README 和任务 INDEX。
- 阶段迁移、决策确认、正式设计发布、授权变化：先更新 `00` 和任务 INDEX，再追加 trace。
- 生成、批准、退回或判定整合评审过期：同步更新 `00.design_review`、任务 INDEX 和 trace；来源设计变化时不得继续显示“已批准”。
- 新增、解决或转移 `waiting-user` / `blocked` 子流：同步更新版本/任务 INDEX 的“需要你处理”区；相关回复必须播报全部 workstreams。
- 决策批准后：`02` 标记为方案评估归档并链接正式设计；不得把完整设计重新复制回 `02`。
- `03` 顶部只维护当前决策登记；生成时 handoff 或完整卡片必须标明历史性质，不能被路由读取。
- 索引缺失时可以补建，但不得因为索引缺失新建第二个任务目录。

## 任务 INDEX 最小模板

```markdown
---
index_type: task
task_id: ""
current_stage: ""
status: ""
next_skill: ""
attention_required: false
waiting_user_count: 0
---

# Task Index

## 当前动作

## 需要你处理

## 子工作流

## 来源与状态职责

## 当前读取路径
```
