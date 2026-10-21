Status: ready-for-human

# 01 · CascadiaCode 已被 winget 目录除名——新机 NF 字体方案定夺

## 事实（2026-10-21，wdc sync 冒烟暴露）

- 提权 apply 时 cli-tools 域 CascadiaCode 单元必败：内部 winget `0x8A150014 = NO_APPLICATIONS_FOUND`（官方码表核实），整域汇总 `0x8A15C005 = WINGET_CONFIG_ERROR_SET_APPLY_FAILED`；同域其余 16 个单元全部成功。
- `winget search / show` 全源（winget / msstore / winget-font）均无此包；winget-pkgs 仓库 manifest 目录 404（manifests/m/Microsoft/CascadiaCode，同字母段其他包在列）——**包已被官方从 winget 目录除名**。工单 28 入域时有效，随后被移除。
- 本机不受影响：全套 Cascadia NF 字体早已按用户装在 `%LOCALAPPDATA%\Microsoft\Windows\Fonts`（winget 不追踪，故 `winget list` 看不见），WT 渲染正常。受影响面：**新机器的 NF 字体来源** + 每次全量 bootstrap 在该单元 FAIL。

## 方案（环境主人定夺：**C**）

- **A. 删死单元，字体归机器自留地**：零机制；新机提示符图标豆腐块，手动装一次。
- **B. 删死单元 + 编排层脚本装官方 release 字体**：钉版本有先例，但深挖后暴露两个糙点——字体文件被占用不可覆盖（钉子升版永远别扭）、本机字体竟零注册表记录（注册「正确姿势」存疑，实现风险高于初判）。已弃。
- **C. 换 winget 在售 NF 字体包（已选）**：`DEVCOM.JetBrainsMonoNerdFont` 3.3.0（正经 WiX MSI、机内注册、原生升级与漂移核销），WT/VSCode 模板 fontFace 同步换族；零新机制、verify 零新增。审美换 JetBrains Mono 由主人接受。

## 实施记录（2026-10-21）

- `configs/cli-tools.winget`：CascadiaCode 死单元 → JetBrainsMonoNerdFont 单元（含除名实录注释）
- `dotfiles/windows/terminal-settings.json`：face → `JetBrainsMono Nerd Font Mono`（终端用 Mono 变体，图标单宽不错位）
- `dotfiles/windows/vscode-settings.json`：editor.fontFamily → `'JetBrainsMono Nerd Font', Consolas, ...`（保留回退链）；terminal.integrated.fontFamily → `'JetBrainsMono Nerd Font Mono'`
- `README.md`：CLI 概览行更新（字体入列；顺带矫正工单27 遗留的「PowerShell 7 在域内」陈述——入口层负责）
- 本机用户目录的旧 Cascadia 字体：零注册表记录的惰性残留，不碍事，留作机器自留物不清理

## 验收清单

- [x] 方案定夺记录于 Comments（C，如上）
- [ ] 实施后全量 bootstrap 提权跑全绿（cli-tools 不再 FAIL；字体装入后确认注册族名与模板一致）
- [x] validate.ps1 全绿

## Comments

- 2026-10-21 开单（sync 冒烟实录；官方码表、winget-pkgs 404、本机字体清单均已核）。推荐 B。定夺前每次全量 bootstrap 都会在此单元诚实 FAIL——非误报。
- 2026-10-21 决策实录：B 方案查证后下调推荐（占用不可覆盖 + 注册姿势存疑，见方案栏），改推 A；主人提议折中看 C，查实 winget 在售 NF 包恰为 JetBrainsMono（唯一），C 兼得「全声明式 + 零机制 + 原生升级」，定为 **C**。
