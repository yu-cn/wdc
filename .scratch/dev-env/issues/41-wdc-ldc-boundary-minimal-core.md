# 41: WDC/LDC 边界最小核心化——保留职责三件移交，终结形式统一

**What to build:** 环境主人定夺（2026-11-01 ASUS 会话）：WDC 与 LDC 是两个独立项目，各自面向对应环境优化，不刻意追求形式统一；WDC 的 WSL 内部工作全量委托 LDC。本单把工单32 建立的委托路线（LDC-0007「发行版内一切收敛走 LDC 单一实现」）走完——委托已完成约九成，`setup-ubuntu.sh` 薄委托 wrapper 还剩 5 件 WDC 保留职责，逐件归类后：3 件移交 LDC，3 件半必须留在 WDC（编排者身份决定），契约最小面永久保留。

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

**Status:** needs-triage

- [ ] **LDC 侧承接（联动前置，另单推进）**：chsh 默认 shell 进 LDC bootstrap root 段；wsl.conf systemd 进 LDC 形态分支（WSL 内核探测，写入后提示重启语义与现 WDC 实现一致）；docker 组 usermod 归位 LDC 自身 sudo 流程
- [ ] **LDC 侧联动**：回看 v0.10.0 两仓 tag 锚点——若无契约联动而同号同日，在 dev-standard §46 补澄清句（同号同日仅限联动变更）；主作者位在 LDC，WDC 侧同步拷贝
- [ ] `scripts/wsl/setup-ubuntu.sh` root 角色：撤 chsh 段、撤 wsl.conf 段、撤 docker 组段——root 阶段收敛为「apt 引导依赖 → LDC 定位 → 委托 install-packages.sh」
- [ ] `scripts/wsl/setup-ubuntu.sh` user 角色：本就只剩身份带过 + LDC 定位 + 委托 bootstrap，核对无需变更
- [ ] `scripts/wsl/probe.sh` 的 WSL 特有两键（默认 shell / systemd）随移交调整：断言职责归 LDC verify，WDC 侧只保留「LDC verify 退出码透传」验收面
- [ ] `scripts/install-wsl-env.ps1` 阶段注释同步改写（"WDC opinion: systemd/shell/docker组" 移除），防文档与实现互相撒谎
- [ ] 迁移验收：新机/既有机重跑 bootstrap 全绿，`wdc verify` 含委托段全绿，新机一条命令全自动体验不回退

## Comments

- 2026-11-01（ASUS 会话）：立单。边界决策出自与环境主人的架构讨论——直接起因是本会话 fzf 修复中暴露的实现统一反例（pwsh 侧模仿 bash 侧 fzf 集成从未生效）。环境主人同期明确「LDC 侧 agent 不用管，专注 WDC 侧」，故本单 WDC 侧条目可执行、LDC 侧两条列为联动前置由主人另行安排。Status 取 needs-triage：WDC 侧规格已完整但整体被 LDC 承接阻塞，排期由主人定。
