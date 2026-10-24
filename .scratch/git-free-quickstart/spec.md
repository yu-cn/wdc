# Spec：零前置快速开始（get.ps1 远程一键引导）

## 背景

README 快速开始原要求用户先手动装 Git（`winget install Git.Git` 或官网安装包）才能 clone 仓库。
git 预装在这条路径上是唯一不可替代的角色——cli-tools winget 域本来就会装 Git，
安装层（winget 配置、dotfiles 符号链接）均不依赖预装 git。

## 决策（环境主人 2026-10-25 定夺：方案 A）

消灭前置步骤本身：新增远程一键引导 `scripts/get.ps1`，照抄 `bootstrap.ps1` 已验证的
「缺运行时就地 winget 装」模式（PS7 先例）：

- 缺 Git → `winget install Git.Git`（弹一次 UAC，bootstrap 本也要提权）
- 仓库定位：`~/.wdc` 指针有效则复用（重跑 = 收敛语义）；缺省 clone 到 `~\wdc`
- 转发 `bootstrap.ps1`（PowerShell 7 装配在其内；get.ps1 自身保持 5.1 可解析 + UTF-8 BOM）

约束：`irm | iex` 属直接执行网络代码——README 给审阅链接；get.ps1 写死上游地址，
fork 用户走手动 clone 三行（README「使用与改造」补例外句）。

## 已评估并否决的替代

- **真 zip 模式**：zip 无 `.git`，bootstrap Stage 7 的 `git config core.hooksPath` 直接 FAIL
  （bootstrap-main.ps1 实证）；要给 bootstrap/wdc/verify 全量加非 git 降级支路，
  用户落在无 sync、无上游跟进的永久降级态，与「仓库是唯一主人」定位相抵。
- **纯文档改法**（winget 命令挪进快速开始代码块）：零代码但手动前置步骤仍在。

姊妹仓库 LDC 对等实施 `scripts/get.sh`（工单见 LDC 仓库 `.scratch/git-free-quickstart/`）。
