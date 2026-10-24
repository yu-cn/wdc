# 36: 移除清单收敛为自清理+迁移冲突（ADR-0007）

**What to build:** 环境主人定夺（2026-10-25）：仓库已 MIT 开源、README 邀请陌生人直接 bootstrap，而移除清单里的主人机史项（Oh My Posh、直装 Node/Python 3.13、nvm-windows、.NET SDK 10/ASP.NET 运行时、WSL Go）对公众机器是纯破坏、对两台主人机已收敛完毕只剩幂等空转（工单21 Comments 2026-10-22 实测）——全部退出。清单语义收敛为两类（ADR-0007）：本仓自清理（WT fragments：上游注入 + ADR-0006 退役残留）与迁移冲突（VSCode 商店 MSIX）。不做开关机制：瘦身后已无破坏面可保护，开关是纯复杂度（拒绝记录见 ADR）。README 快速开始加破坏性披露、fork 改造清单加清单审查项；GLOSSARY 补「移除清单」词条（原脚本头引用的词条本不存在）。

**Blocked by:** None

**Status:** ready-for-agent

- [x] ADR-0007 先落（决策先于代码）；WDC 侧既有裸引用「ADR-0007」就地加 LDC 限定词（与 LDC 侧统筹 ADR 同号不同物）
- [x] remove-leftovers.ps1：删阶段 3/4/5 与提权 pending 机制，重编号 1/2，头注释改写语义
- [x] verify-machine.ps1：删 oh-my-posh/nvm 目录/.NET SDK 三条「已卸」断言；保留 VSCode 单版本与 Desktop 运行时保留（保护性）
- [x] setup-ubuntu.sh：删 Go 两行与头注释 Go 提及；install-wsl-env.ps1 两处同步
- [x] install-languages.ps1:53 注释改真话（system node 由 PATH 优先级裁决，清单不再卸语言栈）
- [x] bootstrap-main.ps1 Stage 5 注释/标签更新（「先装后拆」语义失效，改收敛执法）
- [x] README：快速开始披露 + fork 清单加第 5 项 + WSL 侧/各层职责措辞更新
- [x] GLOSSARY：补「移除清单」词条
- [ ] 两机复验：本机 remove-leftovers 幂等跑 + wdc verify -Quick 全绿；另一台机待 sync 后复验再归档

## Comments

- 2026-10-25（本机会话）：实施如上清单。本机验证：六份 PS 脚本 AST 语法全绿、三份 bash `bash -n` 全绿；remove-leftovers.ps1 幂等真跑——两阶段全 OK 行、零改动；verify -Quick——Windows 侧 1-4 组全绿（含改后移除清单核销组仅剩 VSCode 单版本 + Desktop 运行时保留）。顺手补一处存量漂移：core.hooksPath 未接线（与本单无关，按断言提示 `git config core.hooksPath .githooks` 接上，使本次提交过 pre-commit 硬关）。现存唯一 FAIL 为 WSL 内 LDC「docker daemon 声明键」漂移——存量问题、LDC 辖区，与本单无关，`wdc sync` 收敛。另一台机（ASUS）待 sync 后复验再归档。
