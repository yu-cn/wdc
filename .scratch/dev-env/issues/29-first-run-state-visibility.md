# 29: 首跑状态可见性 + wdc 子命令友好报错

**What to build:** 体验评估结论（2026-10-22 会话，主人批准 A+B）：四张体验工单（16/18/20/24）后主干交互已完整，剩余缺口集中在「首跑五件事」里两件手工事的**状态不可见**与 wdc 报错不友好。① 身份占位：`~/.gitidentity` 未填时现状只在流程中一行 CHANGED 一闪而过，要到第一次 git commit 被「防错护栏」拒了才发现——反馈太晚；② WSL 待续跑：启用后待重启/Ubuntu 未装状态无任何持续可见面；③ `wdc` 打错子命令报 PowerShell ValidateSet 原生英文错误。落地：`wdc status` 增「身份文件」「WSL」两步（效果级判定，与 verify 断言同口径）；bootstrap Summary 在占位未填时给 CHANGED 提醒（**不入 Stages、不影响退出码**——身份是首跑手工步骤，非收敛失败）；未知子命令友好报错（黄字 + help）。探测全部静态无机制层（RunOnce 自动续跑方案明确不做，主人简单优先原则）。

**Blocked by:** None

**Status:** ready-for-agent

- [x] `lib/common.ps1`：`Test-GitIdentityEffective`（`--global --includes` 效果级，只判非空不打印值——红线；避开 cwd 仓库 local config 污染，坑⑤）+ `Test-WslEnabled`（Get-Command 守卫；注释标明提权上下文勿调，坑①）
- [x] `scripts/wdc.ps1` status：dotfiles 漂移之后加「身份文件」「WSL」两步；提权终端跑 status 时 WSL 探测 SKIP（坑①守卫）
- [x] `scripts/wdc.ps1`：ValidateSet 改为体内校验——未知子命令黄字提示 + 打印 help、退出码 1；help 分支复用同一段文本
- [x] `bootstrap-main.ps1` Summary：非 `-ValidateOnly` 且身份未生效时 `CHANGED` 提醒一行（不计失败、不改退出码）
- [x] `scripts/install-wsl.ps1`：`wsl --status` 探测改用 `Test-WslEnabled`（单一来源去重）
- [x] 本机实测：`validate` 全绿；`wdc status` 两新步输出；`wdc staus`（打错）友好报错；`wdc help` 正常
- [ ] 两机复验：ASUS 下次 sync 后 `wdc status` 输出观感（探测延迟、无误导报）

## Comments

- 2026-10-22（主机）：WSL 两步的处置文案刻意指向管理员终端 `wsl --install` 手工路径——bootstrap 自身走不通 WSL 启用（见工单 30），文案不能承诺 bootstrap 能做它做不到的事。
