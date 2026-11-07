# 44: dotfiles 备份轮转上限（3 份封顶，删最老必报告）

**What to build:** `Get-BackupPath` 无限递增（`.bak` → `.bak.N` 无上限），双向漂移频率虽低、双机长跑会攒档；ADR-0015 承诺「机器侧内容绝不静默丢弃」与设上限存在语义张力——主人定夺（2026-11-07）：**上限 3 份**（`.bak` 本体 + 编号系列 ×2），本体永不清，编号系列超出删 mtime 最老并逐项 INFO 报告——删除动作可见，即「不静默丢弃」精神的保持形态（非「不删」）。实现：install-dotfiles.ps1 备份分支后置轮转清理；头注释语义同步。

**Blocked by:** None

**Status:** done

- [x] install-dotfiles.ps1 备份分支加轮转清理（本体永不清、编号系列 ≤2、删必逐项报告）+ 头注释更新
- [x] 演练验证（5 轮模拟双向漂移：总数恒 ≤3、`.bak` 本体在、最老先删、洞位复用正确）
- [x] CHANGELOG [Unreleased] 记 Changed + push 后 CI validate 绿

## Comments

- 2026-11-07（ASUS 会话，同批实施收口）：主人定夺 B/C 双批之 C。语义定夺要点：N=3（本体+编号×2）；「绝不静默丢弃」以删除可见保持而非不删。演练输出（5 轮）：round3 后每次删最老编号份、round5 终态 `.bak + .bak.1 + .bak.3`（洞位复用）——DRILL PASS。
