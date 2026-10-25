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

- [ ] dotfiles-map.ps1 状态函数（六方共读单一来源）
- [ ] install-dotfiles.ps1 渲染化（含幂等教训落地）
- [ ] verify-machine.ps1 内容断言 + 防写穿断言退役
- [ ] triage-dotfiles-drift.ps1 平移（吸收/还原/DryRun）
- [ ] wdc.ps1 status 漂移口径
- [ ] profile + bashrc 漂移提示改内容比对（保留未提交编辑提醒）
- [ ] 文档对齐（AGENTS 坑6 / GLOSSARY / README / inventory）
- [ ] 本机实测：迁移 → verify 全绿 → 漂移链路双向 → 第二遍 bootstrap 零 CHANGED
- [ ] CI 锚点：validate（windows-latest）+ fresh-machine 冒烟 run id 入档
- [ ] 发布由主人指令触发（feat → MINOR）

## Comments

- 2026-10-26（LDC 侧会话代立）：工单依据 LDC v0.6.0 发布与 ADR-0015 WDC 条款代立，实施环境预期为 Windows 开发机（pwsh 在位、pre-commit 硬关可正常把关）。语义争议一律以 LDC `docs/adr/0015-copy-render-not-symlink.md` 原文为准；本票只做施工面展开。注意 dev-standard §6 并行规则：动工前确认无其它会话在 WDC 上。
