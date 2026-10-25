# 上游吸收账本（ADR-0001 补充）

记录每次对 microsoft/WindowsDeveloperConfig 的检查与吸收。基线的机器可读版本在 [upstream-baseline.json](./upstream-baseline.json)，由 `scripts/check-upstream.ps1 -UpdateBaseline` 维护。

## 检查记录

| 日期 | 上游 HEAD | 结论 | 备注 |
|---|---|---|---|
| 2026-10-19 | （初始构建，见 baseline） | 建立基线 | 本仓库初始构建整体参考了上游 dev-config 与 wsl-comfort 的写法与设置集（详见 docs/research/ 与访谈 Q14 的逐项勾选） |
| 2026-10-21 | b39c86809c | 工单07 维度清理 | 删除 check-upstream 的注册表键维度（从未参与差异输出、还把我们的键灌进上游集合污染基线，YAGNI），`-UpdateBaseline` 重建纯包维度基线（31 包） |
| 2026-10-22 | fb564611cf | 工单30 对照分析 | 浅克隆 main 一手核对 wsl 调用纪律与提权结构（两流程全程提权、wsl-comfort RunOnce 续跑注释明写 elevated）；基线未重建（纯包维度无变化） |
| 2026-10-25 | fb564611cf（不变） | 包维度抓取修复 + 基线重建 | 10-21「31 包」表述失实——旧基线实为全文件正则噪声（URL 片段与 DSC 资源类型，零个真包 ID：正则要求 X.Y/Z 带斜杠，winget 包 ID 无斜杠匹配不上）；改为抓包目录真源 steps/packages.ps1 的 Get-DevConfigPackageCatalog，重建为 22 个结构化包 ID（其中 VCRedist 按架构变量补两变体） |

## 吸收记录

| 日期 | 吸收内容 | 上游来源 | 进入本仓库的位置 |
|---|---|---|---|
| 2026-10-19 | 系统设置集（R1–R11 保留项）与 winget/DSC 配置写法 | microsoft/WindowsDeveloperConfig dev-config | configs/base-windows.winget |
| 2026-10-19 | WSL 阶段化安装思路（组件→重启续跑→发行版） | 同上 steps/wsl | scripts/install-wsl.ps1 |
| 2026-10-19 | Catppuccin Mocha 终端配色（原 ComfortShell fragment 定义） | 同上 wsl-comfort | dotfiles/windows/terminal-settings.json |
| 2026-10-22 | wsl.exe 有界调用纪律（安装类新控制台不捕获 / 查询类临时文件重定向+关 stdin+硬超时杀 / 只看退出码）与全程提权单回合结构 | dev-config steps/wsl.ps1·_environment.ps1、wsl-comfort install.ps1 | scripts/lib/common.ps1（Wait-WdcProcess/Invoke-WslBounded）、install-wsl.ps1、bootstrap-main.ps1 |
