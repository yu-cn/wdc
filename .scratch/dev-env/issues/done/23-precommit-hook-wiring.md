# 23: pre-commit 钩子接线自动化 + verify 断言

**What to build:** 优化方向研究（2026-10-21 会话）P1-①。事实：collaboration.md/README 均承诺「pre-commit 钩子把关」，`.githooks/pre-commit` 也在仓库，但接线（`git config core.hooksPath .githooks`）全靠手工且无任何脚本保证——主机实测 `core.hooksPath` 为空，文档承诺的安全网实际不存在（一直靠 CI 兜底）。修法：bootstrap Stage 6 幂等接线（repo-local，不动全局）；verify-machine 加断言。

**Blocked by:** None

**Status:** ready-for-agent

- [x] bootstrap-main.ps1 Stage 6：安装 dotfiles 后 `git -C <repo> config core.hooksPath .githooks`（幂等）
- [x] verify-machine.ps1 1/6 加断言「pre-commit 钩子已接线」（FAIL 提示含自修命令）
- [x] 主机当场接线实测：本工单提交时 pre-commit 钩子真实拦截跑 validate
- [x] 两机复验：下次 sync 后 `wdc verify` 断言绿（ASUS 此前状态未知，接线前提交一直在裸奔）

## Comments

- 2026-10-21（主机会话）：CI workflow 注释早写了「pre-commit 钩子被绕过（WSL 侧提交/钩子未接线）时兜底」——当时就知晓接线不可靠，只是没自动化。本次补上源头。
- 2026-10-22（ASUS 本机会话）：ASUS 侧复验——今日 bootstrap dotfiles 阶段幂等接线（elevated-20261022-202710.log 实证「core.hooksPath → .githooks」）+ verify -Quick「pre-commit 钩子已接线」断言绿；本次归档提交亦经钩子把关。两机俱验，收口归档。
