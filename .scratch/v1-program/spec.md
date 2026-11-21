# spec · v1-program：WDC 1.0.0 产品化改造纲领（试验场 = LETH）

## 定夺

主人 2026-11-21：本机当试验场，详细分析现状、对照 microsoft/WindowsDeveloperConfig 与 wdc 声明面，系统改造为满意产品，全部完成后发 1.0.0 正式版；LDC 双仓保持 + 姿态对齐（方案 A）；T2 语言栈分界按推荐「声明面全退、数据面不动」（实施前可否决）。纲领全文经 plan 模式批准。

## 阶段

- **P0 试验场基线**（✅ 2026-11-21 完成）：status/verify -Quick 全绿、audit 67 项自装≈纯自留地、inventory 落档 `.scratch/inventory-LETH-20261121.md`；欠账清理——uv 双装（删 `.local/bin` 三件，解析归 winget 版）、Cascadia per-user（2 文件+2 注册值删）、clean-legacy 复证零发现；mise shim 锁欠账**待主人无 MCP 终端跑 `wdc sync`**；工单40 ③b/c/d 维持 2026-11-01 后移定夺（价值分析在档）。
- **P1 三方对照研究**（✅ 2026-11-21 完成）：[docs/research/v1-comparison.md](../../docs/research/v1-comparison.md)——对照判定与吸收候选表（6 项：3 项纲领已批、1 项推荐不做、③b/c/d 不翻案、ASUS 终验补进 Phase 4 门槛）。**Phase 2 范围=候选表 #1/#2/#3/#6**（主人翻案另裁）。
- **P2 改造批**：
  - W-A 退出收口：ADR-0010 + `wdc exit` T1/T2（T3 视 LDC 承接）+ verify-exit + 命令面四件套（cli-parity LDC 先行）——续用 `.scratch/exit-mechanism/issues/03-wdc-exit.md`
  - W-B 稳健性：渲染前 JSON 预检（install-dotfiles 渲染前语法守卫，坏文件停+报警）；CI 三腿（fresh-machine 加 exit 回归腿 / clean-legacy 零发现腿 / 快照覆盖腿）
  - W-D 试验场回归环：全量 sync → verify -Full → clean-legacy 零发现 → `wdc exit` T2 → 重新 bootstrap 全绿（装了退、退了装闭环）
- **P3 LDC 姿态对齐**（跨仓，方案 A）：LDC 镜像 ADR-0009 手术（新 ADR + README 首段 + GLOSSARY + sync 叙事降格）；契约面不动；LDC validate 在 WSL 内跑 + fresh-container 绿；版本——LDC 若仅口径对齐→双仓同号同日（§5 联动成立）。
- **P4 1.0.0 发布（门槛制）**：
  - [ ] 退出路径齐备（exit + undo 表 + 快照 + verify-exit）；W-D 回归环绿
  - [ ] **ASUS 双机终验**（sync + verify + clean-legacy 各绿）
  - [ ] P1 候选表勾选项全部落地或显式另票
  - [ ] CI 全绿（validate / fresh-machine 含新腿 / dev-standard-guard）
  - [ ] 文档一致（README / GLOSSARY / undo-table / ADR-0009..0010 / cli-parity）
  - [ ] CHANGELOG 收节 v1.0.0；notes 效果优先纪律；明示承诺面
  - [ ] 双仓版本口径定 + tag/release 同会话收口

## 边界

- 红线不变：退出不碰机器自留地；禁 `git add -A`；`~/.gitidentity` 不入产出物
- ③b/c/d 不翻案不入本期；aka.ms/签名管线维持拒绝（在档定夺）
- LDC 侧改动走 LDC 仓规矩（validate 在 WSL 内跑；UNC 编辑后核对文件位/行尾）
