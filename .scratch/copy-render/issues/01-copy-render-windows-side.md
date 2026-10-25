# 01: dotfiles 渲染拷贝对等实施（Windows 侧全量）

**What to build:** 按 `.scratch/copy-render/spec.md`（引用 LDC ADR-0015，见上方背景）把 Windows 侧 dotfiles 安装从符号链接整体切换为渲染拷贝。开工前先跑 `git -C <repo> fetch && git log --oneline -3` 确认基线，并通读 LDC 同名实现（github.com/yu-cn/ldc，commits `30d7454` feat + `dcf442e` fix——fix 那笔是 CI 抓到的幂等教训，必读）。逐文件施工面：

1. **scripts/lib/dotfiles-map.ps1**——保持「纯数据与纯函数、不依赖 common.ps1」性质，新增逐项状态判定纯函数（建议 `Test-DotfileInSync -Source -Target`：`Get-FileHash` 比对；返回 ok/absent/drift 三态，落点为符号链接=drift 即迁移信号）。这是状态判定的单一来源，install/verify/triage/status/profile 六方共读。
2. **scripts/install-dotfiles.ps1**——`Install-Dotfile` 重写：同内容（hash 相等）幂等跳过；不同内容 `Get-BackupPath` 轮转备份后 `Copy-Item`；落点是符号链接（现役机器的既有形态）直接 `-Force` 移除不备份（链接本体可再造，指向内容不受影响）。`ubuntu.ico` 拷贝段与 `~/.wdc` 指针段原样保留。**施工须知（LDC 实录教训，run 40211476066）**：身份文件等「仅首次」类判据必须以产物存在性为准（`Test-Path` 产物），绝不以「落点是不是链接」为判据——渲染后落点恒为实体文件，形态判据会把自家渲染物误当待接管原始文件，第二遍 bootstrap 重复 CHANGED 破坏幂等。
3. **scripts/verify-machine.ps1**——Phase 1 断言改走 `Test-DotfileInSync` 逐项内容比对（提示语指向 wdc triage）；删除「dotfiles 模板与 HEAD 一致（防写穿）」断言（写穿不再可能）；hooksPath 与图标资产断言保留。注意 `Get-FileHash` 对缺失文件抛错——用状态函数的 absent 分支兜住，别让断言炸出异常栈。
4. **scripts/triage-dotfiles-drift.ps1**——漂移检测从 `git status --porcelain -- dotfiles` 改为地图逐项内容比对；`-DryRun` 保留；吸收 = `Copy-Item <落点> <模板源>` 后**显式 pathspec commit**（既有红线不变：绝不 git add -A）；还原 = `Copy-Item <模板源> <落点>`（丢弃机器改动，交互确认后不可逆——与旧 checkout 语义对齐）。未跟踪文件分支可删（仓库内模板不受机器影响，`??` 只会是真实新文件）。
5. **scripts/wdc.ps1**——status 的「dotfiles 漂移」行改地图逐项内容比对计数（>0 提示 wdc triage）；「仓库尚无 commit」分支可删（不再依赖 HEAD 比对）。
6. **dotfiles/windows/pwsh-profile.ps1 + dotfiles/windows/bashrc**——漂移即时提示（工单24 产物）语义平移：新增内容漂移信号（经 `~/.wdc` 指针 dot-source `scripts/lib/dotfiles-map.ps1` 后逐项 hash 比对——7 个小文件毫秒级）；「未提交模板编辑」的 git porcelain 提示保留（工单24 Comments 已定性：那是「改完记得 commit」红线提醒，不是误报）。两路信号合并为一行或两行黄字，观感自定，要求：零漂移机器开终端必须静默。
7. **文档对齐**——AGENTS.md：坑6 重写（写穿→直改落点，仓库不再受污染，triage/verify 新口径）、「禁 git add -A」红线保留、坑11/坑35 补一句根治标注；GLOSSARY.md：写穿/分流词条按新语义改；README.md 两处符号链接表述；**scripts/inventory-machine.ps1** 有一处 LinkType 引用（安装形态盘点）——改读内容状态。
8. **WSL 侧不动**：委托契约（verify-ldc.sh → ldc verify --quick）在 LDC v0.6.0 上已自洽；bashrc 模板（dotfiles/windows/bashrc）中 vp/fzf 等布局路径本就无硬编码问题，不动。

**Blocked by:** None

**Status:** ready-for-agent

