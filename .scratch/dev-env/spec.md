# Spec: WDC 通用开发环境（dev-env）

Date: 2026-10-19（历史快照——主线已随工单 01–40 整体落地并多轮超越，vp/symlink dotfiles/Docker 不默认装/不引入 CI 等多处已随后续 ADR 演进；现行状态以 issues/ 工单流、docs/adr/ 与 README 为准）
Sources: grill-with-docs 访谈（2026-10-19）· GLOSSARY.md · docs/adr/0001~0003 · docs/research/windowsdeveloperconfig.md

## Problem Statement

我（环境主人）此前用 microsoft/WindowsDeveloperConfig 的 dev-config 与 wsl-comfort 配置过开发机，但其中不少 opinion 不符合我的需要或喜好（勿扰全关通知、远程桌面开启、直装 Node/Python 与我自选的版本管理器双轨并存、终端主题引用断链、WSL 侧 zsh 不合手、Oh My Posh 装而无配置等）；同时我有多台开发机、git 身份各异，没有一套属于自己、可重放、可审查的环境配置。手工逐机调教不可持续，残留清理无清单可依。

## Solution

在本仓库（WDC）自建一套**通用核心配置**：Windows 侧的软件与系统设置用按域拆分的 winget configuration 声明；WSL 侧（Ubuntu + bash + 栈）与编排类步骤由 bootstrap 脚本负责；个人配置文件以 dotfiles 形式版本化并由 bootstrap 以 symlink 安装。任何一台开发机 clone 后跑一条 bootstrap 命令即收敛到声明状态——包括执行显式移除清单清掉上游残留。git 身份经每机本地的身份文件隔离，多机多身份天然安全。收尾以干净 Hyper-V VM 从零冒烟作为交付验收。

## User Stories

