# CLI parity 契约（wdc / ldc 双仓同源）

> **双仓同源拷贝**：本文在 yu-cn/ldc 与 yu-cn/wdc 各存一份，**主作者位在 LDC**（与
> docs/dev-standard.md 同款统筹模式）——改契约先改 LDC 侧提交，WDC 侧同步拷贝；不一致以
> LDC 为准。dev-standard-guard 周检本文件双仓一致；两仓 validate 各自断言「本仓实现命令表
> == 下方契约注释行」，把「改实现忘改契约」从周检提前到提交时。

## 命令表

<!-- wdc-commands: status sync verify plan triage audit upgrade-git log help version -->
<!-- ldc-commands: status sync verify plan audit triage log help version -->

| 命令 | wdc | ldc | 备注 |
|------|-----|-----|------|
| status | ✓（默认，裸命令同义） | ✓（默认，裸命令同义） | 机器可读出口见下 |
| sync | ✓ `-Full` 强制全量 | ✓ `--full` 强制全量 | 快速路径两仓同构（wdc 工单42 / LDC ADR-0021） |
| verify | ✓ 默认 `-Quick`，`-Full` 全量 | ✓ 默认 `--quick`，`--full` 全量 | 旗标风格随各壳惯例（pwsh switch / GNU 长项） |
| plan | ✓（sync 流投影） | ✓（安装面逐项投影） | 皆只读零变更、恒 exit 0 |
| triage | ✓ | ✓ | dotfiles 落点漂移分流（交互式） |
| audit | ✓ | ✓ | 清单准入对账（只读恒 exit 0） |
| upgrade-git | ✓ | — | Git for Windows 专用通道（坑14） |
| log | ✓ `-Lines N` | ✓ `[N]` 位置参数 | wdc 强类型 / ldc 校验正整数 |
| help | ✓ `help [命令]` | ✓ `help <topic>` | 总览或单命令详解 |
| version | ✓ `-v/--version` | ✓ `-v/--version` | git describe |

## 共用 UX 约定

- **裸命令 = 只读快照**（秒级）；长操作/改状态一律显式子命令
- **打错子命令**：「你是不是想输…」——唯一前缀命中优先，再看编辑距离 ≤2
- **`-h` 语义**：`help/-h/--help` 出总览或单命令详解；**子命令后接 `-h/--help` 出该命令详解**
- **机器可读出口**：`wdc status -Json` / `ldc status --json`——单行紧凑 JSON（键口径对齐：
  `tool/version/command`、`repo{state,ahead,behind}`、`dotfiles{drift_count,drift_items[]}`、
  `identity{ok}`、`last_bootstrap{log,verdict}|null`、`hints[]`；布尔出 `true/false`）。
  wdc 用 `-Json`（pwsh switch）是绑定器约束：pwsh 把 `--json` 当未知参数拒绝；wdc 的
  pwsh/Git Bash 包装层把 `--json` 归一为 `-Json` 转发，人机两面等价
- **长操作完成提示**：sync 收尾 BEL（终端响铃/闪烁）——切走窗口结束有感知
- **Tab 补全**：词表解析自实现脚本单一来源（wdc：解析 `$wdcCommands` 行；ldc：解析
  `LDC_COMMANDS` 行），绝不在 shell 配置抄列表——改词表一处生效
- **退出码**：`0` 成功 · `1` 失败；ldc `2` = 有待办手工步骤（sync/bootstrap）· wdc `3` =
  收敛锁占用（sync）。verify 口径全仓统一 0/1/2（dev-standard §4），CLI 层的 3 是 wdc sync 专用

## 治理

- 改命令表/UX 约定：先改本文件（LDC）→ 同批拷贝 WDC → 两仓各自的 validate 断言绿
- guard 周检（两仓 dev-standard-guard.yml 的同源比对循环）覆盖本文件
- 实现侧新增/删改子命令而忘改本文件：本仓 validate 即红（不用等周检）
