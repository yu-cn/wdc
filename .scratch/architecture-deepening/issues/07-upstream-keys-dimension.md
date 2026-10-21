Status: ready-for-agent

# 07 · check-upstream 的 keys 维度：补完或删除

## 问题

脚本自称提取「winget 包 ID 与注册表键」，但 keys 只收集进基线、从不参与差异报告；且我们的 keyPath 被灌进名叫 `$upstreamKeys` 的上游集合（变量名说谎，基线已污染）。deletion test：删掉 keys 相关全部代码，报告输出一字不变——纯死重 + 未来做 keys diff 时的脏基线炸弹。

## 方案候选（环境主人定夺）

- **A**：补 keys 差异维度，兑现设计承诺（顺带修灌错：我们的键只进 ours 系集合）
- **B**：删除 keys 维度（YAGNI，包维度够用）；`-UpdateBaseline` 重建干净基线

## 验收清单

- [ ] 二选一经定夺并记录于 Comments
- [ ] 脚本输出与自称一致；基线干净
- [ ] validate.ps1 全绿

## Comments

- 2026-10-21 开单（架构评估候选 7，Speculative——低频脚本）。
