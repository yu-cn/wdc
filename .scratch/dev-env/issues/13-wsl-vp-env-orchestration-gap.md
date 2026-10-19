# 13: setup-ubuntu.sh 的 vp 环境编排缺口（非登录 shell 误判 + 缺 env 三步）

**What to build:** `scripts/wsl/setup-ubuntu.sh` user 阶段两个问题：① `have vp`（`command -v`）在 `bash <script>` 的非登录非交互上下文里必然探测不到已装的 vp（PATH 未含 `~/.vite-plus/bin`），导致每次 bootstrap 都重跑官方安装器（幂等无害，但多余且产生下载/时间开销）；② 只装 vp 本体，没有 `vp env default lts` / `vp env install lts` / `vp env on` 三步（Windows 侧 `install-languages.ps1` 有）——干净机器 WSL 侧将没有 Node，`verify-machine.ps1` 的「WSL node(vp)」断言必挂。本机（第二台机）是靠 9 月的旧 vp 存货侥幸通过的。

**Blocked by:** None (can start immediately)

**Status:** needs-triage

- [ ] 定夺：WSL 侧是否补 `vp env` 三步（与 Windows 侧对齐）——涉及「干净新机一次过」承诺（工单 10 的原始目标）
- [ ] `have vp` 探测改为显式路径双布局（`~/.vite-plus/bin/vp` 或 `~/.local/share/vite-plus/bin/vp`），或显式 source PATH 片段

## Comments

- 2026-10-19（第二台机会话）：真机验收（工单 10）中发现。主开发机 WSL 侧全绿很可能同样依赖历史手工状态而非脚本编排——建议主机会话在干净 WSL 发行版上复验一次「仅靠仓库脚本」的路径。与 [[12-vp-install-location-portability]] 同族但根因不同（探测上下文 + 编排缺失），单独开票。
