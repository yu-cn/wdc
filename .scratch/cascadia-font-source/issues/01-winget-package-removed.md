Status: ready-for-human

# 01 · CascadiaCode 已被 winget 目录除名——新机 NF 字体方案定夺

## 事实（2026-10-21，wdc sync 冒烟暴露）

- 提权 apply 时 cli-tools 域 CascadiaCode 单元必败：内部 winget `0x8A150014 = NO_APPLICATIONS_FOUND`（官方码表核实），整域汇总 `0x8A15C005 = WINGET_CONFIG_ERROR_SET_APPLY_FAILED`；同域其余 16 个单元全部成功。
- `winget search / show` 全源（winget / msstore / winget-font）均无此包；winget-pkgs 仓库 manifest 目录 404（manifests/m/Microsoft/CascadiaCode，同字母段其他包在列）——**包已被官方从 winget 目录除名**。工单 28 入域时有效，随后被移除。
- 本机不受影响：全套 Cascadia NF 字体早已按用户装在 `%LOCALAPPDATA%\Microsoft\Windows\Fonts`（winget 不追踪，故 `winget list` 看不见），WT 渲染正常。受影响面：**新机器的 NF 字体来源** + 每次全量 bootstrap 在该单元 FAIL。

## 方案（环境主人定夺）

- **A. 删死单元，字体归机器自留地**：零机制、最 YAGNI；代价是新机首开终端 starship 图标缺字形，需手动装一次字体。
- **B. 删死单元 + 编排层脚本装官方 release 字体（推荐）**：从 microsoft/cascadia-code GitHub release（现最新 v2407.24，zip 含全家族）下载装到用户字体目录；版本钉入 configs（同 vp-version 先例）；字体已在位则幂等跳过（本机即此情形）。保住工单 28「新机开箱即有 NF」的初衷，机制有语言栈先例。
- **C. 换 winget 在售 NF 字体包**（如 JetBrainsMono NF 系）：保持全声明式；代价是换字体家族，WT 模板 fontFace 同步改。

## 验收清单

- [ ] 方案定夺记录于 Comments
- [ ] 实施后全量 bootstrap 提权跑全绿（cli-tools 不再 FAIL）
- [ ] validate.ps1 全绿

## Comments

- 2026-10-21 开单（sync 冒烟实录；官方码表、winget-pkgs 404、本机字体清单均已核）。推荐 **B**。定夺前每次全量 bootstrap 都会在此单元诚实 FAIL——非误报。
