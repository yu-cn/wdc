# WDC（Windows Developer Config）— 声明式 Windows 开发环境

> clone 之后一条命令，任何一台 Windows 机器收敛到声明状态：软件、系统设置、dotfiles、WSL Ubuntu——幂等、可重放、可迁移。

[![validate](https://github.com/yu-cn/wdc/actions/workflows/validate.yml/badge.svg)](https://github.com/yu-cn/wdc/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

这是作者的日常开发环境，以仓库形式维护：配置只描述「一台机器应当处于什么状态」，由 bootstrap 负责把机器收敛到这个状态。基于 microsoft/WindowsDeveloperConfig 的经验自建（不 fork，见 [ADR-0001](docs/adr/0001-own-tree-not-fork-upstream.md)）。仓库以 [MIT](LICENSE) 开源，欢迎直接使用或 fork 改造成你自己的环境（见「[使用与改造](#使用与改造)」）。

## 快速开始（新机器）

前置：装好 Git（`winget install Git.Git` 或官网安装包）。其余无需准备——Windows 10/11 自带的 Windows PowerShell 5.1 与 winget 足以启动，缺 PowerShell 7 时 bootstrap 会自动经 winget 用户级安装（无需管理员）。然后（cmd / PowerShell / Git Bash 均可粘贴）：

```powershell
git clone https://github.com/yu-cn/wdc.git
cd wdc
powershell -ExecutionPolicy Bypass -File bootstrap.ps1
```

bootstrap 先确保 PowerShell 7 就位（裸机自动安装），再依次跑七个阶段（预检 → 无副作用校验 → 应用声明配置 → 用户级安装 → 移除清单 → WSL 侧 → dotfiles），全程输出分阶段报告。**一条命令一键收敛**：未提权启动会弹一次 UAC，提权子回合一回合跑完全部七阶段（含 WSL），无需手动二次运行。

<details>
<summary><strong>首次运行你需要配合的五件事</strong>（UAC 提权 · SmartScreen 放行 · 重启续跑 · 填写身份 · 关 VSCode 设置同步）</summary>

1. **UAC 提权**——未提权启动会自动请求，点一次确认
2. **SmartScreen 放行**——vp 安装器未代码签名，全新机器首次可能弹窗，选「仍要运行」
3. **重启续跑**——全新机器 bootstrap 会在提权回合内自动启用 WSL 并提示重启；重启后重跑 `bootstrap.ps1` 安装 Ubuntu 并收尾（自动启用未成时手工路径：管理员终端 `wsl --install`，流程相同）
4. **填写身份**——bootstrap 生成 `~/.gitidentity` 占位后，填上**本机**的 git name/email（各机身份不同；不填则 git 拒绝提交，这是防错护栏）
5. **关闭 VSCode 设置同步**——首次启动 VSCode 若已登录账号（齿轮/账户图标 → 设置同步 → 关闭）。设置同步是账号级开关、配置文件管不到它；不关的话云端会与仓库 dotfiles 打架（仓库是唯一主人）

</details>

重跑 bootstrap 幂等：已就位的全部跳过，只有漂移会被收敛。收敛完成后验收：`pwsh scripts/verify-machine.ps1`（全绿即与声明一致）。`-NoElevate` 保留为非提权单回合入口（排障逃生通道：apply 与 WSL 启用受限跳过）。

<details>
<summary><strong>一条命令得到什么</strong>（点开看完整清单）</summary>

**系统**（[base-windows 域](configs/base-windows.winget)，27 项注册表 opinion）
开发者模式 · 启用 Sudo · 长路径 · 深色主题 · 显示扩展名/隐藏文件 · 资源管理器与任务栏去噪 · 开始菜单关 Web 搜索与推荐 · 关 Recall / Click To Do / 小组件 · Edge 新标签空白 · 关远程桌面

**CLI**（[cli-tools 域](configs/cli-tools.winget)，17 个 winget 包）
Git · GitHub CLI · Chrome · Everything · PowerToys · lazygit · delta · fzf / fd / ripgrep / zoxide / bat / jq · make · JetBrainsMono NF 字体（PowerShell 7 由入口引导层负责安装与升级）

**编辑器**（[editors 域](configs/editors.winget)）
VS Code + 32 个扩展（Python / Jupyter 全家、Remote-WSL / SSH / Containers、Prettier / Vitest / oxc、中文语言包等，[完整清单](configs/vscode-extensions.txt)）

**语言运行时**
Node 归 **vp**（默认跟随 LTS）、Python 归 **uv**——Windows / WSL 两侧同工具同习惯

**WSL 侧**（Ubuntu，发行版内一切委托姊妹仓库 [LDC](https://github.com/yu-cn/ldc)——[setup-ubuntu.sh](scripts/wsl/setup-ubuntu.sh) 薄包装，ADR-0007）
LDC 接管 apt 包 / gh / Docker Engine / uv / vp / Starship / Linux dotfiles（单一实现）；WDC 保留 WSL 生命周期引导（wsl.conf systemd、默认 shell=bash）与移除清单（Go）

**dotfiles**（[dotfiles/](dotfiles/)，符号链接安装，旧文件备份 `*.bak`）
gitconfig（delta / rerere / zdiff3）· starship.toml（pwsh / Git Bash / WSL bash 三 shell 统一提示符）· Windows Terminal · VS Code settings / keybindings · bashrc（Windows 侧；Linux bashrc 归姊妹仓库 LDC，工单32 起委托接管）

</details>

## 使用与改造

- **直接用**：照上文「快速开始」clone 本仓库跑 bootstrap。仓库不含作者的身份与机器派生值——`~/.gitidentity` 填你自己的 git name/email，WSL 终端配置按你本机发行版渲染（[ADR-0004](docs/adr/0004-machine-adaptive-rendering.md)）——之后 `wdc sync` 一键跟进上游演进。
- **fork 改造（推荐）**：fork 成你自己的仓库再 bootstrap，偏好由你定。改造清单：
  1. `configs/*.winget` 与 `configs/vscode-extensions.txt`——软件与扩展清单，删你不用的
  2. `dotfiles/`——shell / git / 终端 / 编辑器偏好
  3. `LICENSE`——版权人换成你自己
  4. `.scratch/`——作者的内部工单流，可删可留（留作方法参考）

  脚本里没有写死的仓库地址，fork 后无需改动即可 bootstrap；日后跟随上游演进的 recipe 见 [docs/forking.md](docs/forking.md)。

## 常用命令

| 命令 | 用途 |
|---|---|
| `wdc` | 只读快照（裸命令默认，秒级）：远端差距 / dotfiles 漂移 / 身份与 WSL / 最近 bootstrap |
| `wdc sync` | 日常一键同步（fetch → pull → bootstrap → verify 全量；会请求一次 UAC） |
| `wdc verify [-Full]` / `wdc triage` / `wdc log` / `wdc help` | 机器断言（默认 -Quick）/ dotfiles 写穿分流 / 最近日志尾部 / 帮助与版本 |
| `pwsh bootstrap.ps1` | 完整收敛（日常改了配置后重跑） |
| `pwsh bootstrap.ps1 -ValidateOnly` | 只做无副作用校验（配置 schema + 脚本静态检查） |
| `pwsh validate.ps1` | 同上的校验入口，独立可用 |
| `winget configure test --file configs/<域>.winget` | 单域漂移检查（不动机器） |
| `pwsh scripts/check-upstream.ps1` | 上游 WindowsDeveloperConfig 差异报告（吸收与否人工定夺） |
| `pwsh scripts/install-dotfiles.ps1` | 只重装 dotfiles 链接 |

## 各层职责（ADR-0002）

```
configs/    声明式层：按域拆分的 winget configuration（base-windows / cli-tools / editors + 扩展清单）
scripts/    编排层：bootstrap 入口、语言版本（vp）、VSCode 扩展、移除清单、WSL 委托包装、上游检查
dotfiles/   dotfiles 层：windows / shared（wsl 已冻结，Linux 模板归姊妹仓库 LDC），符号链接安装（旧文件备份 *.bak）
```

- git 身份不入仓库：模板 include 每机本地的 `~/.gitidentity`
- Node 全权归 **vp**（钉 1.3.0，默认跟随 LTS），Python 全权归 **uv**，两侧同工具同习惯
- 提示符三 shell（pwsh / Git Bash / WSL bash）统一 **Starship**，一份 `starship.toml`
- 移除清单显式执行，**清单外不碰**：JetBrains 套件、Typora、GitHub Desktop 等机器自留地安全

## Docker（WSL 侧默认装）

Docker Engine 由 WSL 阶段委托 LDC 从官方源安装（免 sudo 需重新登录 WSL 一次生效）。守护进程依赖 systemd 自启——bootstrap 会确保 `/etc/wsl.conf` 的 `[boot] systemd=true`，若为本次新写入需 `wsl --shutdown` 后下次进入生效。Windows 侧的 Docker Desktop 不在声明内（机器自留地）。

## 新开发机接入（机器对等，任意台可重复）

1. **协作者授权**：仓库 owner 在 GitHub → Settings → Collaborators 添加该机的 GitHub 账号（或 `gh api repos/<owner>/wdc/collaborators/<用户名> -X PUT`）
2. **该机上**：`gh auth login` → 按上文「快速开始」走 bootstrap（五步）→ **验收**：`pwsh scripts/verify-machine.ps1`（全绿即与声明一致）
3. **反向吸收**：该机上跑 `pwsh scripts/inventory-machine.ps1 > .scratch/inventory-<机器名>-<日期>.md`，commit + push 回仓库——环境主人按 ADR-0003 通用核心判据逐项定夺是否吸收进 configs/dotfiles，吸收后在 [docs/upstream-ledger.md](docs/upstream-ledger.md) 记一笔
4. 任何机器的改进直接 push `main`（pre-commit 钩子把关）；工单与决策经 `.scratch/` 在仓库内流转，**机器之间无主从**；个性需求走机器自留地，不进仓库

## 文档

- 词汇表：[GLOSSARY.md](GLOSSARY.md) · 决策：[docs/adr/](docs/adr/) · 上游调研：[docs/research/](docs/research/) · 吸收账本：[docs/upstream-ledger.md](docs/upstream-ledger.md)
- Fork 跟随：[docs/forking.md](docs/forking.md)（改造成自己环境后如何跟上游演进）
- 贡献指南：[CONTRIBUTING.md](CONTRIBUTING.md)（fork 自用为主，通用核心改进欢迎 PR）
- 工单与规格：`.scratch/`（作者的本地 markdown 工单流；外部贡献请走 GitHub Issues/PR）

## 许可证

[MIT](LICENSE) © [yu-cn](https://github.com/yu-cn)
