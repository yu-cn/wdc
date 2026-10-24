Status: needs-triage

# 01 · verify 漂移段未提权会话整域假警报（LETH 2026-10-25 实录）

## 问题

未提权会话跑 `verify-machine.ps1`（非 -Quick），6/6 漂移段对 **base-windows 与 cli-tools 整域报 FAIL**：全部 27 个注册表单元 + 全部 18 个包单元逐一「未处于」，exit 1；而 editors 域（纯用户级单包）通过。假警报淹没真漂移，非 Quick 验收在普通 PS 会话必红。

取证（同日同会话）：

- 注册表抽样 16 项中 15 项与声明完全一致（含 verify 第 2 节独立断言过的 LongPaths/fDenyTSConnections 等——winget 却判它们「未处于」，实锤评估失败≠真漂移）。
- 包全在位且多数为最新；`winget upgrade` 全量核对后，cli-tools 真漂移仅 2 项：`Git.Git 2.55.0.5→2.56.0.3`、`GitHub.cli 2.103.0→2.103.2`（后者当日已 winget 直升收敛）。
- 两个失败域的共同点：含需提权的单元（base-windows 有 5 个 HKLM 键，cli-tools 全机器级安装）；configs/base-windows.winget 头注亦写明「统一由 bootstrap 提权后应用」。bootstrap 上下文里验收天然提权，verify 单独在未提权会话跑时暴露。

## 待定夺

漂移段断言语义怎么改（规则属于仓库，agent 不擅定）：

- **A（推荐）**：漂移段入口检测提权态；未提权时打印 INFO「未提权会话对含 HKLM/机器级单元的域评估不可靠」，相关域断言降为 SKIP（退出码不因假警报红），提权重跑才计入 FAIL。
- **B**：verify 启动自提权——只读验证默认弹 UAC，改变脚本性质，不推荐。
- **C**：仅文档化（README/FAIL hint 注明漂移段需提权会话），脚本不动——假警报仍在，只是可解释。

## 验收清单

- [ ] 方案经环境主人定夺并记录
- [ ] 按定夺实施；未提权 -Quick 与提权全量两种路径验收全绿（提权全量受 Git 2.56 升级牵制，见 Comments）
- [ ] verify-machine.ps1 的漂移 FAIL hint 同步更新（现 hint 未提示提权因素）

## Comments

- 2026-10-25 记录（ZCode 会话）。当日已顺手收口的三件事：repo-local `git config core.hooksPath .githooks`（FAIL hint 自带修法）；`Hidden 2→1` 还原为声明值（唯一注册表真漂移；若环境主人刻意放开过「受保护的操作系统文件」，反转此处置并把仓库声明改 2）；gh 升 2.103.2。**Git 升级未动**——坑14 全套流程（bash 占用/MSYS 转换/提权读符号链接），需环境主人配合窗口，按 collaboration.md 坑14 剧本执行；在那之前 cli-tools 即使提权重跑也会因 useLatest 真红。
- 2026-10-25（LETH 会话二）：Git 已按坑14 升至 2.56.0.3（schtasks 路线，上一条 Comments 的「Git 升级未动」与「cli-tools 即使提权重跑也真红」均已过时）。当日二次 `wdc sync` 全绿：bootstrap 7/7、verify -Full 三域漂移全 0——且该次 verify 跑在**未提权**会话，**假警报未复现**（提权 bootstrap 刚跑完的状态下）。取证记录（15/16 注册表项一致却整域报「未处于」）仍然成立，假警报定性为状态依赖的间歇形态；A/B/C 方案仍待环境主人定夺，本单保持 needs-triage。
