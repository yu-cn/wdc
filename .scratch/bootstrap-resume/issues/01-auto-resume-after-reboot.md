# 01: 重启后自动续跑 bootstrap（登记—续跑—自清）

**What to build:** bootstrap 请求重启（WSL 功能启用触发）前登记一次性续跑任务；
重启登录后自动重跑 `bootstrap.ps1` 收敛剩余阶段并收尾，全程无需人工操作。

**Blocked by:** None (can start immediately)

**Status:** done

- [x] 登记一次性续跑（登录触发计划任务，提权 RunLevel Highest）——登记点在 install-wsl 的
      需重启分支（3010/1641/0），非重启路径不登记，无循环可能
- [x] 续跑 = 重跑 `bootstrap.ps1`（幂等收敛）；任务自清在续跑启动时即完成（bootstrap-main
      真实收敛启动点 Remove-WdcResumeTask）——成功/失败均不留残留
- [x] 续跑日志落 `logs/`（续跑即普通 bootstrap 运行，transcript 同口径）；verify 全绿即验收
      + verify-machine 新增「续跑任务已清」断言兜底（存续 = 有一次重启后的收敛没跑完）
- [x] README「五件事」第 3 条改写为自动续跑语义；手工路径保留为兜底说明
- [x] validate.ps1 全绿（PSScriptAnalyzer Error 级通过）

## Comments

- 2026-10-25（自主执行会话）：完成。任务名 `WdcBootstrapResume`（GLOSSARY「续跑任务」）。
  触发器 scoped 到发起 bootstrap 的用户登录——不带 -User 的「任意用户登录」触发器实测被拒注册
  （非提权 Access denied），语义也过宽；走 ScheduledTask API 免 schtasks 引号地狱。
- 验证口径（诚实记账）：Limited RunLevel 等价管道端到端实测通过（登记 → 读回 execute/args/触发用户
  → 清除）；`RunLevel Highest` 需提权——真实调用点永远在提权子回合，非提权失败路径实测优雅降级
  （INFO + 手工指引，不打红）。Highest 全链路留待下次真实新机首跑或 fresh-machine 手动触发覆盖。
  本会话未真实重启（不动主人机器）；续跑动作 = 重跑幂等 bootstrap，无新增机制风险。
