# 06: WSL 侧——安装编排

**What to build:** 环境主人跑 bootstrap 的 WSL 阶段后：WSL 功能与 Ubuntu 发行版就位（沿用上游验证过的阶段化思路：启用组件→重启续跑→装发行版），全程不需要人工盯守重启；发行版默认 shell 为 bash（罢黜 zsh），wsl-comfort 的 zsh 设置不再生效。

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] WSL 组件与 Ubuntu 安装可由 bootstrap 编排完成（含重启后续跑）
- [ ] Ubuntu 默认 shell 为 bash
- [ ] 已装机器上执行本阶段幂等（不重复安装、不误删）
- [ ] 阶段报告如实输出（含需要重启时的指引）

## Comments

- 2026-10-19（自主执行会话）：已完成并通过验收标准，实现落在对应 commit（git log 按工单号检索）。
