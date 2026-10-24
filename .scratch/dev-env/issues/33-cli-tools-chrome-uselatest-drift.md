# 33: cli-tools 域 Chrome（useLatest）在 winget configure test 报漂移而版本一致

**What to build:** 查明 `configs/cli-tools.winget` 的 Chrome 项（`useLatest: true`）为何在 `winget configure test` 判「未处于描述的配置状态」并收敛。已取证（2026-10-24，LETH）：本机已装 156.0.8078.48 = winget 源 manifest 最新版（`winget show Google.Chrome` 同值），版本并非漂移点——useLatest 的 test 判定细节待查（test 对「最新」的判定可能走 `winget upgrade` 可升级列表而非版本比对，或与包登记形态有关）。影响：verify-machine.ps1 第 6 组 `cli-tools 漂移=0` FAIL（工单32 迁移验收时暴露；与该工单改动无关）。

**Blocked by:** None

**Status:** ready-for-human

## Comments

- 2026-10-24（LETH 会话，工单32 迁移验收时发现）：候选方向供定夺——a) 查实 useLatest 在 test 语义下的判定源（upgrade 列表/manifest 比对/ARP 登记），按结论决定是否本机处置；b) 若属 useLatest 固有抖动（自更新管道 vs 源索引节奏差），考虑 Chrome 项去 useLatest 改钉版本或接受 verify 偶发红 + triage 规矩。坑4 补充候选：validate 退出码 1=仅警告的实录语义是否同族适用于 configure 的此形态。
