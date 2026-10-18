# 上游吸收账本（ADR-0001 补充）

记录每次对 microsoft/WindowsDeveloperConfig 的检查与吸收。基线的机器可读版本在 [upstream-baseline.json](./upstream-baseline.json)，由 `scripts/check-upstream.ps1 -UpdateBaseline` 维护。

## 检查记录

| 日期 | 上游 HEAD | 结论 | 备注 |
|---|---|---|---|
| 2026-10-19 | （初始构建，见 baseline） | 建立基线 | 本仓库初始构建整体参考了上游 dev-config 与 wsl-comfort 的写法与设置集（详见 docs/research/ 与访谈 Q14 的逐项勾选） |

## 吸收记录

| 日期 | 吸收内容 | 上游来源 | 进入本仓库的位置 |
|---|---|---|---|
| 2026-10-19 | 系统设置集（R1–R11 保留项）与 winget/DSC 配置写法 | microsoft/WindowsDeveloperConfig dev-config | configs/base-windows.winget |
| 2026-10-19 | WSL 阶段化安装思路（组件→重启续跑→发行版） | 同上 steps/wsl | scripts/install-wsl.ps1 |
| 2026-10-19 | Catppuccin Mocha 终端配色（原 ComfortShell fragment 定义） | 同上 wsl-comfort | dotfiles/windows/terminal-settings.json |
