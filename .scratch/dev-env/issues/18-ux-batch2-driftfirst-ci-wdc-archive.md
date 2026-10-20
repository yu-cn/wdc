# 18: 体验批次2——漂移先行跳过无谓应用、CI 源头防线、wdc 一词同步、工单归档

**What to build:** 环境主人批准的四项（2026-10-20，巡检定时化明确不做）：① bootstrap Stage 2 先 `winget configure test` 再决定应用，漂移=0 跳过 apply（日常幂等重跑省 ~3 分钟）；② GitHub Actions 在 push/PR 上跑 `validate.ps1`（源头防线：钩子被绕过时兜底，防坏 commit 进 main 波及全部机器）；③ `wdc` 一键同步命令（pull → bootstrap → verify）进 pwsh/bash 双侧 profile，仓库路径由 bootstrap 自动写入机器本地 `~/.wdc`（ADR-0004 模式）；④ 工单完结归档约定（`issues/done/`）+ 01–09 归档。

**Blocked by:** None (can start immediately)

**Status:** ready-for-human

- [x] ① Stage 2 test-first —— **已实现、实测、回退**：`configure test` 三域 153.8s ≈ 直接 apply 耗时（瓶颈是 winget 每次调用固定开销，非 apply 单元执行），漂移>0 时反而多付一次。保留每阶段计时（本结论正由它测出）。代码中留注释防止重蹈。
- [x] ② `.github/workflows/validate.yml`（windows-latest，只读校验）
- [x] ③ wdc 函数（pwsh + Git Bash 两侧）+ install-dotfiles 写 `~/.wdc`；端到端实测通过（pull → 单命令 bootstrap → verify 一条龙）
- [x] ④ issue-tracker.md 增归档约定；01–09 移入 `done/`（工作早已交付，Status 行保留历史原样）
- [x] 附带结论：PSScriptAnalyzer 无 winget 包（已查证），validate.ps1 的用户范围自装保持为机制，不硬造声明

## Comments

- 2026-10-20（ASUS 会话）：定时巡检（只读 verify 周期任务）环境主人明确暂不做，未实现。