1. As an 环境主人, I want 在一台全新 Windows 开发机上 clone 本仓库并运行一条 bootstrap 命令就得到完整开发环境, so that 新机/重装的开箱成本趋近于零。
2. As an 环境主人, I want bootstrap 幂等可重跑, so that 我可以随时把任何一台机器拉回声明状态而不怕重复执行。
3. As an 环境主人, I want Windows 侧软件与系统设置以按域拆分（base-windows / cli-tools / editors / languages）的 winget configuration 声明, so that 配置可审查、可校验、可局部重跑。
4. As an 环境主人, I want dotfiles 版本化在仓库内并以 symlink 安装, so that 修改仓库即刻生效、机器上永远只有一份真相。
5. As an 环境主人, I want bootstrap 在安装 dotfiles 前把机器上已存在的旧文件备份为 *.bak, so that 我的既有内容绝不丢失。
6. As an 环境主人, I want git 身份存于每机本地的身份文件（~/.gitidentity）而不入仓库, so that 各开发机用各自身份、永不串号。
7. As an 环境主人, I want bootstrap 发现身份文件缺失时生成占位并明确提示填写, so that 忘配身份的机器上 git 直接拒绝提交，形成防错护栏。
8. As an 环境主人, I want WSL 侧 git 身份与 Windows 侧一致（bootstrap 自动带过）, so that 同机两侧提交身份不分裂。
9. As an 环境主人, I want Windows 侧与 WSL 侧都用 vp 管理 Node（irm 官方脚本安装、钉 VP_VERSION）, so that 一套心智模型、.node-version/.nvmrc 两侧通吃。
10. As an 环境主人, I want 两侧都用 uv 管理 Python, so that 工具链选择一致、经验互相迁移。
11. As an 环境主人, I want WSL 侧由 bootstrap 编排安装：Ubuntu、默认 bash（罢黜 zsh）、Go（官方 tarball 钉版本）、精简 apt 工具集、gh（apt 官方源）, so that WSL 侧同样开箱即得且合我的手。
12. As an 环境主人, I want 一份显式移除清单被执行——直装 Node、nvm-windows（含其 symlink）、直装 Python 3.13、.NET SDK 10 与 ASP.NET 运行时、VSCode 商店 MSIX 版、Oh My Posh、远程桌面开启（注册表还原）、勿扰全关（注册表还原）、ComfortShell 与 DevConfig 两个 WT fragment, so that 上游不合喜好的残留被精确清掉。
13. As an 环境主人, I want 移除清单之外的一切一律不碰, so that 机器自留地（JetBrains 套件、Typora、GitHub Desktop 等）和非开发软件绝对安全。
14. As an 环境主人, I want .NET Desktop 运行时保留不动, so that PowerToys 等依赖它的应用不被误伤。
15. As an 环境主人, I want pwsh / Git Bash / WSL bash 三个 shell 的提示符统一由 Starship 接管、共用同一份主题文件, so that 一套视觉语言、一份配置。
16. As an 环境主人, I want 三个 shell 拥有同一组别名（gs/gl/gd 等）与 fzf（Ctrl-R/Ctrl-T/Alt-C）、zoxide（z 跳目录）体验, so that 肌肉记忆三处通用。
17. As an 环境主人, I want 新建的 pwsh profile 自动 source vp 的 env 脚本并初始化 starship/zoxide/fzf, so that 打开终端即得完整环境。
18. As an 环境主人, I want Windows Terminal 主题真正生效（Catppuccin 配色正式定义进配置、替换断链的引用）, so that 我以为拥有的深色主题从「从未生效」变为「真的有」。
19. As an 环境主人, I want WT 的 WSL 入口收敛为一个原生 Ubuntu profile（移除 Comfort Shell profile 与死掉的 Copilot profile）, so that 入口干净、点开即用。
20. As an 环境主人, I want VSCode 保存时格式化真实生效（按语言配 defaultFormatter：Python→ruff、TS/JS/JSON/CSS→prettier，外加 ruff 保存时整理 import）, so that 我开的 formatOnSave 不再空转。
21. As an 环境主人, I want 文件卫生三件套（去行尾空白、补末尾空行、去多余空行）, so that 多机协作的 diff 干净。
22. As an 环境主人, I want .venv 进入文件监听与搜索排除, so that Python 项目不再白烧 watcher。
23. As an 环境主人, I want VSCode 扩展（现有 23 个清单）随配置自动安装且不钉版本, so that 新机扩展即刻齐备、无版本维护负担。
24. As an 环境主人, I want VSCode 自带 Settings Sync 保持关闭、仓库为唯一主人, so that 不会出现两个同步源打架。
25. As an 环境主人, I want 日常用 winget configure test 与无副作用校验（validate + 脚本静态检查）验证配置, so that 不动机器也能发现声明问题与漂移。
26. As an 环境主人, I want 收尾时在干净 Hyper-V VM 从零跑通完整 bootstrap（含 WSL 侧）作为交付验收, so that 「新机开箱即用」是被证明的而非假设的。
27. As an 环境主人, I want bootstrap 输出分阶段报告（做了什么/改了什么/跳过什么/失败在哪）, so that 每次执行结果可读可查。
28. As an 环境主人, I want 一个上游检查脚本能对比 microsoft/WindowsDeveloperConfig 的新改动与我们的声明并输出「值得考虑」清单, so that 上游有益更新不被错过。
29. As an 环境主人, I want 每次吸收上游内容都记入吸收账本（日期+条目+上游链接）, so that 血统可追溯、重复检查有基线。
30. As an 环境主人, I want 仓库推送到 GitHub 私有远端, so that 备份与新机 clone 载体一步到位（issue 仍走本地 .scratch/）。
31. As an 环境主人, I want Docker 不在默认声明内但文档留一条命令的补装指引, so that 用得少不为它背维护成本、要用时也不费劲。
32. As an 环境主人, I want Homebrew(Linux) 从 WSL 侧移除, so that 包管理器收敛为 apt + uv + vp + tarball 四件各司其职。

## Implementation Decisions

