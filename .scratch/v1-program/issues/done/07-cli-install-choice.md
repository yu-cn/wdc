# 07 wdc CLI 注入改为用户选择（首跑提示一次）

Status: ready-for-agent
Type: task

## 定夺

主人 2026-11-22 提出「wdc cli 是否安装应该提示用户选择」——评估采纳（推翻同日早前的 YAGNI 判断）：「装之前问一句」优于「装完后教清理」，且是「不弄坏用户环境」姿态的收口件（接入 shell 先征得同意）。

## 方案

- **首跑入口层提示一次**（bootstrap.ps1，提权子回合前）："是否安装 wdc 命令到 shell？(Y/n)"——默认 Y
- **选择记 `%LOCALAPPDATA%\wdc\cli.json`**（{install: bool}），此后不再问；`wdc exit` 删状态后重装会再问（合理：新轮回新选择）
- **非交互（CI/管道）默认装**（stdin 重定向检测，同 exit-wdc 预演模式判定）；**旗标预设**：`bootstrap.ps1 -NoCli` / `-Cli`（自动化与不愿被问的用户）
- **渲染剥段**：pwsh-profile.ps1 与 bashrc 的 wdc 段（函数+补全+漂移提示）加 `# --- wdc-cli:begin/end ---` 标记；选择否时渲染期剥段（单一来源函数入 dotfiles-map.ps1——Test-DotfileInSync 六方共用同一变换，落点=模板剥段后内容，漂移判定不破坏）
- 透传链：bootstrap.ps1 → bootstrap-main（-NoCli）→ 提权子回合命令行（同 -SkipValidate 模式）

## 验收

- [ ] 模板标记对 + 剥段函数单一来源（dotfiles-map.ps1 自包含）
- [ ] 入口提示 + cli.json 记录 + 旗标 + 非交互默认
- [ ] LETH/存量机预置 cli.json=true（作者日常，免打扰）
- [ ] validate 全绿；LETH 渲染回归（选择 true 时落点与现状零差异）
- [ ] README 一次性使用节与 CHANGELOG 记账
