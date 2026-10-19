# 13: setup-ubuntu.sh 的 vp 环境编排缺口（非登录 shell 误判 + 缺 env 三步）

**What to build:** `scripts/wsl/setup-ubuntu.sh` user 阶段两个问题：① `have vp`（`command -v`）在 `bash <script>` 的非登录非交互上下文里必然探测不到已装的 vp（PATH 未含 `~/.vite-plus/bin`），导致每次 bootstrap 都重跑官方安装器（幂等无害，但多余且产生下载/时间开销）；② 只装 vp 本体，没有 `vp env default lts` / `vp env install lts` / `vp env on` 三步（Windows 侧 `install-languages.ps1` 有）——干净机器 WSL 侧将没有 Node，`verify-machine.ps1` 的「WSL node(vp)」断言必挂。本机（第二台机）是靠 9 月的旧 vp 存货侥幸通过的。

**Blocked by:** None (can start immediately)

**Status:** ready-for-human

- [x] 定夺：WSL 侧补 `vp env` 三步（环境主人 2026-10-20 批准「工单13 补齐」建议）
- [x] `have vp`/`have uv` 探测改为显式路径（双布局 vp、`~/.local/bin/uv`），`vp env default/install/on` 三步入列

## Comments

- 2026-10-19（第二台机会话）：真机验收（工单 10）中发现。主开发机 WSL 侧全绿很可能同样依赖历史手工状态而非脚本编排——建议主机会话在干净 WSL 发行版上复验一次「仅靠仓库脚本」的路径。与 [[12-vp-install-location-portability]] 同族但根因不同（探测上下文 + 编排缺失），单独开票。

- 2026-10-20（第二台机会话）：已实施并真机复验（setup-ubuntu.sh，ASUS/Ubuntu）：显式路径探测命中免重装、三步执行 Node 24.22.0 进 vp 商店、幂等。顺带修掉 uv 每轮重下（同盲区）。副作用与解法：`vp env on` 会往 `~/.bashrc` 追加 PATH 引导并写穿符号链接——已在模板内置可移植等价行（双布局 + `$HOME`），实测 vp 去重检查认出后不再追加（与 [[14-dotfiles-write-through-and-eol]] 防线联动，写穿断言当场抓住过一次）。
