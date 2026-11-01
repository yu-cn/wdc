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

**Status:** done

- [x] bootstrap.ps1 全量成功尾部写 `converged.json`（含提权子回合成功路径；ValidateOnly 不写）
- [x] `wdc.ps1` sync 段快速路径判定：账本==HEAD → SKIP bootstrap、verify -Quick 照跑、汇总显示秒级
- [x] `wdc sync -Full` 强制全量（help 文本同步）
- [x] fail-safe 实测：账本删除/写入垃圾 JSON → 自动回退全量
- [x] `wdc help sync` / README 用法表同步快速路径语义
- [x] 真机验收：连续两次 `wdc sync`——第二次走快速路径秒级且 verify -Quick 全绿；改一个声明文件后 sync → 全量照旧

## Comments

- 2026-11-01（ASUS 会话）：立单。起因=环境主人问「执行过程中能否已有配置快速验证跳过，而不是重复配置或安装」——事实取证后确认重复安装不存在、痛点全部在 Stage 3 重复验证（94%），且 sync 无条件全量。方案讨论三选一（立单 / 只优化 Stage 3 / 暂不动），主人选立单。Stage 3 本体优化（winget 语义层）收益不确定且耦合上游行为，不追；快速路径在 sync 层解，语义干净。LDC 侧对等项（apt-get update 24h 内跳过的本地判定）挂账主人——Stage 6 仅 19.3s，优先级低，按分工 LDC 侧由主人另行安排（工单41 同口径）。
- 2026-11-01（ASUS 会话，实施收口）：落地（336d9ad）。三 helper 入 `scripts/lib/common.ps1`（与渲染账本同目录同模式各管各的：渲染账本管「落点↔模板」，收敛账本管「HEAD↔bootstrap」；读侧严格 40 位小写 hex 校验，任何别的形态按损坏处理返回 $null）；记账点在 `bootstrap-main.ps1` Summary 成功尾部且**仅提权上下文**——-ElevatedPass 子回合 / 管理员直跑 / 管理员终端 -NoElevate 三者 Stage 3 都真实执行过才记账，非提权 -NoElevate 半量（Apply SKIP）与 -ValidateOnly 不写（假账本会假绿，宁可慢不可假绿）。实现增补一处规格细化：快速路径判定除「账本=HEAD」外加**工作区干净守卫**（`git status --porcelain` 非空 → 全量）——验收清单「改声明文件后 sync 走全量」的未提交形态下 HEAD 不变、只判账本会漏，脏树守卫一并兜住脚本侧未提交改动。
- 2026-11-01（ASUS 会话）：真机验收全过（本机 ASUS）——① helper 单测六路径：正常写读 / 垃圾 JSON / 短 sha / JSON 数组 / 缺失 / tmp 无残留全对；② sync#1 全量 424s 全绿，提权子回合尾部 `[OK] 收敛账本 - converged.json 已记账（commit 336d9ad）`（422 字节 JSON，commit 与 `git rev-parse HEAD` 全等）；③ sync#2 快速路径 **424s → 8s**，`[SKIP] bootstrap - 声明未变（收敛账本=HEAD、工作区干净）`、verify -Quick 全绿 exit 0；④ 删账本 → sync 走全量分支（超时截断观察决策效果，账本还原后回快速路径）；⑤ 未提交改 `dotfiles/shared/starship.toml` → 全量分支（脏树守卫生效）；⑥ 干净树 + 账本=HEAD 下 `-Full` → 全量分支；⑦ `wdc help sync` / README 用法表同步。终态：sync 8s 全绿、账本在位。
