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
- [ ] release notes 按「效果优先」纪律：承诺面置顶（一次性配置+显式更新/回归+完整退出+漂移不纠察）、存量机影响正面回答（Chrome/VSCode 扩展两让位的迁移指引）、行为变化进已知事项（Stage 4 瘦身/exit 新命令/clean-legacy 新命令）
- [ ] 双仓版本口径：**v1.0.0 同号同日**（LDC 85f3171 姿态对齐批=联动变更成立，dev-standard §5）；tag/release 同会话收口（协作规矩）

## 遗留观察（不阻塞，主人另定）

- LDC desktop-apps 的 Chrome：Linux 桌面无预装浏览器（Ubuntu Firefox snap 语境不同），未随 WDC Chrome 判例除名——是否对齐待主人定夺
- exit T3（WSL 档）：LDC 侧卸载器未备，后续版本另议

## 发布执行序（主人指令后同会话）

① fresh-machine dispatch 确认绿 → ② WDC CHANGELOG 收节 commit → ③ LDC CHANGELOG 收节 commit（WSL 内）→ ④ 双仓 tag v1.0.0 → ⑤ 双仓 release（--latest、四段笔记、效果优先）→ ⑥ 工单04 归档
