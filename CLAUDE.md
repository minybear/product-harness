# AI Collab Hub 维护入口

@./rules/doc-governance.md
@./rules/ai-human-collab-v05.md

本仓只分发通用 AI 协作资产。`common/pack.json` 是安装清单，正文在 `skills/` 与 `rules/`。
产品适配器由下游项目维护，模板在 `common/adapter-kit/`。
设计指纹实现为 `tools/design-fingerprint/fingerprint.cjs`，协议版本 `design-sha256-v1`。
修改资产需更新相应版本、README 与必要测试，实际运行后才记录通过。
本地维护默认在已有授权范围内完成，不因例行检查或新一轮消息重复索取相同授权。
