# 架构深挖（architecture-deepening）

2026-10-21 架构评估（ask-matt 路由 improve-codebase-architecture；走查 bootstrap 入口/编排层 13 个脚本、两个 CI workflow、configs/dotfiles/docs）产出七个深挖候选，母题一致：**机器事实缺单一事实源**。评估报告为会话内 HTML（不入仓库），候选详情以本组工单为准。

## 决策（环境主人，2026-10-21）

七条全有意义，按推荐序落地：**01-07 全部实施并收口归档**（03 的 sync 冒烟 2026-10-21 完成：提权侧回归确认通过，暴露一个外部事实——字体包被 winget 目录除名，移交 `.scratch/cascadia-font-source/`）。本特性关账。

## 工单

| # | 工单 | 强度 | 状态 |
|---|---|---|---|
| 01 | vp 语言栈事实单一来源 | Strong | done（已归档） |
| 02 | dotfiles 落点映射单一事实源 | Strong | done（已归档） |
| 03 | Invoke-Subscript 子脚本深模块 + 阶段编号收敛 | Strong | done（已归档；sync 冒烟通过） |
| 04 | winget 域发现：一套机制替代两套 | Worth exploring | done（已归档） |
| 05 | WSL 调用与探测适配层 | Worth exploring | done（已归档） |
| 06 | winget 退出码语义收一处（先查证） | Worth exploring | done（已归档） |
| 07 | check-upstream keys 维度：补完或删除 | Speculative | done（已归档；主人定夺 B 删除） |
