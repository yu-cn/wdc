# 42: 收敛账本快速路径——wdc sync 已收敛时跳过 bootstrap

**What to build:** 让「机器已收敛且声明未变」的日常同步从 417s 降到秒级。现状事实（2026-11-01 ASUS 会话实测取证）：402s bootstrap 中 Stage 3（winget 三域 Apply）**376.5s = 94%**，全部是已收敛状态下的**重复验证**——18 个 winget 单元逐包对源查询最新版本（`useLatest: true` 网络成本）；重复安装并不存在（winget DSC 逐单元满足即跳、apt 逐包 `dpkg -s` 跳、渲染同内容跳、LDC 钉子版本比对跳）；Stage 6 仅 19.3s、其余全在秒级。根因是 `wdc sync` **无条件全量 bootstrap**——HEAD 与上次收敛完全一致也照跑。

**设计：**

- **收敛账本** `%LOCALAPPDATA%\wdc\converged.json`：`{ "commit": "<sha>", "at": "<ISO时间>" }`。**bootstrap.ps1 全量成功尾部写入**（`git rev-parse HEAD` 取仓库当时 HEAD）——写在 bootstrap 而非 wdc.ps1，直接跑 bootstrap 的路径同样记账（单一来源）；ValidateOnly / 中途失败不写。与 `rendered.sha256` 渲染账本同目录同模式，两本账各管各的：渲染账本管「落点↔模板」，收敛账本管「HEAD↔bootstrap」。
- **快速路径判定**（`wdc.ps1` sync 段）：fetch/pull 之后读账本——账本 commit == 当前 HEAD → `Write-Step 'bootstrap' 'SKIP' '声明未变（收敛账本=HEAD）——快速路径'`，跳过 bootstrap 直接 verify -Quick；账本落后于 HEAD（有新 pull）→ 全量 bootstrap 照旧。
- **逃生通道**：`wdc sync -Full` 强制全量收敛（param 加 switch）。
- **fail-safe**：账本缺失/损坏/JSON 解析失败 → 一律走全量 bootstrap（宁可慢，不可假绿——与「宁可误红不可静默吞待办」同哲学）；分叉/本地领先仍按现有 FAIL 语义不变。

**边界与风险：**

- 声明变更（改 configs/*、dotfiles/*）必然改变 HEAD → 必走全量，无假绿风险。
- 机器侧手工变更（手动卸载某工具等）在快速路径下不触发重收敛——由每次 sync 仍跑的 verify -Quick 结构断言兜底，深查走 `wdc verify -Full`（三域漂移本就是按需语义）。
- 提权上下文写 `%LOCALAPPDATA%`：本机提权为同用户内联（sudo Enabled=3），无跨用户问题。

**Blocked by:** None

**Status:** ready-for-agent

- [ ] bootstrap.ps1 全量成功尾部写 `converged.json`（含提权子回合成功路径；ValidateOnly 不写）
- [ ] `wdc.ps1` sync 段快速路径判定：账本==HEAD → SKIP bootstrap、verify -Quick 照跑、汇总显示秒级
- [ ] `wdc sync -Full` 强制全量（help 文本同步）
- [ ] fail-safe 实测：账本删除/写入垃圾 JSON → 自动回退全量
- [ ] `wdc help sync` / README 用法表同步快速路径语义
- [ ] 真机验收：连续两次 `wdc sync`——第二次走快速路径秒级且 verify -Quick 全绿；改一个声明文件后 sync → 全量照旧

## Comments

- 2026-11-01（ASUS 会话）：立单。起因=环境主人问「执行过程中能否已有配置快速验证跳过，而不是重复配置或安装」——事实取证后确认重复安装不存在、痛点全部在 Stage 3 重复验证（94%），且 sync 无条件全量。方案讨论三选一（立单 / 只优化 Stage 3 / 暂不动），主人选立单。Stage 3 本体优化（winget 语义层）收益不确定且耦合上游行为，不追；快速路径在 sync 层解，语义干净。LDC 侧对等项（apt-get update 24h 内跳过的本地判定）挂账主人——Stage 6 仅 19.3s，优先级低，按分工 LDC 侧由主人另行安排（工单41 同口径）。
