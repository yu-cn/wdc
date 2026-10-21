Status: ready-for-human

# 02 · dotfiles 落点映射的单一事实源

## 问题

「仓库模板 → 机器落点」三份清单（install 7 项 / verify 6 项 / inventory 8 项）已实际漂移：**verify 漏验 VSCode keybindings 链接**；WT LocalState 包路径字面量重复 5 处。新增 dotfile 需手动同步三个脚本，漏一个即静默不验证。

## 方案（已实施）

- 新增 `scripts/lib/dotfiles-map.ps1`：`Get-DotfilesMap`（Name/Source/Target）+ `Get-WtLocalStateDir`；纯数据与纯函数，不依赖 common.ps1，可被任何脚本单独 dot-source
- install-dotfiles / verify-machine / inventory-machine 三方改读同一映射——**断言面 = 安装面**，keybindings 漏验就此闭合；install-wt-profiles 的 WT 目录同源
- inventory 保留 `~/.gitidentity` 单列（身份文件非链接，属机器数据，ADR-0003）
- WT 的 WSL profile 不入映射——机器派生值走 fragment 渲染（ADR-0004）

## 验收清单

- [ ] validate.ps1 全绿
- [ ] 真机 `wdc verify -Quick`：dotfiles 链接断言 7 项全 OK（含 VSCode keybindings——本工单修的漏验）
- [ ] 真机跑 `pwsh scripts/inventory-machine.ps1`：dotfiles 存在性一节输出正常

## Comments

- 2026-10-21 实施（同工单 01 会话）：编辑已写盘未提交。
