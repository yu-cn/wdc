# Changelog

本项目所有显著变更记录于此文件。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)（显著变更人为记录、分类归档、每个版本可跳转）；版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)（v0.x 阶段破坏性变更走 MINOR）；提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/v1.0.0/)——feat / fix 驱动版本号。发布动作与验证锚点见各 [release](https://github.com/yu-cn/wdc/releases)。

## [Unreleased]

## [0.9.0] – 2026-10-31

### Changed
- **破坏性**：语言管理器 vp 退役、mise 升正（联动 [LDC ADR-0016](https://github.com/yu-cn/ldc/blob/main/docs/adr/0016-vp-retire-mise-takeover.md)、工单39）——`install-languages.ps1` 重写为 mise 默认环境（`mise use -g node@lts`）；`configs/cli-tools.winget` 声明 mise（jdx.mise，useLatest 域内惯例免钉）；remove-leftovers 增 vp 退役迁移项（迁移冲突通道，ADR-0007 宪章内——三种布局目录 + 用户 PATH 注入清除）；`configs/vp-version` 钉子退役（两仓同值钉子消失，dev-standard §6 钉子同值标注「当前无实例」——LDC 主笔同步拷贝）；`configs/vscode-extensions.txt` 去 vite-plus 扩展包；common.ps1 vp 助手、verify/inventory/bootstrap-main/install-wsl-env 换面；README 五处措辞同步；.gitattributes 相应行退役
- README 首屏演示重录——换轨后真实输出（语言栈 mise 断言行、LDC 委托段更新为渲染拷贝时代文案），agg v1.9.0 重转 GIF

### Added
- dotfiles/windows：pwsh profile 挂 `mise activate pwsh`、Git Bash bashrc 挂 shims PATH + activate（Node 等语言工具链按目录切换，与 LDC 侧同款）
- VSCode 扩展清单补 fss/ZCode 上游推荐三件（better-comments / mermaid-preview / tailwindcss）——vite-plus 扩展包退役时核实其仅捆绑 vitest+oxc（清单均已单独声明，摘包零损失）

## [0.8.0] – 2026-10-27

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

## [0.7.0] – 2026-10-26

### Added
- 漂移方向判定（对齐 [LDC ADR-0015 补注](https://github.com/yu-cn/ldc/blob/main/docs/adr/0015-copy-render-not-symlink.md)）：渲染账本 `%LOCALAPPDATA%\wdc\rendered.sha256` 判定 template-update / machine / both / unknown 四方向——纯模板更新免 `.bak` 直接重渲染；triage 逐项标注方向（双向漂移警示吸收会盖掉模板更新）
- `wdc audit` winget 清单准入对账（只读恒 exit 0）：已声明未装（收敛待办）+ 自装未声明（清单准入候选，INFO 计数 + 头部样例）
- README 首屏终端速览演示（`docs/demo.cast` + agg 转 GIF 嵌播，真实命令输出脱敏生成）

### Changed
- 验证瘦身：`wdc sync` 收尾 verify 降 `-Quick`（秒级，三域漂移详查走 `wdc verify -Full`）、validate 由 CI 兜底降级 SKIP（HEAD==origin/main 场景）；fresh-machine 冒烟 WSL 段交界面化——不委托 LDC bootstrap 安装全程（LDC 本体收敛归 LDC 容器冒烟），只验 wsl.conf/shell/身份/probe 交界面。实测：日常收敛全程 6-10 分钟 → **184 秒**；冒烟 Stage 6 198s → 40s

## [0.6.0] – 2026-10-26

### Changed
- **破坏性**：dotfiles 落点由符号链接改为安装期渲染拷贝（对齐姊妹仓 [LDC ADR-0015](https://github.com/yu-cn/ldc/blob/main/docs/adr/0015-copy-render-not-symlink.md)）——符号链接时代的两大结构性问题（机器侧工具写穿污染仓库、仓库缺席死链失联）随之根治；verify / status 改「落点与模板一致」逐项内容断言，triage 分流平移（吸收=落点回写模板显式 pathspec commit / 还原=自模板重渲染）；覆盖前轮转备份 `.bak`、同内容幂等跳过、符号链接残形直接替换
- pwsh profile / Git Bash bashrc 的漂移即时提示改双信号：落点内容漂移（经单一来源 `Test-DotfileInSync` 逐项 hash 比对）+ 未提交模板编辑（git porcelain 保留）；零漂移静默
- 配套修复：WSL 冒烟 LDC_SMOKE 改调用方传参——宿主 env 不跨 WSL 边界（发行版内探测恒空，两轮 CI 实录）

## [0.5.0] – 2026-10-24

### Added
- `scripts/get.ps1` 零前置远程一键引导：缺 Git 自动 winget 安装（弹一次 UAC）→ 仓库定位（`~/.wdc` 指针有效则复用）→ 转发 bootstrap；README 快速开始改版

### Changed
- 移除清单收敛为两类（ADR-0007）：本仓自清理（退役 WT fragments）与迁移冲突（VSCode 商店版换 winget 版）——清单外一概不碰，语言栈与已装软件一律不卸；`dotfiles/wsl/` 退役删除（Linux 模板归姊妹仓 LDC）
- 已知坑 14/15 入册：Git for Windows 升级三道坎、仓库缺席 = dotfiles 全量死链失联（恢复配方 + include 备选否决）

## [0.4.0] – 2026-10-24

### Added
- WSL 阶段委托姊妹仓 [LDC](https://github.com/yu-cn/ldc)（LDC-0007 统筹）：`setup-ubuntu.sh` 退位薄委托（root 段委托 install-packages / user 段委托 bootstrap），WDC 保留 WSL 生命周期引导（WSL 启用、装发行版、wsl.conf systemd、默认 shell）+ 身份带过；验收断言委托 `ldc verify --quick`

## [0.3.0] – 2026-10-23

### Changed
- bootstrap 全程提权重构：提权子回合一回合跑完七阶段（含 WSL），根除「wsl.exe 提权上下文 + PS 管道捕获输出挂死」已知坑①（安装类 Start-Process 绝不捕获、查询走有界文件捕获）

### Added
- wdc CLI 体验修订：裸命令改只读快照（不触发同步/UAC）、`help <命令>` 单命令详解、`--version`、未知子命令就近建议、首跑状态可见性（身份/WSL 两步）
- 新机首跑缺口修复：Stage 1 幂等 `winget configure --enable` + VCRedist 入 cli-tools 域

## [0.2.0] – 2026-10-21

### Changed
- 字体换 JetBrainsMono NF（CascadiaCode 被 winget 官方目录除名，ADR-0005）；WT 的 WSL profile 片段渲染机制退役、改模板静态声明 + 仓库图标资产（ADR-0006）；PowerShell 7 生命周期归 bootstrap 入口层管理（MSI 升级强杀 pwsh 宿主）

### Added
- 机器事实单一事实源：vp 版本钉子（三方共读）· dotfiles 落点映射（断言面=安装面）· Invoke-Subscript 子脚本深模块 · winget 域清单一致性校验 · WSL 有界调用/探测适配层 · winget 退出码语义一处定义 · check-upstream 干净基线

## [0.1.0] – 2026-10-21

### Added
- 开源基线（[v0.1.0](https://github.com/yu-cn/wdc/releases/tag/v0.1.0)）：MIT、README 门面化、CONTRIBUTING、fork 跟随指南；裸机入口降门槛（PowerShell 5.1 自举 PowerShell 7）；WSL 侧 Docker Engine 纳入默认；pre-commit 钩子接线 + verify 断言 + dotfiles 漂移即时提示；fresh-machine 手动冒烟工作流

[Unreleased]: https://github.com/yu-cn/wdc/compare/v0.8.0...HEAD
[0.9.0]: https://github.com/yu-cn/wdc/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/yu-cn/wdc/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/yu-cn/wdc/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/yu-cn/wdc/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/yu-cn/wdc/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/yu-cn/wdc/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/yu-cn/wdc/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/yu-cn/wdc/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yu-cn/wdc/releases/tag/v0.1.0
