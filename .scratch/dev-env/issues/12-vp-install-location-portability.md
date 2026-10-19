# 12: vp 安装位置可移植性——脚本钉死主开发机 LOCALAPPDATA 布局

**What to build:** `install-languages.ps1` 与 `verify-machine.ps1` 用绝对路径 `%LOCALAPPDATA%\vite-plus\bin\vp.exe` 探测 vp，这只对主开发机成立。官方安装器（vite.plus/ps1）的默认/复用布局是 `%USERPROFILE%\.vite-plus`（单体布局），本机（第二台机）即此布局且版本恰为钉子 1.3.0。钉死单一布局导致：本机 bootstrap Stage 3 触发安装器→安装器移交 vp 自助安装→非交互取消（`error: Installation cancelled; existing Vite+ commands were kept.`）→脚本探测路径仍不存在→FAIL；verify-machine 的 vp 断言同样会 FAIL。干净新机走官方默认布局时预计同样中招。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] 事实固化：本机 vp v1.3.0 在 `C:\Users\User\.vite-plus\bin`（官方默认布局），PATH 已含该目录；无系统 Node，node 由 vp shim 提供
- [x] 修复：两脚本探测候选路径列表（`~/.vite-plus/bin/vp.exe` 与 `$LOCALAPPDATA\vite-plus\bin\vp.exe`），命中即用
- [x] 修复后通过 validate.ps1，pre-commit 把关 commit

## Comments

- 2026-10-19（第二台机会话）：真机验收（工单 10）中发现。安装器 ps1 静态阅读结论：头部声明 `VP_HOME` 未设时「复用现有 %USERPROFILE%\.vite-plus 安装」；LOCALAPPDATA 属「Windows Local and Roaming folders select the roots」的选根模式——主开发机的布局来自该模式（历史安装方式所致）。附带影响：主开发机若重装/换机，同样可能落在 `.vite-plus` 布局。是否顺势统一两机布局（主开发机迁移到官方默认）由主机会话定夺，本工单只修可移植性。
