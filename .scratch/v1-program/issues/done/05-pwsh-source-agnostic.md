# 05 pwsh 配置源不可知化——7.7.0 起 MSI 停发适配

Status: ready-for-agent
Type: task

## 问题（主人 2026-11-21 报告，跨机实录）

其他机器用 README 一行命令引导，winget 装出的 PowerShell 7 是 MSIX 形态（7.7.0 起官方停发 MSI，MSIX 为唯一 Windows 渠道——devblogs 2026-11-10 GA 公告 + 2026-04 预告）；而 WDC 的 Windows Terminal 模板硬编码 MSI 机器路径 `C:\Program Files\PowerShell\7\pwsh.exe` → MSIX 机器上该路径不存在 → WT profile 异常（主人报告的症状）。事实自查三处 MSI 时代假设：

1. `dotfiles/windows/terminal-settings.json` L66：commandline 硬编码 MSI 路径（**症状根源**）
2. `bootstrap.ps1` Get-PwshExe 候选路径无 MSIX 别名位（`%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe`）；升级命令钉死 `--source winget`（msstore 来源机器匹配不到）
3. `scripts/adhoc/git-upgrade-task-creator.ps1` L9：schtasks 动作硬编码 ProgramFiles pwsh 路径（坑「schtasks 动作须绝对路径」仍须满足——改为运行时解析实际路径）

## 方案（源不可知：MSI 机器级 / MSI 用户级 / MSIX 三态通吃）

- WT 模板 commandline 改裸 `pwsh.exe`（WT 经 PATH 解析；三态安装路径均在 PATH——MSIX 走 WindowsApps 执行别名，版本升级也不动路径）
- Get-PwshExe 候选补 MSIX 别名位；`winget upgrade` 摘除 `--source winget` 钉死（按已装包自身来源解析）；install 保留 `--source winget` 钉死（确定性）与 `--scope user`（MSI 旧版免管理员所需；MSIX 下无害忽略）
- git-upgrade-task-creator 改 `Get-Command pwsh` 运行时解析 + ProgramFiles 兜底（绝对路径要求不变）

## 验收

- [x] 三处修复落地，validate 全绿
- [x] LETH（MSI 机器级）WT 模板变更后 json 语义比对确认变更可见（status 报 1 项漂移=WT settings——下次 sync 重渲染落点）
- [x] CHANGELOG Fixed 记账（存量机影响：WT 落点下次 sync 重渲染，行为正向）

## Comments

- 2026-11-21 开票即收。7.7.0 MSI 停发事实核自官方 devblogs（2026-11-10 GA 公告 + 2026-04 预告）与 Microsoft Learn。WT 裸 `pwsh.exe` 三态通吃原理：MSI 机器级/用户级安装目录在 PATH，MSIX 走 WindowsApps 执行别名（路径与版本解耦）。install 保留 `--source winget`+`--scope user`（MSI 旧版免管理员所需，MSIX 下 scope 无害忽略）；upgrade 摘源钉死（msstore 装机可匹配）。
