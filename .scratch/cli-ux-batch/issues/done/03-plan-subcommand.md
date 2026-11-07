# 工单03：wdc plan 干跑预演（sync 流投影 v1）

Status: done

## 背景

ldc 有 `ldc plan`（干跑预演，只读零变更——sudo/重跑前先看一眼）；wdc sync 会弹 UAC 跑
分钟级 bootstrap，「先看一眼再决定」在 Windows 侧价值只会更大（双仓体验对齐明文立意）。

## 内容

- v1 = sync 流决策投影（不复制 ldc plan-machine.sh 的安装面逐项比对——那是 250 行独立
  脚本，wdc 侧投影 winget 安装面需 `configure test` 逐域解析，另立后续票）：
  - 仓库：fetch（有界）→ 三态（一致 OK / 落后 PLAN「将拉取 N 提交（--ff-only）」/
    领先或分叉 FAIL「sync 将在此中止交人工」）
  - bootstrap 快速路径判定（同 sync 只读逻辑）：命中 → SKIP「快速路径（秒级，不弹 UAC）」；
    未命中 → PLAN「bootstrap 全量（将请求一次 UAC）」+ 原因（有新拉取 / 账本不符 / 工作区脏）
  - verify：INFO「-Quick 收尾（秒级）；三域漂移详查 wdc verify -Full；dotfiles 漂移 wdc triage」
- `$wdcCommands`、用法头注释、help 总览+detail 同步；退出码 0（预演不是断言，对齐 ldc plan）
- 依赖工单01 的有界 fetch 助手

## 验收清单

- [ ] 三态仓库投影正确（一致/落后/领先模拟）
- [ ] 快速路径判定与 sync 实际行为一致（同判定条件同输出方向）
- [ ] 只读零变更（跑前后 `git status` 干净）
- [ ] help/README 门面同步
- [ ] validate 全绿

## 实录

- 真机：`wdc plan` 三段投影正确（仓库 OK / bootstrap PLAN+原因「收敛账本缺失/无效」与当日 bootstrap FAIL 判定行一致 / verify 口径）；只读零变更（跑前后 git status 干净）；恒 exit 0；validate 全绿（cceb6b0）
