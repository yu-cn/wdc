# 21: Go 退出通用核心

**What to build:** 环境主人定夺（2026-10-21）：Go 不是常用语言，从 WDC 移除。按 ADR-0003 通用核心判据直接出局；日后个别机器要用走机器自留地自装。改动：setup-ubuntu.sh root 阶段改为移除 `/usr/local/go`（`~/go` 用户数据不碰）；bashrc 去 Go PATH 两段；starship.toml 去 golang 模块；install-wsl-env 探测与 verify 断言去 Go。inventory-machine 的 go 探测**保留**——盘点工具职责是发现机器现状（含自留地），非配置。

**Blocked by:** None

**Status:** ready-for-agent

- [x] setup-ubuntu.sh：移除 GO_VERSION 钉子与安装块，新增 `rm -rf /usr/local/go`（幂等，`|| true` 防 set -e）
- [x] dotfiles/wsl/bashrc：去 `/usr/local/go/bin` 与 `~/go/bin` 两段 PATH
- [x] starship.toml：format 去 `$golang`、删 `[golang]` 模块
- [x] install-wsl-env.ps1 探测 / verify-machine.ps1 断言：Go 项移除
- [x] README 装箱清单与语言运行时说明同步
- [ ] 两机复验：下次 `wdc sync` 后 `/usr/local/go` 消失、verify 全绿（Go 断言已除）

## Comments

- 2026-10-21（主机会话）：主机事实自查——go1.27.2 在位（将随下次 sync 收敛移除）；上游吸收账本无 Go 条目，无需回账。
