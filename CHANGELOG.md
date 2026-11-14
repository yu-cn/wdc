# Changelog

[![Keep a Changelog](https://img.shields.io/badge/Keep%20a%20Changelog-2.0.0-informational)](https://keepachangelog.com/en/2.0.0/)

本项目所有显著变更记录于此文件。

- 格式遵循 [Keep a Changelog 2.0.0](https://keepachangelog.com/en/2.0.0/) 的中文化改造版（[docs/changelog-standard.md](docs/changelog-standard.md)，双仓同源、主作者位 LDC）——显著变更人为记录、六类型（Added/Changed/Deprecated/Removed/Fixed/Security）分类归档、每版本 compare 链接可跳转、倒序排列；破坏性变更以 `Breaking:` 标记写在对应类型节内（不单列节）
- 版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)（v0.x 阶段破坏性变更走 MINOR）；提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/v1.0.0/)——feat / fix 驱动版本号。发布动作与验证锚点见各 [release](https://github.com/yu-cn/wdc/releases)。

## [Unreleased]

### Changed
- pwsh init 产物缓存（pwsh-startup 工单01）：starship/gh/zoxide 的静态 init 产物改 bootstrap 渲染时生成到 `%LOCALAPPDATA%\wdc\cache\`（机器本地派生资产，ADR-0004 模式；starship 单层直取 `--print-full-init` 全量产物，绕旧写法「init 产物是 117 字节壳、求值时再嵌套 spawn 一次」的双层 spawn），profile 命中即 dot-source、缺失回退原样 spawn——存在性守卫原则不变，未 bootstrap 机器零报错；工具升级后缓存滞后一版，重跑 bootstrap 收口（profile 内刻意不做版本校验——校验即 spawn，抵消收益）。ASUS 真机热态开窗 4~5s → 2.5~3s（分步基准与诊断定案见 `.scratch/pwsh-startup/spec.md`）
- uv 参数补全惰性加载（pwsh-startup 工单02）：766KB 补全脚本原每开终端固定付 spawn+求值 ~670ms 而多数会话不用——改薄壳 ArgumentCompleter 首次 `uv <Tab>` 才生成求值（同一轮原生 completer 即注册参与出候选；置位后薄壳恒返回空让路，防双份候选）；uv 缺席不注册（存在性守卫）

## [0.13.0] - 2026-11-07

### Added
- `wdc status -Json` 机器可读出口（cli-ux 工单02，联动 LDC 同批 `--json`）：单行紧凑 JSON（`repo/dotfiles/identity/wsl/last_bootstrap/hints`，键口径与 ldc 对齐）；status 分支重构为先算后印，人读输出与 JSON 出口共用同一批判定。pwsh 绑定器把 `--json` 当未知参数拒绝（实测）——正典旗标 `-Json`，pwsh/Git Bash 包装层把 `--json` 归一转发，人机两面等价
- `wdc plan` 干跑预演（cli-ux 工单03，对齐 ldc plan）：只读零变更投影重跑 wdc sync 会做什么——仓库三态（将拉取 N 提交 / 将中止交人工 / 一致）、bootstrap 走全量还是快速路径（=会不会弹 UAC、分钟级还是秒级）及原因、verify 收尾口径；恒 exit 0（预演不是断言）。安装面逐项投影为后续票
- wdc 子命令 Tab 补全（cli-ux 工单05，联动 LDC 同批）：pwsh `Register-ArgumentCompleter` + Git Bash `complete -F`，词表解析自 wdc.ps1 的 `$wdcCommands` 行单一来源（纯文本解析零子进程）——改词表一处生效，shell 配置不抄列表
- `docs/cli-parity.md` 双仓 CLI parity 契约（cli-ux 工单07，主作者位 LDC，双仓同源拷贝）：命令表（含旗标与退出码）+ 共用 UX 约定；dev-standard-guard 周检循环纳入本文件，validate 加「实现命令表 == 契约注释行」断言——改实现忘改契约提交即红

### Changed
- wdc 的 `git fetch` 有界禁交互（cli-ux 工单01，对齐 ldc 既有防护）：status 5s / sync 10s 进程级硬超时 + `GIT_TERMINAL_PROMPT=0` + `GCM_INTERACTIVE=never`——坏网络不再挂起「秒级快照」，凭据过期 GCM 弹 GUI 在 agent 会话无提示挂死的面封死；status 未达降级按缓存判读，sync fetch 失败即中止不盲同步
- 子命令后接 `-h/--help` 出该命令详解（cli-ux 工单04）：原显示总览；裸 `wdc -h` 仍出总览（PSBoundParameters 守卫缺省值）
- 子命令表单一来源化（cli-ux 工单04）：未知命令与「没有单独的帮助」报错文案由 `$wdcCommands` 动态拼（原手抄四处、两处互不一致）；`$wdcCommands` 词序对齐契约文件
- `wdc sync` 收尾 BEL 提示（cli-ux 工单06，联动 LDC 同批）：bootstrap 失败与最终汇总两路收尾都响——分钟级长操作切走窗口结束有感知
- Write-Step 状态词表补 `PLAN`（Magenta）——plan 投影的「将变更」口径，对齐 ldc pstep

## [0.12.0] - 2026-11-07

### Added
- `wdc upgrade-git` 子命令（工单43，坑14 剧本常态化）——Git.Git useLatest 下 agent 会话（宿主即 Git Bash）内升级必被安装器 in-use 检查拦（四起实录，最近一次 ASUS 11-02 起 5 天收敛滞留）；命令按提权态选形态（未提权经 sudo 登记、UAC 放行）创建 HIGHEST 一次性计划任务跑升级剧本（等会话静默 → winget 升级 → 校验 gitconfig），登记后输出坑14 三件事纪律；bootstrap Stage 3 域失败且含 Git 单元时定向指路该通道。真机首跑即收滞留：2.56.0.windows.3 → .4（任务全程 89 秒，gitconfig 完好）

### Changed
- dotfiles 备份轮转设上限（工单44）：`.bak` 本体 + 编号系列至多 3 份——本体永不清，编号系列超出删 mtime 最老并逐项报告（删除动作可见；ADR-0015「机器侧内容绝不静默丢弃」以「报告在」的形态保持）——此前无限递增，双机长跑攒档

### Removed
- 「上游检查」机制退役（主人定夺：wdc 无严格意义上的上游——microsoft/WindowsDeveloperConfig 只是初始构建的参考资源之一，吸收账本 4 条中 3 条出自初始当日、此后零吸收；[ADR-0001 修订标注](docs/adr/0001-own-tree-not-fork-upstream.md)）——`wdc status` 的「距上次检查 >30 天提示补课」提醒撤除；`check-upstream.ps1` 与基线移 `scripts/adhoc/` 留作历史工具；[docs/upstream-ledger.md](docs/upstream-ledger.md) 封卷为血统档案。README/forking.md 的「上游」所指 yu-cn/wdc 本仓（fork 用户视角的真实 fork 关系）不受影响，仓内「上游」词义归一

## [0.11.0] - 2026-11-01

### Changed
- WDC/LDC 边界最小核心化（e8bb745，工单41，GLOSSARY「双边最优化」完整应用；联动 [LDC 工单12](https://github.com/yu-cn/ldc)）——`setup-ubuntu.sh` 撤除最后三件「WDC opinion」（默认 shell / wsl.conf systemd / docker 组，LDC install-packages.sh 机器形态段承接，root 直调缺 SUDO_USER 由 LDC_USER 契约补）；`probe.sh` 退役，shell/systemd 两键断言移交 LDC verify（verify 第 5 组只余「LDC verify 退出码透传」验收面）；`LDC_SKIP_DOCKER` 透传退役改 LDC `docker_skipped()` 自判定（env 保留外部覆盖语义）。dev-standard §46 补澄清句：同号同日仅限联动变更（v0.10.0 锚点回看：双仓零契约联动仍同号同日属过度执行）
- `wdc sync` 收敛账本快速路径（336d9ad，工单42）：已收敛且声明未变时跳过 bootstrap，424s → 8s 真机实测——bootstrap 全量成功尾部写 `%LOCALAPPDATA%\wdc\converged.json`（账本=HEAD，仅提权上下文记账，ValidateOnly / 非提权 -NoElevate 半量 / 中途失败不写）；sync 读账本 commit==HEAD 且工作区干净 → SKIP bootstrap 仅 verify -Quick；账本缺失/损坏/解析失败、有新 pull、工作区有未提交改动一律回退全量（宁可慢不可假绿）；`wdc sync -Full` 强制全量，help/README 同步
- 三 shell 各自最优化批次（5651803，GLOSSARY「双边最优化」首个完整应用）：pwsh 加 `PredictionViewStyle ListView` 可视预测 + gh/uv 原生参数补全（存在性守卫；git 补全生态是 bash 系、docker 不在 Windows——均刻意不补留据）；Git Bash 的 fzf 路径补全曾顶掉 git 原生补全（实测 69 命令被绑）——fzf 块后重挂 `git-completion.bash`（ucrt64/mingw64 双探测防坑17 迁名复发）+ gh 补全；漂移检查加 `[[ $- == *i* ]]` 交互守卫——agent 宿主 shell（bash -lc）每工具调用 0.337s 的 pwsh 子进程会话税归零，真终端提醒不变
- CHANGELOG.md 升级 Keep a Changelog 2.0.0 并落地中文化改造版规范（docs/changelog-standard.md，双仓同源、主作者位 LDC）：版本节连字符归一、破坏性条目改 `Breaking:` 标记、节内六类型 canonical 序、修复 Unreleased compare 链陈旧（v0.8.0...HEAD → v0.10.0...HEAD）；dev-standard-guard 同源守护扩展至 changelog-standard.md

### Fixed
- pwsh 侧 fzf 键位自上线以来从未生效（cc46108）——fzf 官方集成仅 `--bash`/`--zsh`/`--fish`/`--nushell`（0.74.5 实测无 `--powershell`），旧实现靠空输出守卫静默跳过；改 PSReadLine 键位处理器手工接线（Ctrl-R 历史模糊搜索 / Ctrl-T fd 搜索源 + bat 预览多选 / Alt-C 目录跳转），零新依赖、与 LDC bash 侧同语义，fd/bat 缺席对应键位不绑定

## [0.10.0] - 2026-11-01

### Added
- `configs/chrome.winget` 独立域（工单40 主人定夺方案 b）——Chrome 自 cli-tools 拆出（下载体积大、CI runner 禁 DO 服务三连败实录，工单26）：失败只红自己、不拖累其余声明；`Get-WdcDomains` 顺序清单与提权表同步，verify 遍历走单一来源自动纳入

### Changed
- bootstrap Stage 3 各 winget 域改逐单元流式输出 + 发起前 INFO 行（单元数/长域预期，工单40）——原整域收完才回放，`base-windows OK` 后长域（cli-tools 达 5–10 分钟）全程静默
- install-languages 补「mise shims → 用户 PATH」确保步（ensure 型）——vp 安装器对等动作的声明化守卫：非 shell 进程（IDE/agent 的 MCP 插件按裸 node 拉起）依赖全局 node 解析，会话残留 PATH 曾把裸 node 先解析进 vp shim 链致 vp 目录无法清除（ZCode 上下文插件实录）；实测 mise winget 安装器已写入 shims，本步为幂等守卫


## [0.9.0] - 2026-10-31

### Added
- dotfiles/windows：pwsh profile 挂 `mise activate pwsh`、Git Bash bashrc 挂 shims PATH + activate（Node 等语言工具链按目录切换，与 LDC 侧同款）
- VSCode 扩展清单补 fss/ZCode 上游推荐三件（better-comments / mermaid-preview / tailwindcss）——vite-plus 扩展包退役时核实其仅捆绑 vitest+oxc（清单均已单独声明，摘包零损失）

### Changed
- **Breaking:** 语言管理器 vp 退役、mise 升正（联动 [LDC ADR-0016](https://github.com/yu-cn/ldc/blob/main/docs/adr/0016-vp-retire-mise-takeover.md)、工单39）——`install-languages.ps1` 重写为 mise 默认环境（`mise use -g node@lts`）；`configs/cli-tools.winget` 声明 mise（jdx.mise，useLatest 域内惯例免钉）；remove-leftovers 增 vp 退役迁移项（迁移冲突通道，ADR-0007 宪章内——三种布局目录 + 用户 PATH 注入清除）；`configs/vp-version` 钉子退役（两仓同值钉子消失，dev-standard §6 钉子同值标注「当前无实例」——LDC 主笔同步拷贝）；`configs/vscode-extensions.txt` 去 vite-plus 扩展包；common.ps1 vp 助手、verify/inventory/bootstrap-main/install-wsl-env 换面；README 五处措辞同步；.gitattributes 相应行退役
- README 首屏演示重录——换轨后真实输出（语言栈 mise 断言行、LDC 委托段更新为渲染拷贝时代文案），agg v1.9.0 重转 GIF

## [0.8.0] - 2026-10-27

### Added
- get.ps1 支持 `WDC_TAG` 钉版与 `WDC_REPO` 覆盖（env 形态——`irm | iex` 传不了参数；tag 钉版对齐 LDC get.sh 既有能力，fork 用户一条命令引导自己的仓库）
- CI 新增 dev-standard-guard 双仓同源守护工作流：每周拉姊妹仓 LDC 的 `docs/dev-standard.md` 去 CR 归一比对，漂移即红（刻意不挂 push——双仓协同编辑必有先后，瞬时红污染 badge）；本仓 `.gitattributes` 同步钉该文件 LF 消跨仓行尾假红
- 坑14 Git 升级计划任务剧本自 `logs/`（gitignore 盲区、机器间不可见）沉淀 `scripts/adhoc/` 入库，创建器参数化去机器硬编码路径

### Changed
- WSL 委托的 bootstrap exit-2 待办判定改按 LDC 机器标记 `[LDC_TODO=tag]`（严格容忍：恰为 desktop 一项才按 WSL 形态消化，未知新标记一律真问题透传），退役散文文案 grep——两仓间字符串契约的静默失效面对齐 [LDC ADR-0007 补记](https://github.com/yu-cn/ldc/blob/main/docs/adr/0007-wdc-ldc-coordination.md) 根治
- fresh-machine 冒烟补幂等重跑腿（第二遍除身份占位提醒与 WT settings 环境写穿两项已知噪声外零 `[CHANGED]` 才放行，对齐 LDC fresh-container）并月度定时常态化（公开仓库 runner 免费，此前仅手动）
- dev-standard §5 补「双仓版本对齐」约定（LDC 主笔、本仓同步拷贝）：双仓联动变更发版时两仓版本号对齐收口——本版与 LDC v0.8.0 同号同日为首次执行

### Fixed
- `wdc status` 最近 bootstrap 判定行覆盖提权子回合日志（取主/elevated 两日志较新者搜判定）——此前提权委托路径下恒显示「（无判定行）」，真判定就在配对 elevated 日志尾
- validate 的 WSL shellcheck 腿对「发行版列得出但 execvpe(shellcheck) 失败」中继半态误 FAIL——SKIP 面补不可执行证据（此前只认退出码 127；幂等重跑腿 run 40356743323 实录）
- vp env install 每轮误报 `[CHANGED]`——ensure 型步骤改报 OK（对齐 LDC 口径；LETH 本机历次日志同病，幂等重跑腿 run 40361634404 实录）

## [0.7.0] - 2026-10-26

### Added
- 漂移方向判定（对齐 [LDC ADR-0015 补注](https://github.com/yu-cn/ldc/blob/main/docs/adr/0015-copy-render-not-symlink.md)）：渲染账本 `%LOCALAPPDATA%\wdc\rendered.sha256` 判定 template-update / machine / both / unknown 四方向——纯模板更新免 `.bak` 直接重渲染；triage 逐项标注方向（双向漂移警示吸收会盖掉模板更新）
- `wdc audit` winget 清单准入对账（只读恒 exit 0）：已声明未装（收敛待办）+ 自装未声明（清单准入候选，INFO 计数 + 头部样例）
- README 首屏终端速览演示（`docs/demo.cast` + agg 转 GIF 嵌播，真实命令输出脱敏生成）

### Changed
- 验证瘦身：`wdc sync` 收尾 verify 降 `-Quick`（秒级，三域漂移详查走 `wdc verify -Full`）、validate 由 CI 兜底降级 SKIP（HEAD==origin/main 场景）；fresh-machine 冒烟 WSL 段交界面化——不委托 LDC bootstrap 安装全程（LDC 本体收敛归 LDC 容器冒烟），只验 wsl.conf/shell/身份/probe 交界面。实测：日常收敛全程 6-10 分钟 → **184 秒**；冒烟 Stage 6 198s → 40s

## [0.6.0] - 2026-10-26

### Changed
- **Breaking:** dotfiles 落点由符号链接改为安装期渲染拷贝（对齐姊妹仓 [LDC ADR-0015](https://github.com/yu-cn/ldc/blob/main/docs/adr/0015-copy-render-not-symlink.md)）——符号链接时代的两大结构性问题（机器侧工具写穿污染仓库、仓库缺席死链失联）随之根治；verify / status 改「落点与模板一致」逐项内容断言，triage 分流平移（吸收=落点回写模板显式 pathspec commit / 还原=自模板重渲染）；覆盖前轮转备份 `.bak`、同内容幂等跳过、符号链接残形直接替换
- pwsh profile / Git Bash bashrc 的漂移即时提示改双信号：落点内容漂移（经单一来源 `Test-DotfileInSync` 逐项 hash 比对）+ 未提交模板编辑（git porcelain 保留）；零漂移静默
- 配套修复：WSL 冒烟 LDC_SMOKE 改调用方传参——宿主 env 不跨 WSL 边界（发行版内探测恒空，两轮 CI 实录）

## [0.5.0] - 2026-10-24

### Added
- `scripts/get.ps1` 零前置远程一键引导：缺 Git 自动 winget 安装（弹一次 UAC）→ 仓库定位（`~/.wdc` 指针有效则复用）→ 转发 bootstrap；README 快速开始改版

### Changed
- 移除清单收敛为两类（ADR-0007）：本仓自清理（退役 WT fragments）与迁移冲突（VSCode 商店版换 winget 版）——清单外一概不碰，语言栈与已装软件一律不卸；`dotfiles/wsl/` 退役删除（Linux 模板归姊妹仓 LDC）
- 已知坑 14/15 入册：Git for Windows 升级三道坎、仓库缺席 = dotfiles 全量死链失联（恢复配方 + include 备选否决）

## [0.4.0] - 2026-10-24

### Added
- WSL 阶段委托姊妹仓 [LDC](https://github.com/yu-cn/ldc)（LDC-0007 统筹）：`setup-ubuntu.sh` 退位薄委托（root 段委托 install-packages / user 段委托 bootstrap），WDC 保留 WSL 生命周期引导（WSL 启用、装发行版、wsl.conf systemd、默认 shell）+ 身份带过；验收断言委托 `ldc verify --quick`

## [0.3.0] - 2026-10-23

### Added
- wdc CLI 体验修订：裸命令改只读快照（不触发同步/UAC）、`help <命令>` 单命令详解、`--version`、未知子命令就近建议、首跑状态可见性（身份/WSL 两步）
- 新机首跑缺口修复：Stage 1 幂等 `winget configure --enable` + VCRedist 入 cli-tools 域

### Changed
- bootstrap 全程提权重构：提权子回合一回合跑完七阶段（含 WSL），根除「wsl.exe 提权上下文 + PS 管道捕获输出挂死」已知坑①（安装类 Start-Process 绝不捕获、查询走有界文件捕获）

## [0.2.0] - 2026-10-21

### Added
- 机器事实单一事实源：vp 版本钉子（三方共读）· dotfiles 落点映射（断言面=安装面）· Invoke-Subscript 子脚本深模块 · winget 域清单一致性校验 · WSL 有界调用/探测适配层 · winget 退出码语义一处定义 · check-upstream 干净基线

### Changed
- 字体换 JetBrainsMono NF（CascadiaCode 被 winget 官方目录除名，ADR-0005）；WT 的 WSL profile 片段渲染机制退役、改模板静态声明 + 仓库图标资产（ADR-0006）；PowerShell 7 生命周期归 bootstrap 入口层管理（MSI 升级强杀 pwsh 宿主）

## [0.1.0] - 2026-10-21

### Added
- 开源基线（[v0.1.0](https://github.com/yu-cn/wdc/releases/tag/v0.1.0)）：MIT、README 门面化、CONTRIBUTING、fork 跟随指南；裸机入口降门槛（PowerShell 5.1 自举 PowerShell 7）；WSL 侧 Docker Engine 纳入默认；pre-commit 钩子接线 + verify 断言 + dotfiles 漂移即时提示；fresh-machine 手动冒烟工作流

[Unreleased]: https://github.com/yu-cn/wdc/compare/v0.12.0...HEAD
[0.13.0]: https://github.com/yu-cn/wdc/compare/v0.12.0...v0.13.0
[0.12.0]: https://github.com/yu-cn/wdc/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/yu-cn/wdc/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/yu-cn/wdc/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/yu-cn/wdc/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/yu-cn/wdc/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/yu-cn/wdc/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/yu-cn/wdc/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/yu-cn/wdc/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/yu-cn/wdc/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/yu-cn/wdc/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/yu-cn/wdc/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yu-cn/wdc/releases/tag/v0.1.0
