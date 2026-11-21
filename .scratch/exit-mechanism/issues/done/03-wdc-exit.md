# 03 wdc exit 三档退出命令（层2）

Status: done
Type: task
Blocked by: 01, 02

## 定夺点（2026-11-21 主人经 v1-program 纲领批准）

1. **T2 语言栈分界 = A 声明面全退数据面不动**：卸 configs 全部声明包（含 mise/uv 本体）；runtime/venvs/cache/node_modules 数据不碰
2. **默认档 = T2 完整退出**（`-KeepTools` 显式降 T1）
3. **无快照降级语义 = 恢复 Windows 默认值并在输出明示**（存量机拿不出原值，宁诚实不冒充）

## 内容

T1/T2 两档实现（**T3 含 WSL 档后移 Phase 3 与 LDC 联动**——LDC 卸载器未备）：T2 = VSCode 扩展逐个卸载 → 声明包逐 Id 卸载（坑7 多版本 0x8A150016 逐版本显式）→ 注册表还原（快照优先**逐值**还原、绝不整键删除防连坐共享键；存量机降级 undo 表）→ dotfiles 落点处置（有 `.bak` 还原原文件、无则删除）→ `clean-legacy -Fix` → 机器状态删除 → 退出断言（verify-exit）。安全：默认打印全计划后确认；非交互无 `-Yes` 自动预演零变更；T2 确认后自重启提权子回合（bootstrap 同款）。ADR-0010 落案（含拒绝项：整键 reg import 还原/退出时差分快照/数据面全清/T3 本期做/独立 verify-exit 子命令）。

## 验收

- [x] ADR-0010 立案（含定夺记录 + 拒绝的替代）
- [x] T1/T2 实现 + 退出断言；幂等（失败重跑收尾——脚本自身设计）
- [x] fresh-machine CI 加 exit 腿（bootstrap → 重跑幂等 → exit -Yes → 断言状态清）——**下次月度跑或 dispatch 实证**
- [x] wdc 命令面四件套同步 + validate 全绿；CHANGELOG 记账（cli-parity LDC 先行 09f8d1f）
- [x] LETH 预演实测（非交互无 -Yes = 计划预演零变更）

## Comments

- 2026-11-21 开票即收（W-A 批）。执行体 `scripts/exit-wdc.ps1`；undo 表数字勘误同步（实为删值 20 / 置默认 7，此前误记 22/5）。真机 T2 全量执行留 W-D 回归环（装了退→退了装）做——本机直跑会拆掉工作环境，须按纲领在回归环里成对执行。
