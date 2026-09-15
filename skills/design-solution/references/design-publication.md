# 正式设计发布模板

仅在决策已经确认、`workflow_handoff.current_stage=design-publication` 且获得文档写入授权时读取。

```markdown
# {主题} 设计

状态：有效 / 待更新 / 已废弃
模块：{模块}
来源 task_id：{task_id}
来源任务档案：`docs/{项目}/tasks/{task}/`
决策记录：`03-决策记录.md` / 持久化 decision_ref
revision：{revision}
最后更新：{yyyyMMdd}

## 1. 目标与边界

## 2. 已确认设计

## 3. 接口、事件或调用契约

## 4. 数据、配置与兼容性

> 有运行配置/开关/阈值变更时，必须同时写清 **前端配置入口** 决策（与 `01` 一致）：

- **需前端入口**：菜单/路由（如该项目现有配置页路径）、配置键/命名空间、表单字段、默认值、校验、权限、保存后如何生效；优先写“扩展现有配置页”而非新造菜单。
- **仅运维手推**：维护角色、推送方式、为何不暴露给用户；集成模板/南向 JSON/协议模板等研发向配置默认仅运维手推，除非 `01` 已确认用户可编辑。
- **不涉及配置**：本节只写数据/兼容性，不强行写前端入口。

## 5. 错误处理、回滚与停止条件

## 6. 实施约束与验证要求

## 7. 依据与领域证据

> 有协议/外部系统契约时必填。复用并对齐 `01-需求分析.md` 证据索引；仅 `confirmed` 可写入正文契约。

## 8. 变更控制
```

约束：只写经确认的结论；不得包含候选方案、访谈过程、未决问题、完整 trace 或未批准的字段。多个模块分别发布设计文件；任务快照必须登记每个实际路径。涉及 领域协议或外部服务 等协议时，发布前按 `../analyze-requirement/references/domain-research.md` 完成 P1 证据复核；不得把 `inferred/unknown` 升格为正式契约。范围含前端/门户展示时追加「前端展示」节，按适配器登记的模块 UI Skill 填写；无前端变更不写空章。

发布后计算文件 SHA-256，原子更新 `00`：

- artifact 的 `workstream_ids[]/source_revision/content_hash/check_status=pending`
- 清空旧 checked 指纹
- `design_review.required=true/status=pending`
- 清空旧 03A 与 reviewed 指纹
- `next.skill=check-design`

再同步 `docs/{项目}/INDEX.md`、`design/README.md`、任务 INDEX 和 trace。`02-方案评估.md` 只保留评估依据与未决事项，并链接正式设计。