- **三层应用模型**（ADR-0002）：声明式层（winget configuration，DSC 资源：Microsoft.WinGet/Package、Microsoft.Windows/Registry、Microsoft.VSCode.Dsc/VSCodeExtension）负责包与系统设置；编排层（bootstrap PowerShell 脚本）负责提权重启、WSL 侧安装、vp/Go/uv 的版本安装、dotfiles 链接、移除清单执行；dotfiles 层为仓库内版本化目录。不强求编排进 DSC（上游迁移即前车之鉴）。
- **配置按域拆分**：base-windows（系统 opinion 与注册表设置，含「恢复系统通知」等反转项）、cli-tools、editors（VSCode+扩展）、languages（语言管理器）。bootstrap 按序应用，依赖方向为设置→软件。
- **vp 安装**：Windows 侧 `irm https://vite.plus/ps1 | iex`（用户明确指定），以环境变量钉 VP_VERSION；WSL 侧用 vp 官方 Linux 安装方式。Node 具体版本交给 `vp env default`（跟随 LTS 或钉 node@24，实施时定）。
- **移除清单语义**：包卸载与注册表还原两类；Desktop 运行时明确保留；清单外不碰是硬原则。
- **身份机制**：gitconfig 模板不含 [user] 段，以 include 引用每机本地 `~/.gitidentity`；bootstrap 缺失时生成占位并提示；WSL 侧从 Windows 侧同值部署。
- **dotfiles 安装**：symlink（开发者模式已启用）；目标存在旧文件先备份 `*.bak`；三 shell 的 rc 与 profile 均由模板生成，Git Bash 现有 rc 的 fzf/zoxide/history/别名结构作为统一模板源。
- **Starship 统一**：单份主题文件链接到两侧三个 shell；Oh My Posh 移除；WT 配色（Catppuccin Mocha 系）正式定义进 terminal-settings 并设为全局默认，替换断链引用。
- **VSCode**：Settings Sync 关闭；扩展以现清单 23 项声明、不钉版本；settings 补 formatter 映射、整理 import、文件卫生、.venv 排除。
- **WSL 侧编排**：Ubuntu 安装沿用上游验证过的阶段化思路（启用组件→重启续跑→装发行版）；发行版内默认 shell 定为 bash；清 wsl-comfort 托管块后以我们模板重建 rc。
- **上游吸收**（ADR-0001 补充）：检查脚本 + 吸收账本 + 固化基线，人工决定移植，不做 git 级同步。
- **远端**：GitHub 私有仓库；`main` 为唯一长期分支。
- 词汇表八个术语（环境配置/dotfiles/bootstrap/Windows 侧/WSL 侧/通用核心/机器自留地/身份文件）为规格与工单的强制用语。

## Testing Decisions

- 唯一高缝隙：**bootstrap 入口**——外部行为是「机器状态收敛」，只在入口处验证，不测脚本内部实现。
- 三面验证（由便宜到贵，均已与用户确认）：
  1. 无副作用校验：`winget configure validate` 逐份配置 + PowerShell 脚本静态分析（PSScriptAnalyzer）——每次改动后跑。
  2. 本机幂等收敛：真实机器上 bootstrap 首跑变更、重跑零变更；`winget configure test` 报告漂移——迭代期跑。
  3. 干净 VM 全量冒烟：Hyper-V 全新 Windows → clone → bootstrap → 断言清单（包已装、注册表值符合、dotfiles 链接就位、身份占位生成、WSL 侧可用、移除清单生效）——收尾一次性验收。Sandbox 只能覆盖 Windows 侧（不支持 WSL2），作可选快验。
- 纯逻辑函数（备份命名、身份文件生成、include 行生成）可用 Pester 单测，属可选增强，不作为验收门槛。
- 无既有先例测试（空仓库），本规格自建上述三层即可，不引入 CI。

## Out of Scope

- Docker 默认安装与任何容器运行时声明（仅留文档指引）。
- JetBrains 套件、Typora、GitHub Desktop 等机器自留地工具的声明或卸载。
- 可选模块/override 机制与按机器的 profile（YAGNI，ADR-0003）。
- 日用软件全家桶（Q9-B 判据外的新日用项）。
- Rust/Java/kubectl/Azure CLI 等当前未用栈。
- Visual Studio。
- 定时自动重跑配置、CI 常态化测试。
- 上游 git 级自动同步/fork 维护。
- WSL 发行版内部eyond bash 工具链与栈之外的内容（如 zsh 生态、tmux 等未选用工具）。
- 新的日用级系统 opinion（R1~R11 之外的）。

## Further Notes

- 上游残留移除涉及注册表还原（远程桌面、勿扰），注意还原值与上游设置值精确互逆。
- vp 安装器未代码签名：干净 VM 冒烟时 SmartScreen 可能需要一次人工放行，验收步骤应写明。
- 双 VSCode 收敛（卸 MSIX）在本机执行时需确认用户数据目录不丢（用户级设置随 winget 版保留）。
- nvm-windows 卸载需同时清理 NVM_HOME、NVM_SYMLINK 环境变量与 `C:\nvm4w` 链接。
- 实施顺序建议 tracer-bullet：先让「最窄端到端」（clone→bootstrap→一台本机收敛）跑通，再逐域充实。
