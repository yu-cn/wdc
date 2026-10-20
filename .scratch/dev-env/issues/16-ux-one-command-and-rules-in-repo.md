# 16: 使用体验系统优化——单命令一键收敛 + 规则入仓

**What to build:** 两项环境主人指示（2026-10-20）：① 规则属于仓库而非单机 agent 记忆（其他机器读不到）——协作规矩与已知坑固化到 `docs/agents/collaboration.md`，AGENTS.md 挂索引；② 系统性优化使用体验。落地：bootstrap 单命令一键收敛（此前需手动跑两遍：提权 + `-NoElevate`）、汇总带每阶段耗时、日志轮转（保最近 20 份）、README 快速开始随之单命令化。

**Blocked by:** None (can start immediately)

**Status:** ready-for-human

- [x] 规则入仓：docs/agents/collaboration.md（协作规矩 + 九条真机实录坑）+ AGENTS.md 索引
- [x] bootstrap 单命令自动串联：未提权完整模式 → 一次 UAC → 提权子回合（新内部参数 -ElevatedPass，不再 -NoExit 悬窗）跑完提权阶段 → 父窗口 -Wait 等待后就地补跑 WSL/dotfiles → 合并汇总
- [x] 汇总输出每阶段耗时；logs/ 轮转保最近 20 份
- [x] README 快速开始：删除「提权跑完再 -NoElevate」的二次运行指引（该参数保留作低权限场景入口）
- [ ] 任一新机器实测单命令流程（含 WSL 未启用时的重启续跑路径）

## Comments

- 2026-10-20（ASUS 会话）：设计取舍——父回合跳过 Stage 1–4 重复（提权子回合已完成），只补 Stage 5/6，避免重复 30s 校验；子回合退出码并入汇总断言（子回合 FAIL 会体现在最终汇总）。wsl.exe 提权挂死的规避不变（WSL 阶段仍在普通权限上下文执行）。
