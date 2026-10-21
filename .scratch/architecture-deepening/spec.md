# 架构深挖（architecture-deepening）

2026-10-21 架构评估（ask-matt 路由 improve-codebase-architecture；走查 bootstrap 入口/编排层 13 个脚本、两个 CI workflow、configs/dotfiles/docs）产出七个深挖候选，母题一致：**机器事实缺单一事实源**。评估报告为会话内 HTML（不入仓库），候选详情以本组工单为准。

## 决策（环境主人，2026-10-21）

七条全有意义，按推荐序落地：01/02/03 同日实施并真机收口（01/02 验收全过归档 done/；03 余一项 `wdc sync` 冒烟，ready-for-human）；06 先查证再定改法；04/05/07 排队 ready-for-agent，任一机器会话可领。

## 工单

| # | 工单 | 强度 | 状态 |
|---|---|---|---|
| 01 | vp 语言栈事实单一来源 | Strong | done（已归档） |
| 02 | dotfiles 落点映射单一事实源 | Strong | done（已归档） |
| 03 | Invoke-Subscript 子脚本深模块 + 阶段编号收敛 | Strong | ready-for-human（余 sync 冒烟） |
| 04 | winget 域发现：一套机制替代两套 | Worth exploring | ready-for-agent |
| 05 | WSL 调用与探测适配层 | Worth exploring | ready-for-agent |
| 06 | winget 退出码语义收一处（先查证） | Worth exploring | ready-for-agent |
| 07 | check-upstream keys 维度：补完或删除 | Speculative | ready-for-agent |
