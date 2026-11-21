# 01 pre-install 快照 + 逐项 undo 表（层0）

Status: ready-for-agent
Type: task

## 内容

两部分：

1. **undo 表文档**（零行为风险，先行）：`docs/undo-table.md`——base-windows.winget 全部注册表单元逐项列出（name / keyPath / valueName / WDC 值 / undo 动作），undo 动作分类：删值（WDC 前不存在该值）/ 置 Windows 默认（该值原本存在但不同）。微软 WindowsDeveloperConfig 同款做法（每项设置文档化 how to undo）。
2. **pre-install 快照**（bootstrap 代码变更）：首次 apply base-windows 域前，若 marker `%LOCALAPPDATA%\wdc\pre-install\.done` 缺失——对全部去重 keyPath 逐个 `reg export` 落 `pre-install\<slug>.reg`，写 marker（ADR-0004 机器本地模式，幂等一次性）。exit 还原时快照优先（delete+import），无快照降级走 undo 表默认值并明示。

## 验收

- [x] docs/undo-table.md 覆盖 base-windows 全部注册表单元（数量与 .winget 断言一致），undo 动作逐项有据（27/27；删值 22 / 置默认 5；策略键 4 处标空键连删）
- [ ] 快照步骤入 bootstrap apply 路径（提权回合内），marker 守卫，重跑不重复导出
- [ ] 存量机（无快照可采）行为：marker 直接落「快照缺席」标记而非假快照
- [ ] validate 全绿；fresh-machine CI 下次跑即覆盖新路径

## Comments

- 2026-11-21 文档半边先行落地（快照代码半边待做——本会话无法安全跑提权 bootstrap 全量验证，留待后续会话或 CI）。undo 表与 .winget 单元一一同源对齐（同分组同序）；`fDenyTSConnections` 客户端版默认即 1 属「反转项天然幂等」，表内注明快照才是还原手动开过 RDP 的正解。
