# 33: cli-tools 域 Chrome（useLatest）在 winget configure test 报漂移而版本一致

**What to build:** 查明 `configs/cli-tools.winget` 的 Chrome 项（`useLatest: true`）为何在 `winget configure test` 判「未处于描述的配置状态」并收敛。已取证（2026-10-24，LETH）：本机已装 156.0.8078.48 = winget 源 manifest 最新版（`winget show Google.Chrome` 同值），版本并非漂移点——useLatest 的 test 判定细节待查（test 对「最新」的判定可能走 `winget upgrade` 可升级列表而非版本比对，或与包登记形态有关）。影响：verify-machine.ps1 第 6 组 `cli-tools 漂移=0` FAIL（工单32 迁移验收时暴露；与该工单改动无关）。

**Blocked by:** None

**Status:** ready-for-human

## Comments

- 2026-10-24（LETH 会话，工单32 迁移验收时发现）：候选方向供定夺——a) 查实 useLatest 在 test 语义下的判定源（upgrade 列表/manifest 比对/ARP 登记），按结论决定是否本机处置；b) 若属 useLatest 固有抖动（自更新管道 vs 源索引节奏差），考虑 Chrome 项去 useLatest 改钉版本或接受 verify 偶发红 + triage 规矩。坑4 补充候选：validate 退出码 1=仅警告的实录语义是否同族适用于 configure 的此形态。
- 2026-10-24（续取证）：三方版本一致仍报「未处于」——`chrome.exe` 文件版本、`winget list` 登记版本、`winget show` 源 manifest 版本同为 156.0.8078.48。排除「版本比对」与「ARP 登记滞后」两个假设；useLatest 的 test 判定与版本无关，指向 DSC 资源对 useLatest 的 get 实现（或 upgrade 可用性检查）。低成本路径：观察一个 Chrome 自更新周期（源索引跟进后复测），自愈则定性为节奏差抖动、按 b) 记「接受」处置；不自愈再深挖 DSC 实现。
- 2026-10-24（ASUS 会话，工单32 机器对等复验时取证）：ASUS 同域报漂移但形态不同——configure test「未处于」的两单元为 Git（装 2.55.0.5，源 manifest 2.56.0）与 GitHubCLI（装 2.103.0，源 2.103.2），均为真实版本滞后；Chrome 本轮为满足态。对照本单 LETH 实录（三方一致仍报「未处于」）：test 判定对「有升级可用」的单元确实报漂移——ASUS 两例属可被 `winget upgrade` 消化的真滞后，非 useLatest 假阳性同款；Chrome 假阳性仍是独立未解问题。ASUS 两例不在工单32 迁移任务内处置，留待主人定夺升级节奏。
