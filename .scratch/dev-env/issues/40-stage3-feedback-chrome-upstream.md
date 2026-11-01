# 40: Stage 3 无反馈期修复 + Chrome 处置定夺 + WindowsDeveloperConfig 对照超越

**What to build:** 环境主人 2026-11-01（LETH 会话）三议题批次（对齐工单 38 批次先例）。① **Stage 3 无反馈期修复**：根因=`bootstrap-main.ps1:153` `$out = & winget configure ... 2>&1` 整域同步收完后才 Write-Host（`base-windows OK` 与 `cli-tools FAIL` 之间实测隔 177 行输出、cli-tools 域 5–9 分钟静默）；修法=改流式管道 `& winget configure ... 2>&1 | ForEach-Object { Write-Host $_ }`（pwsh7 原生命令管道逐行流、Write-Host 进 transcript），并在每域发起前 Write-Step INFO 行写明单元数与预计时长；可选增强=stopwatch 每 30s 心跳行（覆盖 winget 源更新期单元零输出窗口）。② **Chrome 处置**（主人定夺）：历史实录=工单 26 CI runner 三连败（DODownloader 0x80D02002，runner 禁 DO 服务）、真机两台正常；工单 33 useLatest 漂移误报；主人本次观感「容易失败或卡住」。断言面仅 cli-tools.winget:182-188 一处声明（verify/inventory 无专项断言），处置成本低。方案 a=除名（主人方向：Edge/Firefox 预装兜底，描述行注明 `winget install Google.Chrome` 自装姿势）；方案 b=拆独立域 chrome.winget（声明保留、爆炸半径隔离，失败只红自己不拖 cli-tools 域）；方案 c=CI runner 跳过模式（工单 26 已提）。③ **上游对照**（microsoft/WindowsDeveloperConfig）：wdc 已超越面=双仓机器对等/跨侧委托、dotfiles 渲染拷贝+triage、verify 断言面、坑实录体系、工单/ADR/dev-standard 治理、mise 钉版策略（上游用 nvm）；上游领先面候选=（a）**重启续跑**——scheduled task 约 30s 后自动续跑 setup（WSL/虚拟化启用需 reboot 场景，wdc 现需手动重跑；坑 14 schtasks 基础设施可复用）；（b）**Workloads 工具链层**——单命令装子集（wdc 域结构是机器域非工作负载域，fss/量化各工具链 mise.toml 已部分承载，是否立项看主人工作流）；（c）**AI/GPU 工具链**——GPU 检测装 PyTorch + Ollama（DGX 机器形态可能真用）；（d）manifest.yml 单一来源驱动（wdc 单一来源散于 Get-WdcDomains/cli-tools.winget/dotfiles-map，已够用，工程美化性质）；不追=Authenticode 签名（成本高，get.ps1 raw 分发现状可接受）、aka.ms 短链（主人域名未知）、troubleshooting 文档（collaboration.md 坑体系已覆盖同域）。

**Blocked by:** None

**Status:** needs-triage

- [ ] ① Stage 3 流式输出修复（bootstrap-main.ps1 一处 + 各域发起 INFO 行；可选 stopwatch 心跳）
- [ ] ② Chrome 处置（方案 a/b/c 待主人定夺，票内推荐 b：隔离爆炸半径且不弃真机声明收敛）
- [ ] ③ 上游超越点立项（候选 a/b/c/d 待主人挑；推荐 a 重启续跑——真装机体验差异最大的一处）
