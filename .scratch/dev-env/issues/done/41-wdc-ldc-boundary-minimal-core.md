# 41: WDC/LDC 边界最小核心化——保留职责三件移交，终结形式统一

**What to build:** 环境主人定夺（2026-11-01 ASUS 会话，词条化于 GLOSSARY「双边最优化」）：WDC 与 LDC 是两个独立项目，目标函数是**双边各自最优化**——Windows 侧用 Windows 母语、Linux/WSL 侧用 Linux 母语，统一不是目标而是工具，仅在服务委托实质处保留最小面；WDC 的 WSL 内部工作全量委托 LDC。本单把工单32 建立的委托路线（LDC-0007「发行版内一切收敛走 LDC 单一实现」）走完——委托已完成约九成，`setup-ubuntu.sh` 薄委托 wrapper 还剩 5 件 WDC 保留职责，逐件归类后：3 件移交 LDC，3 件半必须留在 WDC（编排者身份决定），契约最小面永久保留。

**保留职责分类（本单的核心决策记录）：**

| 保留职责 | 判定 | 理由 |
| --- | --- | --- |
| apt 引导依赖（git/curl/ca-certificates/gnupg） | **留** | 鸡生蛋：LDC 未 clone 时只有编排者能装 git——不可委托 |
| LDC 定位（clone + fetch/`pull --ff-only`，分叉中止交人工） | **留** | 编排者职责 + 防分叉护栏 |
| 身份带过（.gitidentity 拷入 WSL home） | **留** | 凭据从 Windows 带入，天然跨界 interop，非「Linux 内部配置」 |
| 验收面（`verify-ldc.sh` 只透传 LDC verify 退出码） | **留** | 委托不静默失败的保险——管结果不管实现，永久保留 |
| chsh 默认 shell | **移交** | 代码注释自认「LDC 未接管 chsh 前保留在包装层」的临时位 |
| wsl.conf systemd 自启 | **移交** | LDC 本就形态感知（LDC_SKIP_DOCKER / 桌面域 SKIP）——「WSL 形态下确保 systemd」归 LDC 形态分支更内聚 |
| docker 组 usermod | **移交后自然消失** | 根因是 WDC root 直调缺 SUDO_USER；LDC 走自身 sudo 语境无此问题 |

**「形式统一」三分法（同批定夺）：** 实现统一该破（实证：fzf 0.74.5 无 `--powershell`，pwsh 侧模仿 bash 集成的实现从未生效，wdc cc46108 改 PSReadLine 手工接线才是各环境母语；starship.toml「原样移植」双份同理，独立后允许各自演化）。发版对齐可松绑（dev-standard §46 本义仅联动变更对齐版本号；v0.10.0 双仓同号同日是否属无契约联动的过度执行，需回看 tag 锚点确认后处置）。契约统一保留最小面：退出码语义 + `LDC_TODO` 机器标记（ADR-0007/2026-10-26）——独立性 ≠ 失联，没有它 WSL 侧未收敛时 WDC 是瞎的。

**Blocked by:** LDC 侧承接三件移交项（环境主人另行安排；LDC 侧清单见下，规范主作者位在 LDC）

**Status:** done

- [x] **LDC 侧承接（联动前置，另单推进）**：chsh 默认 shell 进 LDC bootstrap root 段；wsl.conf systemd 进 LDC 形态分支（WSL 内核探测，写入后提示重启语义与现 WDC 实现一致）；docker 组 usermod 归位 LDC 自身 sudo 流程
- [x] **LDC 侧联动**：回看 v0.10.0 两仓 tag 锚点——若无契约联动而同号同日，在 dev-standard §46 补澄清句（同号同日仅限联动变更）；主作者位在 LDC，WDC 侧同步拷贝
- [x] `scripts/wsl/setup-ubuntu.sh` root 角色：撤 chsh 段、撤 wsl.conf 段、撤 docker 组段——root 阶段收敛为「apt 引导依赖 → LDC 定位 → 委托 install-packages.sh」
- [x] `scripts/wsl/setup-ubuntu.sh` user 角色：本就只剩身份带过 + LDC 定位 + 委托 bootstrap，核对无需变更
- [x] `scripts/wsl/probe.sh` 的 WSL 特有两键（默认 shell / systemd）随移交调整：断言职责归 LDC verify，WDC 侧只保留「LDC verify 退出码透传」验收面
- [x] `scripts/install-wsl-env.ps1` 阶段注释同步改写（"WDC opinion: systemd/shell/docker组" 移除），防文档与实现互相撒谎
- [x] 迁移验收：新机/既有机重跑 bootstrap 全绿，`wdc verify` 含委托段全绿，新机一条命令全自动体验不回退

