# 14: dotfiles 符号链接的写穿污染 + 行尾（eol）防护缺失

**What to build:** 两个相交的问题：① WSL 内工具（实测：`gh auth login`）向 `~/.gitconfig` 写配置时，会**写穿符号链接直接改写仓库模板文件**（本机实测：credential helper 块于 23:13:22 进入 `dotfiles/wsl/gitconfig` 并被 commit+push）。「仓库是唯一主人」的防线对写穿无感知。② 仓库无 `.gitattributes`，Windows 侧 `core.autocrlf=true` 下任何 checkout/restore 都可能把 dotfiles 落成 CRLF——WSL git 经 `/mnt/d` 读到 `path = ~/.gitidentity\r`，include 静默失效（本机实测：`git restore` 后 WSL 身份解析即刻断裂）。

**Blocked by:** None (can start immediately)

**Status:** needs-triage

- [x] 应急处置（第二台机）：credential 块迁入 WSL `~/.gitidentity`（模板 include 的机器本地文件，ADR-0003 身份数据模式），仓库模板还原 pristine，WSL 侧认证/身份实测不受影响
- [x] 防护：新增 `.gitattributes`（`dotfiles/** text eol=lf`），dotfiles 永久钉 LF
- [ ] 定夺（主机会话）：写穿防护的长期方案——例如 bootstrap/verify 增加「dotfiles 与 HEAD 的一致性断言」（漂移即 FAIL），或文档化「WSL 内先关链接再跑会写配置的工具」

## Comments

- 2026-10-19（第二台机会话）：事故时间线：23:12 dotfiles 链接建立 → 23:13 WSL 内 `gh auth login` 写穿 → 23:18 被 `git add -A` 意外带入 commit `6d18bf9` 推上 main。`git add -A` 的教训：符号链接在位后，提交前必须 `git status` 核对 dotfiles 无漂移。

- 2026-10-19（第二台机会话）：排障中踩到的文档内行为，记录备用：**`git config --global/--file/--local` 等带作用域查询按设计不展开 include**（`--includes` 才开），只有全栈查询默认展开。用 `--global` 探测「include 是否生效」会得出假阴性。本仓库 `verify-machine.ps1` 的 WSL `id:` 探测用的是全栈查询，行为正确。
