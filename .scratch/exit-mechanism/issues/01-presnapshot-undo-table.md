# 01 pre-install 快照 + 逐项 undo 表（层0）

Status: ready-for-agent
Type: task

## 内容

两部分：

1. **undo 表文档**（零行为风险，先行）：`docs/undo-table.md`——base-windows.winget 全部注册表单元逐项列出（name / keyPath / valueName / WDC 值 / undo 动作），undo 动作分类：删值（WDC 前不存在该值）/ 置 Windows 默认（该值原本存在但不同）。微软 WindowsDeveloperConfig 同款做法（每项设置文档化 how to undo）。
2. **pre-install 快照**（bootstrap 代码变更）：首次 apply base-windows 域前，若 marker `%LOCALAPPDATA%\wdc\pre-install\.done` 缺失——对全部去重 keyPath 逐个 `reg export` 落 `pre-install\<slug>.reg`，写 marker（ADR-0004 机器本地模式，幂等一次性）。exit 还原时快照优先（delete+import），无快照降级走 undo 表默认值并明示。

## 验收

- [x] docs/undo-table.md 覆盖 base-windows 全部注册表单元（数量与 .winget 断言一致），undo 动作逐项有据（27/27；删值 22 / 置默认 5；策略键 4 处标空键连删）
- [x] 快照步骤入 bootstrap apply 路径（提权回合内），marker 守卫，重跑不重复导出（Stage 3 base-windows 域 apply 前挂 `Export-WdcPreInstallSnapshot`；marker=manifest.json）
- [x] 存量机（无快照可采）行为：marker 直接落「快照缺席」标记而非假快照（skipped-already-converged，判据=收敛账本在位）
- [ ] validate 全绿；fresh-machine CI 下次跑即覆盖新路径（本地两分支实测过：Fresh 15 keyPath 全导出+marker 幂等；LETH 存量机分支正确落缺席标记——CI 腿待下次月度跑实证）

## Comments

- 2026-11-21 文档半边先行落地（快照代码半边待做——本会话无法安全跑提权 bootstrap 全量验证，留待后续会话或 CI）。
- 2026-11-21 续（同日）：代码半边落地。`Export-WdcPreInstallSnapshot` 入 common.ps1（`-Fresh` 仅测试/诊断，生产无参调用）；keyPath 自 configs/base-windows.winget 单一来源提取（含空格路径模式取整行）；reg export 缺席键=还原信息记 manifest。本地实测：Fresh 分支 15 keyPath 全导出（缺席 0）、marker 重跑幂等跳过；LETH 默认目录实测存量机分支（收敛账本在位→INFO+skipped manifest，已正确预标记本机）。bootstrap 挂点待提权全量或 CI 实证（勾选留 CI 项）。
