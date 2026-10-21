Status: done

# 04 · winget 域发现：一套机制替代两套

## 问题

域清单两套机制并存：validate.ps1 / check-upstream.ps1 扫描 `configs/*.winget`；bootstrap-main.ps1 与 verify-machine.ps1 硬编码三域。新增第 4 个域文件时会被校验、被盘点，但**不被应用、不被核销**——声明与执行面静默分叉，恰是声明式仓库最忌讳的。

## 方案（已实施）

选**保守方案增强版**：顺序清单收敛为 common.ps1 的 `Get-WdcDomains` 单一来源（bootstrap Stage 3 与 verify 6/6 共读），内置与 configs/*.winget 目录的一致性校验——目录出现清单外域即抛错点名（防「校验✓ 应用✗」半接入）。目录扫描 + 顺序声明（方案 A）暂不引入：现清单仅三域，YAGNI，域增多再升级。

## 验收清单

- [x] 方案经定夺并记录（环境主人 2026-10-21 授权按推荐继续；采 B 增强版，理由如上）
- [x] 新建临时域文件能被四个脚本一致感知（或一致拒绝）——实测：`configs/zz-drift-test.winget` 使 Get-WdcDomains 抛错点名「未入清单 zz-drift-test」；validate 侧本就扫描目录
- [x] validate.ps1 全绿 + 真机冒烟——validate 全绿；Get-WdcDomains 函数级单测通过；提权 Stage 3 的回归确认并入工单 03 的 sync 冒烟同场覆盖

## Comments

- 2026-10-21 实施（ZCode 会话，工单 04-06 批次 commit）；证据链：validate 全绿、单测（域顺序 / ConvertTo-WslPath / Test-WingetExitCode 判码矩阵）、游离域文件漂移模拟抛错、verify -Quick 全绿。
