Status: ready-for-agent

# 04 · winget 域发现：一套机制替代两套

## 问题

域清单两套机制并存：validate.ps1 / check-upstream.ps1 扫描 `configs/*.winget`；bootstrap-main.ps1 与 verify-machine.ps1 硬编码三域。新增第 4 个域文件时会被校验、被盘点，但**不被应用、不被核销**——声明与执行面静默分叉，恰是声明式仓库最忌讳的。

## 方案候选（实施时与环境主人 grill 定夺）

- **A**：域发现统一为目录扫描 + 显式顺序声明。注意：base-windows（字体/注册表）必须先于 cli-tools/editors 应用，顺序不能交给字母序
- **B**：保守——保留硬编码清单，加「清单与目录一致」断言，分叉即 FAIL

## 验收清单

- [ ] 方案经环境主人定夺并记录于 Comments
- [ ] 新建临时域文件能被四个脚本一致感知（或一致拒绝）
- [ ] validate.ps1 全绿 + 真机 bootstrap 冒烟

## Comments

- 2026-10-21 开单（架构评估候选 4，Worth exploring）。
