# 用例清单

按本轮 **03A / 01 验收** 裁剪，不为分类而凑数。

每个被测方法优先覆盖：

| 类型 | 何时写 |
|---|---|
| happy path | 主成功路径，必写 |
| invalid / 业务拒绝 | 设计中的错误码、校验、权限失败 |
| null / empty | 入参或集合可能为空时 |
| boundary | 有阈值、长度、状态机边界时 |
| dependency failure | 有 mock 的下游/DAO/Redis 失败与降级 |
| concurrency | 仅当设计要求幂等/并发且代码有共享状态 |

输出给用户的短表：

```markdown
## 单元测试

**文件**：
**命令**：`./gradlew :{service}:test --tests '...'`
**运行**：passed / failed / not_authorized

| # | 用例 | 类型 | 对应验收 |
|---|---|---|---|
| 1 | | happy path | 03A §x |
```
