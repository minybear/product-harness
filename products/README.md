# 项目扩展包

此目录不包含真实产品适配器。下游可以在自己的私有 Hub 中提供 `products/<id>/pack.json`：

```json
{"id":"example-app","status":"available","skills":["example-module"],"rules":["example-rule.md"]}
```

将实际正文放入该包的 `skills/<name>/SKILL.md` 和 `rules/<file>.md`。
这是格式示例，不是可安装产品。产品 ID、Skill 名和规则文件名必须是安全的单段名称。
缺包时安装器仅提供生成说明，模板保持 `incomplete` / `catalog-only`。
适配器不应通过公共仓库暴露内部地址、用户数据、凭据或公司专用实现。
