# 20: wdc CLI 使用体验优化——子命令化 + 单一实现

**What to build:** 现状：`wdc` 是 pwsh profile 与 Git Bash bashrc 里各一份的内联函数（约 13 行同构 bash/pwsh，已现漂移风险），只有一个固定动作 pull→bootstrap→verify：没有帮助可发现、不能只跑局部（verify/triage/看日志都要手敲长命令）、bootstrap 失败只说「日志在 logs/」不给出内容、无耗时汇总。环境主人指示（2026-10-20）：优化使用体验。方案：逻辑收敛为仓库内单一 `scripts/wdc.ps1`，两侧 shell 只留薄包装转发；子命令化——`sync`（默认，原全量动作）/ `status`（只读快照：远端差距、dotfiles 漂移、最近 bootstrap 结果）/ `verify [-Full]`（默认 -Quick）/ `triage`（工单 17 工具入口）/ `log [-Lines N]`（失败排查）/ `help`。sync 增强：fetch 后领先/落后报告、本地领先即中止（防意外 pull 合并）、UAC 预告、bootstrap 失败自动 tail 最近日志 30 行、总耗时。WSL 侧维持无 wdc（bootstrap+UAC 属 Windows 会话，跨 interop 徒增失败面）。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `scripts/wdc.ps1` 单一实现（六子命令，复用 lib/common.ps1 的报告风格）
- [ ] pwsh profile 与 Git Bash bashrc 改薄包装（~/.wdc 解析 + 转发，错误提示保留）
- [ ] 主机实测：help / status / verify / log / triage 入口，sync 全链路端到端（含 UAC）
- [ ] README「常用命令」表补 wdc 子命令
- [ ] ASUS 复验：拉取后新 shell 直接用新 wdc

## Comments

- 2026-10-20（主机会话）：开工即实现。设计取舍：不做 `update`/`doctor` 等花哨命名（sync/status/verify/triage/log 与仓库现有动词一一对应）；verify 独立子命令默认 -Quick（秒级日常），sync 尾部的 verify 维持全量（同步即验收）。
