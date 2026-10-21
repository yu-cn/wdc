# 04: 裸机入口降门槛——前置只需 Git（5.1 自举 PS7 后转发执行）

**What to build:** 环境主人指示（2026-10-21）：改善其他用户使用体验，最好只需先安装 Git。现状前置是 Git + PowerShell 7 两条。定案（主人提议）：先用 5.1 装 7，再用 7 执行。方案：根 `bootstrap.ps1` 重写为 5.1 兼容引导层（探测 pwsh → 缺则 winget 用户级安装 → PATH 注入 → 原样带参转发）；收敛本体移至根 `bootstrap-main.ps1`（`#Requires 7` 与全部 `$PSScriptRoot` 路径语义不变，提权子回合 `$PSCommandPath` 自指照旧）；validate.ps1 静态检查纳入 main；README 快速开始改一条三 shell（cmd/PowerShell/Git Bash）通用命令。Git Bash 专属入口（.sh）讨论后不做：管线本就是 PowerShell，bash 只能当包装（同两跳），且 MSYS/mintty 管道徒增已知坑同族的失败面；通用命令在 Git Bash 本就直跑。

**Blocked by:** None

**Status:** ready-for-agent

- [x] `bootstrap-main.ps1`：原 bootstrap.ps1 全量搬移至仓库根（同目录故路径零改写），仅头部注释更新
- [x] `bootstrap.ps1` 引导层：5.1 可解析（无三元/??/&&；UTF-8 BOM 防中文乱码）；探测顺序 PATH → ProgramFiles → LOCALAPPDATA；`-ValidateOnly` 无副作用护栏（缺 pwsh 时拒绝自动安装、只给指引）；PATH 注入使 main 及其提权/校验子进程可解析 pwsh；winget 缺失/安装失败/装后仍找不到三个失败出口均有指引
- [x] validate.ps1 静态检查覆盖 `bootstrap-main.ps1`
- [x] README 快速开始：前置只剩 Git；命令改 `powershell -ExecutionPolicy Bypass -File bootstrap.ps1`（三 shell 通用）；阶段说明补「先确保 PS7 就位」
- [x] 主机实测：5.1 入口端到端 `-ValidateOnly`（引导横幅 → 转发 → 六阶段 → EXIT=0，中文无乱码）；PS7 直入 EXIT=0；validate.ps1 两个入口脚本均纳入且全绿

## Comments

- 2026-10-21（主机会话）：主机已装 PS7（探测命中 Program Files 路径），「5.1 + 无 pwsh → winget 自装」分支未真机覆盖——分支逻辑与失败出口已逐行核对，真裸机验证留待下次干净 VM 验收（同工单 10 先例）。wdc sync 走 `pwsh -File bootstrap.ps1` 经引导层多一跳子进程（约 0.5s），行为实测不变。
