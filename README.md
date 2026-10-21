# WDC — 个人 Windows 开发环境（通用核心配置）

把「我的 Windows 开发环境」变成可重放、可迁移的声明式仓库：**任何一台开发机 clone 后跑一条命令，即得完整环境（Windows 侧 + WSL 侧）**。基于 microsoft/WindowsDeveloperConfig 的经验自建（不 fork，见 [ADR-0001](docs/adr/0001-own-tree-not-fork-upstream.md)）。

仓库以 [MIT](LICENSE) 开源：欢迎参考、直接使用或 fork 改造成你自己的环境（见「[使用与改造](#使用与改造)」）。

## 快速开始（新机器）

前置：装好 Git 与 PowerShell 7（`winget install Git.Git Microsoft.PowerShell`——bootstrap 以 pwsh 7 运行，裸 Windows 只有 5.1），然后：

```powershell
git clone https://github.com/yu-cn/WDC.git
cd WDC
pwsh bootstrap.ps1
```

bootstrap 会依次跑六个阶段（预检 → 无副作用校验 → 应用声明配置 → 用户级安装 → WSL 侧 → dotfiles），全程输出分阶段报告。**一条命令一键收敛**：未提权启动会弹一次 UAC，提权子回合跑完后自动补跑用户级/WSL 阶段，无需手动二次运行。**首次运行你需要配合的五件事**：

1. **UAC 提权**——未提权启动会自动请求，点一次确认
2. **SmartScreen 放行**——vp 安装器未代码签名，全新机器首次可能弹窗，选「仍要运行」
3. **重启续跑**——全新机器启用 WSL 功能后需重启一次，重启后重跑 `bootstrap.ps1` 继续
4. **填写身份**——bootstrap 生成 `~/.gitidentity` 占位后，填上**本机**的 git name/email（各机身份不同；不填则 git 拒绝提交，这是防错护栏）
5. **关闭 VSCode 设置同步**——首次启动 VSCode 若已登录账号（齿轮/账户图标 → 设置同步 → 关闭）。设置同步是账号级开关、配置文件管不到它；不关的话云端会与仓库 dotfiles 打架（仓库是唯一主人）

重跑 bootstrap 幂等：已就位的全部跳过，只有漂移会被收敛。`-NoElevate` 仍可用于只跑用户级/WSL 阶段（无需提权时）。

## 使用与改造

- **直接用**：照上文「快速开始」clone 本仓库跑 bootstrap。仓库不含作者的身份与机器派生值——`~/.gitidentity` 填你自己的 git name/email，WSL 终端配置按你本机发行版渲染（ADR-0004）——之后 `wdc sync` 一键跟进上游演进。
- **fork 改造（推荐）**：fork 成你自己的仓库再 bootstrap，偏好由你定。改造清单：
  1. `configs/*.winget` 与 `configs/vscode-extensions.txt`——软件与扩展清单，删你不用的
  2. `dotfiles/`——shell / git / 终端 / 编辑器偏好
  3. `LICENSE`——版权人换成你自己
  4. `.scratch/`——作者的内部工单流，可删可留（留作方法参考）

  脚本里没有写死的仓库地址，fork 后无需改动即可 bootstrap。

## 常用命令

| 命令 | 用途 |
|---|---|
| `wdc` | 日常一键同步（fetch → pull → bootstrap → verify 全量；子命令见 `wdc help`） |
| `wdc status` / `wdc verify` / `wdc triage` / `wdc log` | 只读快照 / 机器断言（默认 -Quick）/ dotfiles 写穿分流 / 最近 bootstrap 日志尾部 |
| `pwsh bootstrap.ps1` | 完整收敛（日常改了配置后重跑） |
| `pwsh bootstrap.ps1 -ValidateOnly` | 只做无副作用校验（配置 schema + 脚本静态检查） |
| `pwsh validate.ps1` | 同上的校验入口，独立可用 |
| `winget configure test --file configs/<域>.winget` | 单域漂移检查（不动机器） |
| `pwsh scripts/check-upstream.ps1` | 上游 WindowsDeveloperConfig 差异报告（吸收与否人工定夺） |
| `pwsh scripts/install-dotfiles.ps1` | 只重装 dotfiles 链接 |

## 各层职责（ADR-0002）

```
configs/    声明式层：按域拆分的 winget configuration（base-windows / cli-tools / editors + 扩展清单）
scripts/    编排层：bootstrap 入口、语言版本（vp）、VSCode 扩展、移除清单、WSL 两侧、上游检查
dotfiles/   dotfiles 层：windows / wsl / shared 三处，符号链接安装（旧文件备份 *.bak）
```

- git 身份不入仓库：模板 include 每机本地的 `~/.gitidentity`
- Node 全权归 **vp**（钉 1.3.0，默认跟随 LTS），Python 全权归 **uv**，两侧同工具同习惯
- 提示符三 shell（pwsh / Git Bash / WSL bash）统一 **Starship**，一份 `starship.toml`
- 移除清单显式执行，**清单外不碰**：JetBrains 套件、Typora、GitHub Desktop 等机器自留地安全

## Docker（默认不装，要用即装）

```powershell
# 在 WSL Ubuntu 内安装 Docker Engine（官方脚本），并把当前用户加入 docker 组
wsl -d Ubuntu -u root -e bash -c "curl -fsSL https://get.docker.com | sh && usermod -aG docker ubuntu"
# 之后 wsl 内重新登录即可免 sudo 用 docker
```

## 新开发机接入（机器对等，任意台可重复）

1. **协作者授权**：仓库 owner 在 GitHub → Settings → Collaborators 添加该机的 GitHub 账号（或 `gh api repos/<owner>/WDC/collaborators/<用户名> -X PUT`）
2. **该机上**：`gh auth login` → 按上文「快速开始」走 bootstrap（五步）→ **验收**：`pwsh scripts/verify-machine.ps1`（全绿即与声明一致）
3. **反向吸收**：该机上跑 `pwsh scripts/inventory-machine.ps1 > .scratch/inventory-<机器名>-<日期>.md`，commit + push 回仓库——环境主人按 ADR-0003 通用核心判据逐项定夺是否吸收进 configs/dotfiles，吸收后在 [docs/upstream-ledger.md](docs/upstream-ledger.md) 记一笔
4. 任何机器的改进直接 push `main`（pre-commit 钩子把关）；工单与决策经 `.scratch/` 在仓库内流转，**机器之间无主从**；个性需求走机器自留地，不进仓库

## 文档

- 词汇表：[GLOSSARY.md](GLOSSARY.md) · 决策：[docs/adr/](docs/adr/) · 上游调研：[docs/research/](docs/research/) · 吸收账本：[docs/upstream-ledger.md](docs/upstream-ledger.md)
- 贡献指南：[CONTRIBUTING.md](CONTRIBUTING.md)（fork 自用为主，通用核心改进欢迎 PR）
- 工单与规格：`.scratch/`（作者的本地 markdown 工单流；外部贡献请走 GitHub Issues/PR）

## 许可证

[MIT](LICENSE) © [yu-cn](https://github.com/yu-cn)
