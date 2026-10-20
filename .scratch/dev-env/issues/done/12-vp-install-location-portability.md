# 12: vp 安装位置可移植性——脚本钉死主开发机 LOCALAPPDATA 布局

**What to build:** vp 探测/卸载相关脚本钉死主开发机布局，换机即挂。涉及：① `install-languages.ps1` 与 `verify-machine.ps1`（Windows 侧）只认 `%LOCALAPPDATA%\vite-plus\bin\vp.exe`；② `install-wsl-env.ps1` 探测行与 `verify-machine.ps1` WSL 探测只认 `~/.local/share/vite-plus/bin`，且 vp 探测用 `command -v`（非登录 shell 必然 MISSING，与自身注释矛盾）；③ `remove-leftovers.ps1` 卸载不处理同 ID 多版本并存（.NET SDK 双版本 → 0x8A150014 匹配歧义，提权也无效）。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] 事实固化：本机 Windows vp v1.3.0 在 `C:\Users\User\.vite-plus\bin`（官方默认布局）；WSL vp v1.3.0 在 `~/.vite-plus`，node shim 可用
- [x] 修复①②：Windows 侧与 WSL 侧探测均改为双布局候选（默认布局在前）
- [x] 修复③：`Remove-WingetPackage` 改为枚举已装版本、逐版本 `--version` 显式卸载
- [x] 修复后通过 validate.ps1，实测 WSL 探测输出 go/uv/vp/node/shell 全绿

## Comments

- 2026-10-19（第二台机会话）：真机验收（工单 10）中发现。安装器 ps1 静态阅读结论：头部声明 `VP_HOME` 未设时「复用现有 %USERPROFILE%\.vite-plus 安装」；LOCALAPPDATA 属「Windows Local and Roaming folders select the roots」的选根模式——主开发机的布局来自该模式（历史安装方式所致）。附带影响：主开发机若重装/换机，同样可能落在 `.vite-plus` 布局。是否顺势统一两机布局（主开发机迁移到官方默认）由主机会话定夺，本工单只修可移植性。

- 2026-10-19（第二台机会话）：范围扩大——WSL 探测同病（本机 WSL `~/.vite-plus` 布局，探测行钉 `~/.local/share/vite-plus` 且 `command -v` 在非登录 shell 恒空）；`Remove-WingetPackage` 多版本歧义也归并本工单（同属「主开发机形态固化」）。

- 2026-10-20（第二台机会话）：同族补刀两处，见本批 commit：verify-machine WSL 探测默认用户由硬编码 `ubuntu` 改为自动探测；dotfiles/wsl/bashrc 内置可移植 vp PATH 引导（双布局，防 `vp env on` 写穿追加）。
