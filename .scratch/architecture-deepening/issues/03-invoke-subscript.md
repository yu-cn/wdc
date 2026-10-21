Status: ready-for-human

# 03 · Invoke-Subscript 子脚本深模块 + 阶段编号收敛

## 问题

「跑 pwsh 子脚本 → 转发输出 → 判退出码 → Write-Step」四步样板 8 处重复、细节微妙不一；同源症状：阶段编号漂移（`Stage 0/5…4/5`、`5/6…6/6`、`Summary 4/4` 混存，README 称六个阶段还漏数了移除清单）。

## 方案（已实施）

- `scripts/lib/common.ps1` 增 `Invoke-Subscript`（Label / Path / ArgumentList → bool；转发输出与判码进实现，接口只留成败）
- bootstrap-main.ps1 六处、install-dotfiles.ps1 的 WT 渲染一处改调；阶段统一编号 **1/7–7/7**，Summary 去伪编号
- README「六个阶段」勘正为七个（补移除清单）
- **wdc.ps1 不改**：其三处直调刻意保留实时流式输出（bootstrap/verify 运行数分钟，捕获-转发会失去实时性）——与样板场景的接口诉求不同，非遗漏

## 验收清单

- [x] validate.ps1 全绿
- [x] 真机 bootstrap 重跑：七阶段编号顺次输出、行为与此前一致（幂等零变更）
- [ ] `wdc sync` 冒烟：bootstrap 输出仍实时逐行可见

## Comments

- 2026-10-21 实施（ZCode 会话，refactor commit 0097606）；同会话真机收口：validate 全绿；`bootstrap -NoElevate` 全绿 113s——阶段 1/7…7/7 顺次、Summary 各步 `[OK] validate.ps1`/`install-languages.ps1` 等 Invoke-Subscript 口径输出正常、幂等收敛。
- 剩余一项：`wdc sync` 冒烟会弹 UAC，本会话无法点击，留给环境主人任一次日常 sync 顺手核验（wdc.ps1 未改动，直调路径行为无变化——此项属回归确认，不阻塞归档判断）。