## Comments

- 2026-11-01（ASUS 会话）：立单。边界决策出自与环境主人的架构讨论——直接起因是本会话 fzf 修复中暴露的实现统一反例（pwsh 侧模仿 bash 侧 fzf 集成从未生效）。环境主人同期明确「LDC 侧 agent 不用管，专注 WDC 侧」，故本单 WDC 侧条目可执行、LDC 侧两条列为联动前置由主人另行安排。Status 取 needs-triage：WDC 侧规格已完整但整体被 LDC 承接阻塞，排期由主人定。
- 2026-11-01（ASUS 会话）：主人重申并强化原则为「尽可能达到 Windows 和 Linux（含 WSL）双边最优化」——本单 What-to-build 已按目标函数口径改写，原则词条化进 GLOSSARY「双边最优化」（紧邻「机器对等」）。WDC 侧按此口径的存量扫描：已母语化=fzf（PSReadLine）、渲染拷贝、VSCode/gitconfig 双份各自裁剪；形式统一残留候选=lazygit（去留等实测）、make（ezwinports，无 Makefile 场景即残留，无害可留）；starship.toml 双份按新原则允许各自演化（漂了不修）。
- 2026-11-01（ASUS 会话，实施收口）：主人解除「LDC 侧不动」限制，三 Phase 同会话走完。**Phase A**（LDC 工单12，006c2e5/188c02e/32bd1ad/732e47c）：三件进 LDC install-packages.sh 机器形态段——root 直调缺 SUDO_USER 的根因由新增 `LDC_USER` 契约补（ADR-0007 补记，WDC wrapper 显式传 WSL 默认用户）；`docker_skipped()` 自判定取代 WDC 透传（env 保留外部覆盖语义）；LDC verify 扩六组补 shell/systemd 两键。**Phase B**（e8bb745）：setup-ubuntu.sh 三段撤除、probe.sh 退役（git rm）、verify-ldc.sh 纯透传、install-wsl-env.ps1 注释改写。**Phase C**：v0.10.0 锚点回看=双仓零契约联动仍同号同日（WDC 功能批×LDC 治理批）→ dev-standard §46 补澄清句「同号同日仅限联动变更」（LDC 主笔、WDC 同批拷贝 29e1b4a）；顺手项三件随 LDC 工单12 落地（FZF_CTRL_T_OPTS bat 预览 / cli-tools 去 tree / apt 索引 24h 跳过）。
- 2026-11-01（ASUS 会话，迁移验收实录）：wdc sync 全量 388s 全绿 exit 0——新委托链逐行实证：机器形态三件幂等 SKIP（ubuntu 已是 bash / wsl.conf 已启用 / docker 组已在组，全由 LDC 单一实现核销）、`[SKIP] apt-get update - 索引 24h 内已更新（本地判定）` 顺手项实弹命中、「WDC opinion」包装层文案消失；verify 第 5 组只余 `[OK] WSL LDC verify --quick` 退出码透传，两键断言由 LDC verify 6/6 段承接（双 OK）；bashrc 重渲染后交互 shell 实际导出 FZF_CTRL_T_OPTS（断效果断言）。LDC 容器冒烟双架构+handoff 全绿（run 41319222742，dispatch 实跑）。实施坑实录：UNC 跨界编辑两次削掉 bash 脚本可执行位（100755→100644）——git update-index --chmod=+x + chmod 双修后 amend，后续跨侧编辑 bash 脚本后须核对 mode。
