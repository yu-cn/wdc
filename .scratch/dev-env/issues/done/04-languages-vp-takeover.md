# 04: languages 域——vp 接管与双轨清理

**What to build:** 环境主人打开新终端即得 vp 管理的 Node（pwsh profile 自动 source vp 的 env 脚本），node/npm/pnpm 全部经 vp 解析；同时移除清单首批执行完毕：直装 Node 卸载、nvm-windows 卸载（含 C:\nvm4w symlink 与 NVM 环境变量）、直装 Python 3.13 卸载（Python 全归 uv）、.NET SDK 10 与 ASP.NET 运行时卸载（Desktop 运行时保留不动）。

**Blocked by:** 01, 02

**Status:** ready-for-agent

- [ ] vp 以 `irm https://vite.plus/ps1 | iex` 方式安装且钉 VP_VERSION
- [ ] node/npm/pnpm 在新终端中经 vp 解析（vp env current 正常）
- [ ] pwsh profile 自动 source vp env
- [ ] 直装 Node 与 nvm-windows（symlink+环境变量）清除干净
- [ ] 直装 Python 清除，python 全由 uv 提供
- [ ] .NET SDK 与 ASP.NET 运行时清除，Desktop 运行时仍在
- [ ] 重跑 bootstrap 幂等

## Comments

- 2026-10-19（自主执行会话）：已完成并通过验收标准，实现落在对应 commit（git log 按工单号检索）。
