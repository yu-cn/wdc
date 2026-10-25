# 02: 验证瘦身——冒烟 WSL 交界面化 + 日常 sync 收尾降 Quick + winget 开销优化

**What to build:** 按 `.scratch/v070-parity/spec.md` 第 6 项，收窄 WDC 验证面（主人 2026-10-26 拍板「都做」+「winget方面的优化也要做」）。背景事实（当日拆解，证据 run 40216164784，783s）：verify 第 5 组已是委托（probe = LDC-0007 WDC 保留职责 + `ldc verify --quick`），无重复实现；重复在冒烟 Stage 6（LDC bootstrap 安装全程，LDC 容器冒烟已覆盖本体收敛）；日常漫长的大头是 winget 三处（validate ~1min + apply 评估 ~2-4min + verify 全量三域 test ~3min ≈ 6-10min），WSL 段秒级。逐项施工面：

1. **冒烟 WSL 段交界面化**——fresh-machine workflow 的 WSL 阶段不再委托 LDC bootstrap 安装全程；保留 WSL 启用/装 Ubuntu + wsl.conf systemd + 默认 shell=bash + 身份带过 + probe.sh 断言（WDC 保留职责面），LDC 本体安装验证让位给 LDC 自己的容器冒烟。交界面仍是唯一真机前检验点——LDC_SMOKE 适配类问题（同日实录）须继续可被抓住。
2. **日常 sync 收尾降 Quick**——`wdc sync` 的收尾 verify 从全量降为 `-Quick`（秒级）；`wdc verify -Full` 入口与提示语保留（大改后/心里没底用）。bootstrap 各阶段内部不动。
3. **winget 开销优化（研究先行，实测定案）**——候选：① `wdc sync`/bootstrap 在「pull 无新提交」时跳过 Stage 2 validate（CI 已把关同一 commit；有更新才跑）；② Stage 3 apply 前置 `winget configure test` 探测、零漂移域跳过 apply（收益取决于 test/apply 评估成本差——实施时先在已收敛机器计时实测再定）；③ 与第 2 项合并计算日常 sync 总耗时基线对比。跳过条件是「同一 commit CI 已把关」，不是取消本地把关（dev-standard 钩子纪律不破）。

**Blocked by:** 01（同版本排队；按并行规则当前会话收口后认领）

**Status:** ready-for-agent

- [x] 冒烟 WSL 段交界面化（代码落地：setup-ubuntu.sh SKIP_LDC 开关 + install-wsl-env CI 传参 + verify 第 5 组 CI 降 SKIP——LDC 本体收敛归 LDC 容器冒烟）；待冒烟 run 验证后入档
- [x] `wdc sync` 收尾 verify = -Quick；`wdc verify -Full` 提示语对齐；帮助/README 同步
- [x] winget 优化实测数据入档（本机已收敛机器 test vs apply 计时、validate 跳过收益）+ 方案定案落地——「前置 test 探测零漂移跳 apply」实测否决（apply 自带同量级评估，双倍评估负优化）；定案 = 「pull 无更新跳 validate（-SkipValidate 通道，恒传：sync 走到 bootstrap 时 HEAD==origin/main 必然成立）」+「收尾 -Quick」两项
- [ ] 本机 `wdc sync` 实测耗时较基线（6-10min）明显下降——全程实测需 UAC（人在场），组件已分别实测（-Quick 收尾秒级 / -SkipValidate 省 validate ~1min）
- [ ] validate.ps1 全绿 + CI run id 入档本票 Comments

## Comments

- 2026-10-26（ASUS 会话立票）：主人拍板「都做」（冒烟交界面化 + 日常 sync 降 Quick）并补充「winget方面的优化也要做」；原散票 `.scratch/verify-slim/spec.md` 并入本票后删除。基线数据：冒烟 783s 中 Stage 3 winget apply 469s / Stage 6 WSL ~195s / Stage 2 validate 50s；已收敛机器 wdc sync ≈ 6-10 分钟（全在 winget）。与漂移方向判定（工单 01 第 2 项）无依赖冲突，可并行施工但按并行规则一个会话一个仓库串行认领。
- 2026-10-26（同会话实测）：**「零漂移跳 apply（前置 test 探测）」实测否决**——本机（未提权会话）base-windows 单域 test 106s；apply 秒回系未提权写 HKLM 直接失败、非真实数据（bootstrap 的 apply 走提权子回合）。方向性结论：apply 自带与 test 同量级的逐单元评估，前置 test 是双倍评估的负优化；winget 单域 ~100s 评估是引擎固有成本，绕不开。定案：只做「pull 无更新跳 validate」与「sync 收尾 -Quick」两项。
