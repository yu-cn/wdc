# 01: Tracer 骨架——bootstrap 能跑

**What to build:** 环境主人在本机 clone 仓库后运行一条 bootstrap 命令，能看到分阶段执行报告（做了什么/跳过什么/失败在哪），机器按第一份最小声明（cli-tools 雏形：Starship + fzf）收敛；再次运行零变更（幂等）。同时提供无副作用校验入口：逐份 winget configuration validate + PowerShell 脚本静态检查，秒级出结果。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] bootstrap 单入口命令可在本机执行并输出分阶段报告
- [ ] 第一份按域拆分的配置（cli-tools 雏形）声明 Starship 与 fzf 并成功应用
- [ ] 重跑 bootstrap 零变更（幂等收敛）
- [ ] 校验入口对全部配置与脚本通过（validate + 静态检查）
- [ ] 仓库结构就位：配置域目录、dotfiles 目录、脚本目录、bootstrap 入口

## Comments

- 2026-10-19（自主执行会话）：已完成并通过验收标准，实现落在对应 commit（git log 按工单号检索）。
