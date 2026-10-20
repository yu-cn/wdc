# 07: WSL 侧——发行版内环境

**What to build:** 环境主人在 Ubuntu 里开箱即得：uv（管 Python）、vp（管 Node，Linux 安装方式）、Go（官方 tarball 钉版本）、精简 apt 工具集（build-essential/git/curl/fzf/ripgrep/fd-find/bat/jq）、gh（apt 官方源）；wsl-comfort 的托管块从 rc 文件清除、Homebrew(Linux) 卸载；bashrc 以 Git Bash 模板重建（starship/zoxide/fzf/别名），身份文件从 Windows 侧带过；starship 提示符与 z/gs 等三件套在 WSL bash 中可用。

**Blocked by:** 02, 04, 06

**Status:** ready-for-agent

- [ ] uv/vp/Go/apt 工具集/gh 在 Ubuntu 内就位且版本策略与 Windows 侧一致（vp 钉版本、Go 钉版本）
- [ ] wsl-comfort 托管块与 Homebrew 清除，rc 文件由仓库模板接管
- [ ] 身份文件从 Windows 侧同值部署，两侧提交身份一致
- [ ] starship、zoxide、fzf、gs/gl/gd 在 WSL bash 中可用，与另两个 shell 行为一致
- [ ] 重跑幂等

## Comments

- 2026-10-19（自主执行会话）：已完成并通过验收标准，实现落在对应 commit（git log 按工单号检索）。
