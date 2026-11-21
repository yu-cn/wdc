# v1 对照研究：本机现状 × WDC 声明面 × microsoft/WindowsDeveloperConfig

> 2026-11-21，v1-program Phase 1 产物（纲领见 `.scratch/v1-program/spec.md`）。基线取证：`.scratch/inventory-LETH-20261121.md`。原则：参照上游不盲从（ADR-0001；2026-11-07 封卷——无跟随义务，按需一次性吸收实践）。

## 一、本机（LETH）基线快照（Phase 0 实测 2026-11-21）

**健康面**：`wdc status` 全绿（仓库与 origin 一致 / dotfiles 零漂移 / 身份生效 / WSL 就位）；`wdc verify -Quick` 6/6 全绿（含 LDC 透传）；audit 已声明未装=0。

**自装面**：`wdc audit` 自装未声明 67 项——样例头部全为个人软件（aDrive / 钉钉 / 夸克 / Typora / 百度网盘 / B站 / 豆包 / 飞书 / PotPlayer / UniGetUI），inventory 另见 JetBrains Toolbox + CLion + DataGrip（自留地红线工具）。**结论：自装面≈纯机器自留地，无「应吸收进声明」的漏网**（67 项全表主人扫一眼确认即可，若有想通用化的另票）。

**本日已清理**（v1-program Phase 0，推荐方案经纲领批准）：uv 双装——`~/.local/bin/{uv,uvx,uvw}.exe` 三件删除，`which uv` 解析归 winget 版（0.13.8 在装，0.13.9 可升）；Cascadia per-user 残留——2 字体文件 + 2 条 HKCU 注册值删除。`wdc clean-legacy` 复证零发现。

**在册欠账**：① mise 升级被 shim 锁挡（[[winget-portable-shim-lock]]）——**待主人在无 MCP 普通终端跑 `wdc sync`**（今日多笔提交本就触发全量一次）；② pre-install 快照 manifest 已预标记存量机（skipped-already-converged，机制语义正确）；③ 版本滞后面（delta / gh / Chrome 可升级）——useLatest 正常节奏，下次全量收敛自消化。

## 二、三方对照（分面）

### A. 系统设置（27 项注册表 opinion）

wdc 的设置集血统即来自上游（2026-10-19 吸收 R1–R11 + 两反转：恢复通知、**关**远程桌面）。上游 Full 的差异项（开 RDP+防火墙规则、Sudo 配置向、更多任务栏微调）属 **opinion 分歧而非能力差距**——互逆项已有意为之。**无吸收项。**

### B. 包与工具链

| 上游装 | wdc 现状 | 判定 |
|---|---|---|
| .NET SDK 10 | 无 | 维持出局（通用核心判据——某台机器不需要即出局） |
| Oh My Posh | Starship | 维持（三 shell 统一已定） |
| Node LTS + **nvm** | Node 归 **mise** | 维持（wdc 更优：多语言单管理器，Windows/WSL 同工具） |
| Python + uv | Python 归 uv | 已对等 |
| Copilot CLI | 无 | 拒绝（gh 扩展生态按需自装，未入通用核心） |
| Cascadia Mono NF | JetBrainsMono NF | 已定（Cascadia 包除名史，今日清残） |
| 其余（Git/gh/VSCode/WT/PowerToys/fzf 家族…） | 同源子集 + lazygit/delta/Everything | 已对等或超出 |

### C. WSL 侧

上游 wsl-comfort（zsh/Starship/fzf/rg/fd/bat/eza/zoxide/jq/主题终端）⊂ LDC 委托面（apt / gh / Docker Engine / uv / mise / Starship / Linux dotfiles / 默认 shell，双发行版×双架构 CI）。**无吸收项**（上游无 Docker、无 arm64）。

### D. 机制与工程（真正的前沿对照面）

