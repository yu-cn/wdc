# Fork 指南：改造成自己的环境后，如何跟随上游

README「使用与改造」讲了 fork 初次改造；本文讲之后的日子：你的 fork 与 [yu-cn/wdc](https://github.com/yu-cn/wdc)（上游）都会演进，怎么跟。

## 一次性设置

- 按改造清单改完 `configs/` 与 `dotfiles/`（见 README），`LICENSE` 版权人换成你自己
- fork 的 Actions 默认禁用：到你 fork 的 Actions 页启用 validate / fresh-machine 工作流
- `.scratch/` 是上游作者的内部工单流，fork 可直接删——留着只会给合并制造噪音

## 日常跟随上游

```bash
git remote add wdc https://github.com/yu-cn/wdc.git   # 一次性
git fetch wdc
git merge wdc/main          # 或收敛到已知好点：git merge wdc/v0.1.0
```

冲突预期（按层，ADR-0002 的分层恰好是合并策略）：

- `scripts/` 机制层：基本不冲突；上游改 bug/行为时倾向收上游
- `configs/` 与 `dotfiles/` 偏好层：冲突即你们的喜好分叉，倾向保留你的
- `wdc status` 的「上游检查」提醒读的是上游作者的吸收账本，fork 用户可无视

## 版本锚点

上游不承诺兼容性，但 tag（如 v0.1.0）标记「发布时验证全绿」的提交——想稳就跟 tag 走，想要新特性就跟 main。