- [x] dotfiles-map.ps1 状态函数（六方共读单一来源）
- [x] install-dotfiles.ps1 渲染化（含幂等教训落地）
- [x] verify-machine.ps1 内容断言 + 防写穿断言退役
- [x] triage-dotfiles-drift.ps1 平移（吸收/还原/DryRun）
- [x] wdc.ps1 status 漂移口径
- [x] profile + bashrc 漂移提示改内容比对（保留未提交编辑提醒）
- [x] 文档对齐（AGENTS 坑6 / GLOSSARY / README / inventory）
- [x] 本机实测：迁移 → verify 全绿 → 漂移链路双向 → 第二遍 bootstrap 零 CHANGED
- [ ] CI 锚点：validate（windows-latest）+ fresh-machine 冒烟 run id 入档
- [ ] 发布由主人指令触发（feat → MINOR）——主人 2026-10-26 已指令：全绿后发 v0.6.0

## Comments

- 2026-10-26（LDC 侧会话代立）：工单依据 LDC v0.6.0 发布与 ADR-0015 WDC 条款代立，实施环境预期为 Windows 开发机（pwsh 在位、pre-commit 硬关可正常把关）。语义争议一律以 LDC `docs/adr/0015-copy-render-not-symlink.md` 原文为准；本票只做施工面展开。注意 dev-standard §6 并行规则：动工前确认无其它会话在 WDC 上。
- 2026-10-26（ASUS 会话实施）：施工面全部落地，本机实测通过。实录要点：
  - 迁移实录：7 落点 SymbolicLink → 渲染拷贝。CHANGED 行要报「原指向」须在 Remove-Item **前**取 `$item.Target`——删除后 FileInfo 失效读空（首跑实测踩中，已修）。
  - 幂等：install-dotfiles 二遍 7×OK 零 CHANGED。本仓无「仅首次」形态判据（身份段本就以 Test-Path 产物为准、~/.wdc 指针以内容比对为准），LDC 教训（run 40211476066）自然落地。
  - 漂移链路双向实测：手改落点 → verify FAIL（点名 bashrc）→ wdc status FAIL → triage -DryRun 出 diff → 还原(r) 重渲染回绿；吸收(a) → 回写模板 + pathspec commit（pre-commit validate 全绿）→ 软回退清场。备份轮转 .bak.1/.2/.3 实测创建（测试产物已清，历史 .bashrc.bak 不动）。
  - 提示链路（profile/bashrc 双信号）：pwsh profile 原生 dot-source 毫秒级，漂移行点名漂移项；bash 经一次性 `pwsh -NoProfile`（实测启动 ~220ms）换单一事实源。**两个 bash 坑实录**：① `pwsh -Command` 会把后续参数并进命令串，`$args` 不可靠——仓库路径改环境变量传入；② `VAR=x var=$(pwsh…)` 前缀赋值**不进命令替换子壳**（pwsh 读到空值、报错被 2>/dev/null 吞、漂移行静默失踪）——须独立 `export` 行。修复后带漂移 source 实测双信号齐发、收敛归零静默。
  - 工单第 5 条「仓库尚无 commit」分支查无此笔（当前 wdc.ps1 无该分支；Get-AheadBehind 的 rev-list 失败守卫属仓库差距语义，保留未动）。
  - 工单第 7 条「坑11/坑35」：坑11/坑15 已补根治标注；「坑35」查无此坑——collaboration.md 仅 15 条坑，spec 所指「工单35」（reparse 双路径痛）随渲染拷贝一并消除，无独立坑词条可标注。
  - 吸收语义注意：整文件回写会把模板**未提交编辑一并卷进** pathspec commit（旧模型 checkout+commit 同语义，实测踩中后软回退清场）——吸收前先收口模板编辑（profile/bashrc 第二路提示正是为此）。
  - 完整 bootstrap 提权回合未跑（UAC 需人在场）；「第二遍 bootstrap 零 CHANGED」以 dotfiles 阶段（install-dotfiles.ps1）多遍幂等实测替代覆盖，下次 wdc sync 完整收敛顺带复核。
  - 验收清单外的顺手项：triage 的 diff 加 `-c core.autocrlf=false` 静音行尾告警（--no-index 比对与行尾无关）。
  - **CI 冒烟锚点实录**：validate run 40216099975 绿（push 兜底全过）；fresh-machine run 40216164784 红在 Stage 6——**既有缺口、与本工单无关**：工单32 的 LDC 委托（7216068，10-24）上线后冒烟从未跑过（上次绿 10-22 跑的还是桩 user 阶段），CI 上身份刻意占位 → LDC bootstrap PENDING exit 2 → 包装层按真问题拒绝容忍 → Stage 6 红。本工单改动面（Stage 7 dotfiles 渲染）在该 run 全绿：全新机器零迁移直渲染、WT settings 落点备份轮转、starship 落点目录创建、ubuntu.ico、~/.wdc 指针全过。修复：setup-ubuntu.sh user 阶段 CI 语境（GITHUB_ACTIONS）设 `LDC_SMOKE=1`（LDC ADR-0004 冒烟降级语义，真机不设），fix 单列提交后重触发冒烟锚新 run id。
