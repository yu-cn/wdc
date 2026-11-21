# 04 v1.0.0 发布 checklist（门槛制——不达标不发；发布动作待主人 explicit 指令）

Status: ready-for-human
Type: task

## 门槛（P4）

- [x] fresh-machine 全环 CI 绿（run 44930767170 全环六腿绿：bootstrap → 幂等重跑 → 快照断言 → clean-legacy 零发现 → exit 全退断言 → 退了→装重装）
- [ ] **ASUS 双机终验（发布后 48h 内补验——2026-11-22 主人定夺改序；窗口至 11-24，未到）**：ASUS 上 `wdc sync`（收敛到含本日全部批次的 HEAD）→ `wdc verify -Quick` 全绿 → `wdc clean-legacy` 报告可接受（uv/Cascadia 类发现按 LETH 同款处置）；**发现的问题以 v1.0.1 收口**，不回改 1.0.0 tag。release notes 已知事项已披露此补验安排
- [ ] LETH 本地 W-D 回归环（可选，主人窗口）：真跑 `wdc exit`（T2）→ 重新 bootstrap → verify 全绿——存量机降级路径的终极实证；CI 已覆盖 fresh-machine 半场
- [x] LDC 侧 fresh-container CI 绿（run 44934727486 四腿绿@c58d652，LDC 侧工单04 落章 437f7ce 记载）
- [x] 文档一致终查：README / GLOSSARY / undo-table / ADR-0003/0009/0010 / cli-parity / docs/research/v1-comparison.md（发布会话终查；LDC 发布前 34e3740 补改的 cli-parity clean-legacy 行由 2026-11-22 收尾批双仓拷回归位）
- [x] CHANGELOG 收节 v1.0.0（Unreleased → 版本节；compare 链 v0.14.0...v1.0.0，Unreleased 陈旧链一并修正——4e207ce）
- [x] release notes 按「效果优先」纪律：承诺面置顶（一次性配置+显式更新/回归+完整退出+漂移不纠察）、存量机影响正面回答（**链接 [docs/upgrade-v1.md](../../../docs/upgrade-v1.md) 存量机升级指引**：一条 `wdc sync` + Chrome/VSCode 两让位行为表 + 建议手动两件 + pwsh 7.7 可选迁移）、行为变化进已知事项（Stage 4 瘦身/exit 新命令/clean-legacy 新命令/WT 裸 pwsh）——v1.0.0 release 已发（2026-11-22 02:00 北京时间）
- [x] 双仓版本口径：**v1.0.0 同号同日**（A 案成立：WDC release 02:00 / LDC release 02:22，均北京时间 11-22；LDC 85f3171 姿态对齐批=联动变更成立，dev-standard §5）；tag/release 同会话收口（协作规矩，双仓各自同会话完成）

## 里程碑加持（「里程碑版本」应有的额外面——2026-11-22 主人定调补充）

- [x] **README 里程碑翻新**：「一条命令得到什么」更新（包数 18+Starship+VCRedist/编辑器段让位口径）、首跑配合四→五件事（含 CLI 选择）、1.0.0 承诺面句+装完即走锚链、钉版示例 v0.14.0（14b70a0 文案全检批）
- [x] **SemVer 1.0.0 语义宣告**：CHANGELOG 前言明示「1.0.0 起 SemVer 完整生效——破坏性走 MAJOR」（a4f72e7）
- [x] **坑档收编两条新实录**（collaboration.md）：坑19 winget 拒跨形态升级退出码 0 假绿；坑20 pwsh 数组 -notmatch 恒真
- [x] **钉版回退预案**：release notes 已知事项将写 `WDC_TAG=v0.14.0` 回退姿势（执行序⑤时落）
- [ ] 归档卫生：exit-mechanism 工单02 随 ASUS 终验收口（窗口至 11-24，待补验后收）；v1-program 工单全归档（✓ 本票 d484e84 收 04，02/03/05/06/07 均已在 done/）
- [x] demo.gif 重录（f53fe1f 终版：84 列/NSimSun CJK 等宽/提示符/快照-plan-exit 三段；字节级+帧级双验证；根因笔误实录入 commit）

## 遗留观察（不阻塞，主人另定）

- ~~LDC desktop-apps 的 Chrome：Linux 桌面无预装浏览器（Ubuntu Firefox snap 语境不同），未随 WDC Chrome 判例除名——是否对齐待主人定夺~~ **已定夺（2026-11-22 LDC 回告）：不除名——可选包组自选语义**
- ~~exit T3（WSL 档）：LDC 侧卸载器未备，后续版本另议~~ **已消解（2026-11-22 LDC 回告）：ldc exit（ADR-0024）即该退出面，无「未备卸载器」残留**

## 发布执行序（主人指令后同会话）

① fresh-machine dispatch 确认绿（**全环须带 `-f full-loop=true`**：`gh workflow run fresh-machine.yml -f full-loop=true`——例行月度只跑四腿，2026-11-22 主人定夺瘦身） → ② WDC CHANGELOG 收节 commit → ③ LDC CHANGELOG 收节 commit（WSL 内）→ ④ 双仓 tag v1.0.0 → ⑤ 双仓 release（--latest、四段笔记、效果优先）→ ⑥ 工单04 归档

**执行实录（2026-11-22，双仓各自同会话收口）**：WDC ① run 44930767170 → ② 4e207ce → ④⑤ tag 4e207ce + release 02:00 → ⑥ d484e84；LDC ① run 44934727486 → ③ 8b810cb → ④⑤ tag/release 02:22 → 归档 aa3108c。本票 checklist 内容落章由 11-22 收尾批补（归档 mv 先行、勾选后补）。
