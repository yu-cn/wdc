# 30: 裸机 WSL 启用路径在 bootstrap 内不可达（README「重启续跑」承诺与实现脱节）

**What to decide:** 工单 29 实现期间的事实发现（2026-10-22，代码判读）：**全新机器上 bootstrap 无法启用 WSL，也无法安装 Ubuntu**。链条：

- `bootstrap-main.ps1` Stage 6 提权守卫无条件跳过 WSL 阶段（坑①：wsl.exe 提权+管道捕获挂死）——**任何提权上下文都不跑 install-wsl.ps1**；
- `install-wsl.ps1` 仅有的两个安装分支（`--install --no-distribution` 启用功能、`--install -d Ubuntu` 装发行版）都以 `if ($elevated)` 为前提——而能跑到它的唯一上下文（非提权父回合）恰好不满足；
- 即：两个安装分支在 bootstrap 流程内是**不可达代码**，非提权时只剩 SKIP 提示「提权运行 bootstrap 并重启后续跑」——但用户照做（管理员终端跑 bootstrap）后 Stage 6 照样跳过，提示构成死循环。

旁证：fresh-machine 冒烟（工单 26）runner 为管理员上下文，WSL 阶段整段 SKIP（工作流注释自认）；工单 16 的复选项「任一新机器实测单命令流程（含 WSL 未启用时的重启续跑路径）」至今未勾。README「首次运行你需要配合的五件事」第 3 条「启用 WSL 功能后需重启」读起来像 bootstrap 会启用——实际不会。待主人定夺方向：

- a) **提权子回合内启用 WSL 但绕开挂死坑**：`wsl --install --no-distribution` 用 `Start-Process` 直写控制台（不经 PS 管道捕获）——风险：坑①未在新姿势下实证，可能复刻楔死；需真机试错
- b) **承认启用是手工步骤**：README 五件事第 3 条改写为「管理员终端跑 `wsl --install` 并重启」（现役 wdc status 文案已按此写）；install-wsl.ps1 的不可达安装分支删除或改守卫——bootstrap 职责从「启用」收窄到「启用后就绪」
- c) **现代 WSL（Store 版）探测分流**：Win11 新机 WSL 多为预装 Store 版、用户级可装发行版——探测到时走用户级安装分支，老机器才要求提权

**Blocked by:** None

**Status:** needs-triage

- [ ] 环境主人定夺方向后拆实现工单

## Comments

- 2026-10-22（主机）：工单 29 的 wdc status「WSL」步已能让这个状态可见（未启用/Ubuntu 未装各给 FAIL + 手工处置文案），本工单只决「bootstrap 要不要接管启用」。
