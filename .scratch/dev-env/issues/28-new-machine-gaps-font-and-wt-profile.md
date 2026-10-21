# 28: 新机首跑缺口——Nerd 字体缺失 + WT 双 PowerShell profile

**What to build:** 环境主人新机首跑实录（2026-10-21）暴露两个通用核心漏项（老机器自留地泄漏，从未进声明）：

1. **字体缺失**：WT 模板 `profiles.defaults.font.face = "Cascadia Mono NF"`——NF（Nerd Font）变体不随 Windows/WT 附带（裸机只带非 NF 的 Cascadia Mono），starship/图标全变豆腐块。修复：cli-tools 域新增 `Microsoft.CascadiaCode`（2404.23 起含 Mono NF/Code NF 字族）。
2. **WT 双 PowerShell profile**：模板的 PowerShell profile 带的是老机器当年生成的随机 GUID（{3618cdc9-…}），新机器上 WT 动态生成的 PowerShell 用规范 GUID（{574e775e-4f2a-5b96-ac1e-a2962a402336}）——WT 按 GUID 去重覆盖，GUID 不同即并存两只。修复：模板与 defaultProfile 改用规范 GUID，任何机器上恰好覆盖动态生成那只。cmd（{0caa0dad-…}）与 Windows PowerShell（{61c54bbd-…}）本就是规范 GUID，无需动。

**Blocked by:** None

**Status:** ready-for-agent

- [x] cli-tools.winget：新增 Microsoft.CascadiaCode（含 NF 字族）
- [x] terminal-settings.json：PowerShell profile GUID 与 defaultProfile 改为规范 {574e775e-…}
- [x] validate 全绿（schema + 静态）
- [ ] 新机复验：重跑 bootstrap 后字体不再是豆腐块、WT 只有一只 PowerShell profile（老机器同步后同样恰好一只：动态被模板覆盖）

## Comments

- 2026-10-21（主机会话）：双 profile 成因的判据——WT 的 settings.json profile 与动态生成 profile 同 GUID 则覆盖、异 GUID 则并存；owner 机器从未见双只因 {3618cdc9-…} 那只本就是该机 WT 首跑时生成后写穿进模板的（工单14 同族现象的良性版）。
