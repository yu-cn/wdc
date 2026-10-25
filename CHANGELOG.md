# Changelog

本项目所有显著变更记录于此文件。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)（显著变更人为记录、分类归档、每个版本可跳转）；版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)（v0.x 阶段破坏性变更走 MINOR）；提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/v1.0.0/)——feat / fix 驱动版本号。发布动作与验证锚点见各 [release](https://github.com/yu-cn/wdc/releases)。

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

[Unreleased]: https://github.com/yu-cn/wdc/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/yu-cn/wdc/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/yu-cn/wdc/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/yu-cn/wdc/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/yu-cn/wdc/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/yu-cn/wdc/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/yu-cn/wdc/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yu-cn/wdc/releases/tag/v0.1.0
