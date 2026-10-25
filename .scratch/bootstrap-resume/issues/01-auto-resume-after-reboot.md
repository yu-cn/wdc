# 01: 重启后自动续跑 bootstrap（登记—续跑—自清）

**What to build:** bootstrap 请求重启（WSL 功能启用触发）前登记一次性续跑任务；
重启登录后自动重跑 `bootstrap.ps1` 收敛剩余阶段并收尾，全程无需人工操作。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] bootstrap-main 在请求重启前登记一次性续跑（schtasks，提权，登录触发）；
      非「已请求重启」路径不登记，无循环可能
- [ ] 续跑 = 重跑 `bootstrap.ps1`（幂等收敛），完成后任务自删（成功/失败均清）
- [ ] 续跑日志落 `logs/`；`verify-machine.ps1` 全绿即验收
- [ ] README「五件事」第 3 条改写为自动续跑语义；手工路径保留为兜底说明
- [ ] validate.ps1 全绿（PSScriptAnalyzer Error 级通过）

## Comments

- 2026-10-25（对标评估会话）：立单。设计约束与否决项见同目录 [spec.md](../spec.md)。
