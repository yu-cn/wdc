# wdc exit——一次性配置的退出面（声明面全退、数据面不动）

ADR-0009 把 WDC 定位为「一次性配置 + 显式更新/回归」后，退出路径成为产品缺口的最后一块（对照上游 microsoft/WindowsDeveloperConfig：有 uninstall 一键 + 每项 undo 文档，但明说 "previous settings are not restored"）。主人 2026-11-21 定夺三定夺点：T2 语言栈分界=**声明面全退、数据面不动**；默认档=**T2 完整退出**；无快照降级=**恢复 Windows 默认值并明示**（存量机拿不出 pre-install 原值，宁诚实不冒充）。前置件已落：pre-install 快照（工单01）、undo 表（docs/undo-table.md）、签名清扫（工单02 `wdc clean-legacy`）。

## 决策

- **`wdc exit [-KeepTools] [-Yes]`**，执行体 `scripts/exit-wdc.ps1`。T2 完整退出（默认）：VSCode 扩展逐个卸载 → 声明包逐 Id 卸载（同 ID 多版本 0x8A150016 逐版本显式，坑7）→ 注册表还原 → dotfiles 落点处置 → `clean-legacy -Fix` 清扫 → 机器状态删除。T1 状态退出（`-KeepTools`）：只删机器状态（`%LOCALAPPDATA%\wdc`、`~/.wdc`、死计划任务），环境原样。
- **还原基准优先级**：pre-install 快照 > undo 表 Windows 默认值。快照还原**逐值**进行——绝不 `reg delete` 整键（Explorer\Advanced 等共享键上会连坐非 WDC 值）；快照值类型不可自动还原（hex 二进制类）时降级 undo 表。存量机（快照缺席）在输出明示「恢复默认值而非原始值」。
- **交互安全**：默认打印全计划后确认；非交互（stdin 重定向，如 CI/管道）且无 `-Yes` 自动降级为**预演零变更**；T2 确认后自重启提权子回合（bootstrap 同款 `Start-Process -Verb RunAs`）。
- **红线**：机器自留地不碰（ADR-0003）；**语言数据面不动**（mise/uv 本体随声明面卸载，其 runtime/venvs/cache 留在原位）；除名≠卸载（Chrome 等已除名软件不在退出面）；`~/.gitidentity` 与仓库 clone 不删（机器数据/用户自处置）；**基础设施共享资源不卸**（VCRedist 公共运行库 + NF 字体——系统级共享，卸之即伤及无关软件与终端渲染；CI 三轮恒死于字体包卸载的字体变更广播，2026-11-22 补入）。
- **收尾断言**（verify-exit，坑11 断效果）：状态目录/指针/备份链已清——退出自身幂等，失败重跑收尾。

## 取舍

拒绝的替代：**reg delete 整键 + reg import 整键还原**（连坐共享键上的非 WDC 值——其他软件同期写入一并回滚，比不还原更糟）；**退出时再做注册表差分快照**（工单01 已在首次 apply 前落快照，退出时现场差分只能拿到 WDC 自己的值）；**连运行时数据一起退**（工单03 定夺 B，误伤 venv/cache，主人否决）；**T3 WSL 档本期做**（LDC 侧卸载器未备，Phase 3 联动另议）；**独立 verify-exit 子命令**（退出自带断言足够，不扩命令面）。
