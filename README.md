# WDC（Windows Developer Config）— 声明式 Windows 开发环境

> clone 之后一条命令，任何一台 Windows 机器收敛到声明状态：软件、系统设置、dotfiles、WSL Ubuntu——幂等、可重放、可迁移。

[![validate](https://github.com/yu-cn/wdc/actions/workflows/validate.yml/badge.svg)](https://github.com/yu-cn/wdc/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<p align="center">
  <a href="docs/demo.cast"><img src="docs/demo.gif" width="720" alt="wdc 终端速览：wdc 快照 / wdc verify（约 4 秒循环播放）"></a>
</p>
<p align="center"><sub>↑ 速览：<code>wdc</code> 只读快照 · <code>wdc verify</code> 机器断言（源文件 <a href="docs/demo.cast">docs/demo.cast</a>）</sub></p>

这是作者的日常开发环境，以仓库形式维护：配置只描述「一台机器应当处于什么状态」，由 bootstrap 负责把机器收敛到这个状态。基于 [microsoft/WindowsDeveloperConfig](https://github.com/microsoft/WindowsDeveloperConfig) 的经验自建（不 fork，见 [ADR-0001](docs/adr/0001-own-tree-not-fork-upstream.md)）。仓库以 [MIT](LICENSE) 开源，欢迎直接使用或 fork 改造成你自己的环境（见「[使用与改造](#使用与改造)」）。

## 快速开始（新机器）

零前置——Windows 10/11 自带的 winget 与 Windows PowerShell 足以启动，一条命令（cmd / PowerShell / Git Bash 均可粘贴）：

```powershell
powershell -c "iex ((irm https://raw.githubusercontent.com/yu-cn/wdc/main/scripts/get.ps1).Trim([char]0xFEFF))"
```

get.ps1 是唯一的远程引导脚本：缺 Git 自动 winget 安装（弹一次 UAC）→ 定位或 clone 仓库（`~/.wdc` 指针有效则复用，缺省 clone 到 `~\wdc`）→ 直接进入 bootstrap 全流程（缺 PowerShell 7 自动经 winget 用户级安装）。`Trim([char]0xFEFF)` 是剥掉 raw 返回的 UTF-8 BOM——Windows PowerShell 5.1 不剥它，BOM 前缀会把首行注释粘成命令导致解析/运行失败（collaboration.md 已知坑16）。该命令属于直接执行网络代码——介意可先[审阅 get.ps1](scripts/get.ps1)再粘贴。偏好手动管理的等价三行（Git 需自备，`winget install Git.Git` 或官网安装包）：

```powershell
git clone https://github.com/yu-cn/wdc.git
cd wdc
powershell -ExecutionPolicy Bypass -File bootstrap.ps1
```

bootstrap 先确保 PowerShell 7 就位（裸机自动安装），再依次跑七个阶段（预检 → 无副作用校验 → 应用声明配置 → 用户级安装 → 移除清单 → WSL 侧 → dotfiles），全程输出分阶段报告。**一条命令一键收敛**：未提权启动会弹一次 UAC，提权子回合一回合跑完全部七阶段（含 WSL），无需手动二次运行。

> **直接在自己机器上跑之前先知道**：bootstrap 是作者的日常环境收敛——会应用注册表系统设置（含关远程桌面等 opinion），并执行一份显式移除清单（[ADR-0007](docs/adr/0007-removal-list-converge-only.md)：卸载商店版 VSCode 换 winget 版、清理退役终端片段；**不卸载任何语言栈与已装软件**）。想用自己的偏好，建议先 fork 按下文「使用与改造」裁剪再跑。

<details>
<summary><strong>首次运行你需要配合的五件事</strong>（UAC 提权 · SmartScreen 放行 · 重启续跑 · 填写身份 · 关 VSCode 设置同步）</summary>

1. **UAC 提权**——未提权启动会自动请求，点一次确认
2. **SmartScreen 放行**——vp 安装器未代码签名，全新机器首次可能弹窗，选「仍要运行」
3. **重启**——全新机器 bootstrap 会在提权回合内自动启用 WSL 并提示重启；重启登录后由一次性续跑任务**自动重跑** bootstrap 安装 Ubuntu 并收尾（GLOSSARY「续跑任务」：任意一次 bootstrap 启动即清除、绝不循环；自动登记未成时手工路径：重启后重跑 `bootstrap.ps1`，或管理员终端 `wsl --install`，流程相同）
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

**WSL 侧**（Ubuntu，发行版内一切委托姊妹仓库 [LDC](https://github.com/yu-cn/ldc)——[setup-ubuntu.sh](scripts/wsl/setup-ubuntu.sh) 薄包装，LDC-0007）
LDC 接管 apt 包 / gh / Docker Engine / uv / vp / Starship / Linux dotfiles（单一实现）；WDC 保留 WSL 生命周期引导（wsl.conf systemd、默认 shell=bash）

**dotfiles**（[dotfiles/](dotfiles/)，渲染拷贝安装（ADR-0015），旧文件备份 `*.bak`）
gitconfig（delta / rerere / zdiff3）· starship.toml（pwsh / Git Bash / WSL bash 三 shell 统一提示符）· Windows Terminal · VS Code settings / keybindings · bashrc（Windows 侧；Linux bashrc 归姊妹仓库 LDC，工单32 起委托接管）

</details>

## 使用与改造

- **直接用**：照上文「快速开始」clone 本仓库跑 bootstrap。仓库不含作者的身份与机器派生值——`~/.gitidentity` 填你自己的 git name/email，WSL 终端配置按你本机发行版渲染（[ADR-0004](docs/adr/0004-machine-adaptive-rendering.md)）——之后 `wdc sync` 一键跟进上游演进。
- **fork 改造（推荐）**：fork 成你自己的仓库再 bootstrap，偏好由你定。改造清单：
  1. `configs/*.winget` 与 `configs/vscode-extensions.txt`——软件与扩展清单，删你不用的
  2. `dotfiles/`——shell / git / 终端 / 编辑器偏好
  3. `LICENSE`——版权人换成你自己
  4. `.scratch/`——作者的内部工单流，可删可留（留作方法参考）
  5. `scripts/remove-leftovers.ps1`——移除清单（[ADR-0007](docs/adr/0007-removal-list-converge-only.md)：本仓自清理 + 迁移冲突，不卸语言栈），按你自己的迁移需求增删

  脚本里没有写死的仓库地址，fork 后无需改动即可 bootstrap；日后跟随上游演进的 recipe 见 [docs/forking.md](docs/forking.md)。例外：[scripts/get.ps1](scripts/get.ps1) 是面向上游的远程一键引导、写死上游地址——fork 用户走手动 clone 三行，或把它改成你的仓库地址再发布。

## 常用命令

| 命令 | 用途 |
|---|---|
| `wdc` | 只读快照（裸命令默认，秒级）：远端差距 / dotfiles 漂移 / 身份与 WSL / 最近 bootstrap |
| `wdc sync` | 日常一键同步（fetch → pull → bootstrap → verify -Quick 收尾；会请求一次 UAC） |
| `wdc verify [-Full]` / `wdc triage` / `wdc log` / `wdc help` | 机器断言（默认 -Quick）/ dotfiles 落点漂移分流 / 最近日志尾部 / 帮助与版本 |
| `pwsh bootstrap.ps1` | 完整收敛（日常改了配置后重跑） |
| `pwsh bootstrap.ps1 -ValidateOnly` | 只做无副作用校验（配置 schema + 脚本静态检查） |
| `pwsh validate.ps1` | 同上的校验入口，独立可用 |
| `winget configure test --file configs/<域>.winget` | 单域漂移检查（不动机器） |
| `pwsh scripts/check-upstream.ps1` | 上游 [WindowsDeveloperConfig](https://github.com/microsoft/WindowsDeveloperConfig) 差异报告（吸收与否人工定夺） |
| `pwsh scripts/install-dotfiles.ps1` | 只重装 dotfiles 渲染拷贝 |

## 各层职责（ADR-0002）

```
configs/    声明式层：按域拆分的 winget configuration（base-windows / cli-tools / editors + 扩展清单）
scripts/    编排层：bootstrap 入口、语言版本（vp）、VSCode 扩展、移除清单、WSL 委托包装、上游检查
dotfiles/   dotfiles 层：windows / shared（wsl 已冻结，Linux 模板归姊妹仓库 LDC），渲染拷贝安装（旧文件备份 *.bak）
```

- git 身份不入仓库：模板 include 每机本地的 `~/.gitidentity`
- Node 全权归 **vp**（钉 1.3.0，默认跟随 LTS），Python 全权归 **uv**，两侧同工具同习惯
- 提示符三 shell（pwsh / Git Bash / WSL bash）统一 **Starship**，一份 `starship.toml`
- 移除清单只做两类事（[ADR-0007](docs/adr/0007-removal-list-converge-only.md)）：本仓自清理（退役 WT fragments）与迁移冲突（VSCode 商店版→winget 版），**清单外不碰**——JetBrains 套件、Typora、GitHub Desktop 等机器自留地安全，语言栈与已装软件一律不卸

## Docker（WSL 侧默认装）

Docker Engine 由 WSL 阶段委托 LDC 从官方源安装（免 sudo 需重新登录 WSL 一次生效）。守护进程依赖 systemd 自启——bootstrap 会确保 `/etc/wsl.conf` 的 `[boot] systemd=true`，若为本次新写入需 `wsl --shutdown` 后下次进入生效。Windows 侧的 Docker Desktop 不在声明内（机器自留地）。

## 新开发机接入（机器对等，任意台可重复）

1. **协作者授权**：仓库 owner 在 GitHub → Settings → Collaborators 添加该机的 GitHub 账号（或 `gh api repos/<owner>/wdc/collaborators/<用户名> -X PUT`）
2. **该机上**：`gh auth login` → 按上文「快速开始」走 bootstrap（五步）→ **验收**：`pwsh scripts/verify-machine.ps1`（全绿即与声明一致）
3. **反向吸收**：该机上跑 `pwsh scripts/inventory-machine.ps1 > .scratch/inventory-<机器名>-<日期>.md`，commit + push 回仓库——环境主人按 ADR-0003 通用核心判据逐项定夺是否吸收进 configs/dotfiles，吸收后在 [docs/upstream-ledger.md](docs/upstream-ledger.md) 记一笔
4. 任何机器的改进直接 push `main`（pre-commit 钩子把关）；工单与决策经 `.scratch/` 在仓库内流转，**机器之间无主从**；个性需求走机器自留地，不进仓库

## 文档

- 词汇表：[GLOSSARY.md](GLOSSARY.md) · 决策：[docs/adr/](docs/adr/) · 上游调研：[docs/research/](docs/research/) · 吸收账本：[docs/upstream-ledger.md](docs/upstream-ledger.md) · 变更记录：[CHANGELOG.md](CHANGELOG.md)
- Fork 跟随：[docs/forking.md](docs/forking.md)（改造成自己环境后如何跟上游演进）
- 贡献指南：[CONTRIBUTING.md](CONTRIBUTING.md)（fork 自用为主，通用核心改进欢迎 PR）
- 工单与规格：`.scratch/`（作者的本地 markdown 工单流；外部贡献请走 GitHub Issues/PR）

## 许可证

[MIT](LICENSE) © [yu-cn](https://github.com/yu-cn)
