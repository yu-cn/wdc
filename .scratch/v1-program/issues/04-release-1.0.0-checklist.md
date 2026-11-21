# 04 v1.0.0 发布 checklist（门槛制——不达标不发；发布动作待主人 explicit 指令）

Status: ready-for-human
Type: task

## 门槛（P4）

- [ ] fresh-machine 全环 CI 绿（run 44917510844 实证中：bootstrap → 幂等重跑 → 快照断言 → clean-legacy 零发现 → exit 全退断言 → 退了→装重装；后续任一跑全绿即过）
- [ ] **ASUS 双机终验**（主人动作）：ASUS 上 `wdc sync`（收敛到含本日全部批次的 HEAD）→ `wdc verify -Quick` 全绿 → `wdc clean-legacy` 报告可接受（uv/Cascadia 类发现按 LETH 同款处置）
- [ ] LETH 本地 W-D 回归环（可选，主人窗口）：真跑 `wdc exit`（T2）→ 重新 bootstrap → verify 全绿——存量机降级路径的终极实证；CI 已覆盖 fresh-machine 半场
- [ ] LDC 侧 fresh-container CI 绿（P3 批 85f3171 后首跑）
- [ ] 文档一致终查：README / GLOSSARY / undo-table / ADR-0003/0009/0010 / cli-parity / docs/research/v1-comparison.md
- [ ] CHANGELOG 收节 v1.0.0（Unreleased → 版本节；compare 链续 v1.0.0...HEAD）
- [ ] release notes 按「效果优先」纪律：承诺面置顶（一次性配置+显式更新/回归+完整退出+漂移不纠察）、存量机影响正面回答（**链接 [docs/upgrade-v1.md](../../../docs/upgrade-v1.md) 存量机升级指引**：一条 `wdc sync` + Chrome/VSCode 两让位行为表 + 建议手动两件 + pwsh 7.7 可选迁移）、行为变化进已知事项（Stage 4 瘦身/exit 新命令/clean-legacy 新命令/WT 裸 pwsh）
- [ ] 双仓版本口径：**v1.0.0 同号同日**（LDC 85f3171 姿态对齐批=联动变更成立，dev-standard §5）；tag/release 同会话收口（协作规矩）

## 里程碑加持（「里程碑版本」应有的额外面——2026-11-22 主人定调补充）

- [ ] **README 里程碑翻新**：对外门面整体校——「一条命令得到什么」清单已变（扩展/Chrome 让位后）；首段后可加「1.0.0 承诺面」一句话；demo 产物与现命令集的差异说明（重录为可选项）
- [ ] **SemVer 1.0.0 语义宣告**：CHANGELOG 前言与 release notes 明示「1.0.0 起 SemVer 完整生效（此前 v0.x 破坏性走 MINOR）」——里程碑的正式含义
- [ ] **坑档收编两条新实录**（collaboration.md）：① winget 拒绝跨安装技术升级且退出码 0 假绿（MSI→MSIX，2026-11-21 LETH）；② pwsh 数组 `-notmatch` 返回不匹配行数组非空恒真（CI 断言腿 run 44917510844 实录）
- [ ] **钉版回退预案**入 release notes 已知事项一句：出问题可 `WDC_TAG=v0.14.0` 钉旧版重跑（get.ps1 既有能力）
- [ ] 归档卫生：exit-mechanism 工单02 随 ASUS 终验收口；v1-program 工单全归档（本票发布时收）
- [ ] 可选（主人定）：demo.gif 重录（现 gif 为旧命令集 wdc/verify 循环，1.0.0 新面貌 plan/exit/clean-legacy）

## 遗留观察（不阻塞，主人另定）

- LDC desktop-apps 的 Chrome：Linux 桌面无预装浏览器（Ubuntu Firefox snap 语境不同），未随 WDC Chrome 判例除名——是否对齐待主人定夺
- exit T3（WSL 档）：LDC 侧卸载器未备，后续版本另议

## 发布执行序（主人指令后同会话）

① fresh-machine dispatch 确认绿（**全环须带 `-f full-loop=true`**：`gh workflow run fresh-machine.yml -f full-loop=true`——例行月度只跑四腿，2026-11-22 主人定夺瘦身） → ② WDC CHANGELOG 收节 commit → ③ LDC CHANGELOG 收节 commit（WSL 内）→ ④ 双仓 tag v1.0.0 → ⑤ 双仓 release（--latest、四段笔记、效果优先）→ ⑥ 工单04 归档
