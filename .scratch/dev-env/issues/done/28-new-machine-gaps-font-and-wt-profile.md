# 28: 新机首跑缺口——Nerd 字体缺失 + WT 双 PowerShell profile

**What to build:** 环境主人新机首跑实录（2026-10-21）暴露两个通用核心漏项（老机器自留地泄漏，从未进声明）：

1. **字体缺失**：WT 模板 `profiles.defaults.font.face = "Cascadia Mono NF"`——NF（Nerd Font）变体不随 Windows/WT 附带（裸机只带非 NF 的 Cascadia Mono），starship/图标全变豆腐块。修复：cli-tools 域新增 `Microsoft.CascadiaCode`（2404.23 起含 Mono NF/Code NF 字族）。
2. **WT 双 PowerShell profile**：模板的 PowerShell profile 带的是老机器当年生成的随机 GUID（{3618cdc9-…}），新机器上 WT 动态生成的 PowerShell 用规范 GUID（{574e775e-4f2a-5b96-ac1e-a2962a402336}）——WT 按 GUID 去重覆盖，GUID 不同即并存两只。修复：模板与 defaultProfile 改用规范 GUID，任何机器上恰好覆盖动态生成那只。cmd（{0caa0dad-…}）与 Windows PowerShell（{61c54bbd-…}）本就是规范 GUID，无需动。

**Blocked by:** None

**Status:** ready-for-agent

- [x] cli-tools.winget：新增 Microsoft.CascadiaCode（含 NF 字族）
- [x] terminal-settings.json：PowerShell profile GUID 与 defaultProfile 改为规范 {574e775e-…}
- [x] validate 全绿（schema + 静态）
- [x] 新机复验：重跑 bootstrap 后字体不再是豆腐块、WT 只有一只 PowerShell profile（老机器同步后同样恰好一只：动态被模板覆盖）

## Comments

- 2026-10-21（主机会话）：双 profile 成因的判据——WT 的 settings.json profile 与动态生成 profile 同 GUID 则覆盖、异 GUID 则并存；owner 机器从未见双只因 {3618cdc9-…} 那只本就是该机 WT 首跑时生成后写穿进模板的（工单14 同族现象的良性版）。
- 2026-10-22（LETH会话）：「老机器同步后同样恰好一只」半边复验（LETH 侧）——今日 sync 后 WT settings.json 符号链接在位（直指仓库模板）；profile 全景恰一只 PowerShell（规范 GUID {574e775e-…}，defaultProfile 同指），旧随机 GUID {3618cdc9-…} 无残留；CMD/Windows PowerShell 保持规范 GUID，Azure 隐藏如常——「动态被模板覆盖」按判据成立。ASUS 侧同核待其下次会话；勾选框（新机复验，含字体半边）仍开放。
- 2026-10-23（LETH会话）：VM 新机侧复验（虚拟真跑 WDC-VM01，全记录见工单30 注释）——**字体半边成立**：cli-tools 域应用后 JetBrainsMono NerdFont 全家 96 文件入 C:\Windows\Fonts 并注册（NF/NFM/NFP/NL 四族 × 全字重），WT 模板 `font.face=JetBrainsMono NFM` 无豆腐块之忧；**profile 半边成立**：WT settings.json 符号链接直指仓库模板，defaultProfile={574e775e-…}（规范 GUID），profile 全景恰一只 PowerShell + CMD/Git Bash/Ubuntu WSL（静态声明）+ Azure/Windows PowerShell hidden——新机「双 profile 并存」未复现，「动态被模板同 GUID 覆盖」在全新 WT 上如判据成立。至此字体半边有新机证据、老机半边 LETH 有据（ASUS 待核），勾选与否归主人。
- 2026-10-23（LETH会话）：主人定夺「VM 能够当做真机」——「新机复验」项凭 VM 证据勾选（字体 96 文件 + WT 恰一只 PowerShell，见上条），归档收口。ASUS 侧老机一眼同核属锦上添花（与 LETH 同模板同机制），随时可补记。
