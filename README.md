# WDC — 个人 Windows 开发环境（通用核心配置）

把「我的 Windows 开发环境」变成可重放、可迁移的声明式仓库：**任何一台开发机 clone 后跑一条命令，即得完整环境（Windows 侧 + WSL 侧）**。基于 microsoft/WindowsDeveloperConfig 的经验自建（不 fork，见 [ADR-0001](docs/adr/0001-own-tree-not-fork-upstream.md)）。

## 快速开始（新机器）

前置：装好 Git（`winget install Git.Git`），然后：

```powershell
git clone https://github.com/yu-cn/WDC.git   # 私有仓库，需登录
cd WDC
pwsh bootstrap.ps1
```

bootstrap 会依次跑六个阶段（预检 → 无副作用校验 → 应用声明配置 → 用户级安装 → WSL 侧 → dotfiles），全程输出分阶段报告。**首次运行你需要配合的四件事**：

1. **UAC 提权**——未提权启动会自动请求，点一次确认
2. **SmartScreen 放行**——vp 安装器未代码签名，全新机器首次可能弹窗，选「仍要运行」
3. **重启续跑**——全新机器启用 WSL 功能后需重启一次，重启后重跑 `bootstrap.ps1` 继续
4. **填写身份**——bootstrap 生成 `~/.gitidentity` 占位后，填上**本机**的 git name/email（各机身份不同；不填则 git 拒绝提交，这是防错护栏）

重跑 bootstrap 幂等：已就位的全部跳过，只有漂移会被收敛。

## 常用命令

| 命令 | 用途 |
|---|---|
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

## 文档

- 词汇表：[GLOSSARY.md](GLOSSARY.md) · 决策：[docs/adr/](docs/adr/) · 上游调研：[docs/research/](docs/research/) · 吸收账本：[docs/upstream-ledger.md](docs/upstream-ledger.md)
- 工单与规格：`.scratch/dev-env/`（本地 markdown issue，不使用 GitHub Issues）