| 机制 | 上游做法 | wdc 现状 | 判定 |
|---|---|---|---|
| 幂等模型 | check→apply→verify 逐步命令 | winget configure 声明式 + 幂等重跑 CI 实证 | 维持（声明式更贴 ADR-0009 + 现有 verify 断言体系） |
| **undo / 退出** | 每项设置文档化 undo + 一键 uninstall（不恢复原值） | undo 表 + pre-install 快照已落（**比上游强：快照可恢复原值**）；`wdc exit` 工单03 | **吸收中（W-A）** |
| **覆盖前防御** | Terminal settings.json 语法错即停，不覆盖坏文件 | 渲染直接覆盖（.bak 兜底但静默） | **吸收（W-B1 渲染前 JSON 预检）** |
| **CI 密度** | "CI-tested" per-PR 矩阵 | validate per-push + fresh-machine **月度**（fresh clone→bootstrap→幂等重跑零变更） | **半吸收（W-B2 三腿：exit 回归腿 / clean-legacy 零发现腿 / 快照覆盖腿）；触发密度维持月度+dispatch（release 前 dispatch 必跑）——per-PR 全量 bootstrap 的 runner 成本与信号衰减不划算，另议才翻** |
| 供应链 | aka.ms + Authenticode 签名 + pinned SHA-256 | raw 分发 + `WDC_TAG` 钉版 | 维持（2026-11-01 在档定夺：成本不匹配） |
| 并发锁 / 重启续跑 | Global mutex + %ProgramData% 状态续跑 | `Global\WdcBootstrap` + 收敛账本 + 续跑任务（自清不循环） | 已对等（锁思想本就吸收自上游） |
| Workloads 子命令层 | 有（TypeScript/Java/Go/Rust…单命令装子集） | 无 | **维持后移**（工单40 ③b：2026-11-01 价值分析在档——自用无痛点，价值依赖开源独立决策；除非主人翻案） |
| AI/GPU 工具链 | 有（GPU 检测装 PyTorch/Ollama） | 无 | **维持后移**（③c 在档：与 uv 项目级钉版冲突，Ollama curl|sh 已够） |
| manifest 单一来源 | manifest.yml 驱动一切流程 | 散源 + 一致性校验断言（Get-WdcDomains / dotfiles-map / cli-parity 各自单源） | **维持后移**（③d 在档：定版前夕动结构风险不对称） |

## 三、吸收候选表（Phase 2 范围冻结用）

| # | 项 | 建议 | 状态 |
|---|---|---|---|
| 1 | W-A 退出收口（ADR-0010 + `wdc exit` T1/T2 + verify-exit） | 做 | 纲领已批，续用 exit-mechanism 工单03 |
| 2 | W-B1 渲染前 JSON 语法预检（坏文件停+报警） | 做 | 纲领已批 |
| 3 | W-B2 CI 三腿（exit 回归 / clean-legacy 零发现 / 快照覆盖） | 做 | 纲领已批 |
| 4 | W-B2b fresh-machine 触发密度（月度→per-PR） | **不做**（维持月度+dispatch，release 前 dispatch 必跑） | 本表推荐，主人可翻 |
| 5 | ③b Workloads / ③c AI GPU / ③d manifest | **不翻案**（2026-11-01 定夺在档，立项不撤销待真实场景） | 维持 |
| 6 | W-D 试验场回归环 + **ASUS 双机终验** | 做（ASUS 终验补进 Phase 4 门槛——2026-11-01 首次 1.0.0 讨论的「双机终验」五步在档，本次闭合） | 纲领补充 |

## 四、1.0.0 承诺面（对 2026-11-01 首次讨论的闭合）

上次缓发定夺「距离 1.0.0 还有些差距」，拟过五步（承诺面盘点 / 归档卫生 / 双机终验 / 文档 / 发版）。本次纲领逐项闭合：**承诺面**=「一次性配置 + 显式更新/回归 + 完整退出（exit/undo 表/快照/verify-exit）+ 漂移合法不纠察」；**归档卫生**=v1-program spec 落 `.scratch/`；**双机终验**=W-D 回归环（LETH）+ ASUS 终验（Phase 4 门槛）；**文档**=README/GLOSSARY/undo 表/ADR-0009..0010/cli-parity 一致；**发版**=CHANGELOG 收节 + 效果优先 notes + tag/release 同会话。
