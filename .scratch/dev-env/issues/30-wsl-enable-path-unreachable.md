# 30: WSL 启用路径在 bootstrap 内不可达 → 全程提权重构（吸收上游调用纪律）

**What to build:** 实现期间的事实发现升级为架构重构（主人 2026-10-22 定夺：全程提权）。原问题：提权子回合按坑①守卫整段跳过 WSL，非提权回合又无权启用/装发行版——install-wsl.ps1 两个安装分支是不可达代码，README「重启续跑」承诺的路径死循环；工单 16 的复选项「任一新机器实测（含 WSL 未启用路径）」因此从未可验。上游对照（一手源码核对）：microsoft/WindowsDeveloperConfig 两条流程（dev-config 引擎、wsl-comfort）均全程提权，wsl-comfort 的 RunOnce 续跑注释明写 elevated 且续跑后在提权上下文跑发行版内 bootstrap 脚本。其调用纪律：安装类命令新控制台/控制台直连绝不管道捕获；查询类临时文件重定向+关 stdin+硬超时杀；只看退出码（输出文本随系统语言变）。坑①实录发生在旧姿势（PS 管道捕获）下，双回合结构正是为绕它搭的脚手架——工单19 日志丢失、本工单死循环、dotfiles 双跑皆其所生。落地：

1. 全程提权：提权子回合一回合跑完七阶段（含 WSL），父回合只等待+转发退出码；删 SkipRepeat/补跑逻辑；`-NoElevate` 保留为非提权单回合逃生通道
2. 调用纪律全仓统一（lib/common.ps1 单点）：`Wait-WdcProcess`（有界等待+心跳+超时杀）、`Invoke-WslBounded`（临时文件捕获+关 stdin+WSL_UTF8）；`Test-WslEnabled`/`Get-WslDistros`/`Get-WslDefaultUser`/`Invoke-WslScript` 全部改到新姿势，仓库内不再存在 PS 管道捕获的 wsl.exe 调用
3. install-wsl.ps1：启用分支新控制台跑 `wsl --install --no-distribution`（0/3010/1641 判启用，提示重启续跑）；Ubuntu 分支新控制台 `--no-launch` 安装+装完轮询确认发行版真出现（上游 Wait-DevConfigUbuntuVisible 同款）；两分支 BestEffort——失败/超时降级黄字手工指引，不打红
4. 文档同步：README（单命令段/五件事第 3 条/-NoElevate 定位）、collaboration 坑①改写为「调用纪律+逃生通道」、fresh-machine.yml 注释（runner WSL 阶段从整段跳过变真跑，无嵌套虚拟化属预期降级）；upstream-ledger 记吸收一笔

明确不吸收：自动重启（shutdown.exe）+ 计划任务/RunOnce 续跑机制（一年一遇频率撑不起该复杂度）；dism 直开功能与 `--web-download` 回退梯子（个人 Win11 舰队 YAGNI，失败走手工）；OOBE 抑制（牵动发行版内用户供给设计，另行议题）。

**Blocked by:** None

**Status:** ready-for-agent

- [x] lib/common.ps1：Wait-WdcProcess + Invoke-WslBounded + 四函数改造
- [x] install-wsl.ps1：两分支重写（BestEffort + 效果确认）
- [x] bootstrap-main.ps1：全程提权单回合重构
- [x] 文档四处同步 + upstream-ledger 记账
- [x] validate 全绿；wdc verify -Quick 过新姿势（发行版内 probe.sh 实测）
- [x] 主机提权重跑 bootstrap（幂等；UAC 一次）——提权下 WSL 查询+发行版内执行真机验证
- [x] 两机复验：下次 wdc sync 后 WSL 阶段全绿（日常路径的持续验证）
- [ ] 新机首跑（启用→重启→Ubuntu→收尾）——等下一台真机，fresh-machine CI 部分覆盖

## Comments

- 2026-10-22（主机）：三方案推演与上游一手源码核对的完整过程见本工单首版（git 历史）；主人两轮追问后定夺全程提权，依据是上游两条流程的完整先例——含提权下发行版内执行的规模化实证（wsl-comfort RunOnce 续跑注释明写 elevated）。
- 2026-10-22（ASUS）：真机验收实录——本机提权重跑 bootstrap 全绿（294s，七阶段单回合）；elevated-20261022-202710.log 里 Stage 6 于提权上下文完整执行：有界查询（WSL/Ubuntu 探测）+ 发行版内 setup-ubuntu.sh（文件捕获输出可读、心跳触发一次、root/user 双阶段 + probe 全过、零挂死）。对比旧双回合结构同内容 403s——省去父回合补跑。
- 2026-10-22（ASUS）：fresh-machine 冒烟 run 39779367377 全绿收官，且远超「部分覆盖」预期——runner 新镜像有嵌套虚拟化，全新链路真实执行：WSL 探测 → **Ubuntu 全新安装**（新控制台姿势 6.5 分钟、心跳 6 次、效果确认轮询通过）→ 发行版内环境（无 OOBE 的全新发行版，默认用户探测回落 root，setup-ubuntu root/user 双阶段照常完成，docker 29.9.2 装成）→ probe 全绿（id:MISSING 属预期——runner 无真实身份，红线不外泄）→ 工单29 的身份占位提醒也在 CI 首秀。**唯一仍未验证面收窄为：WSL 功能全新启用分支（含重启续跑）——runner 镜像预启用、ASUS 已启用，等另一台真机或未来新机。** 真机注意：OOBE 建用户后重跑 bootstrap，发行版内环境会以真实用户重铺（幂等）。
- 2026-10-22（ASUS 本机会话）：机器名勘误——本机 hostname=ASUS（盘点报告同证），上方两条注释「（主机）」已就地勘正；旧工单里「主机会话」均指另一台机器。「两机复验」之 ASUS 侧已由今日提权真跑覆盖（WSL 阶段全绿），另一机待其下次 sync。
- 2026-10-22（LETH会话）：LETH 侧复验——本机 sync 拉取 45 提交（全程提权重构首上本机），bootstrap 七阶段单回合全绿（980s；Stage 3 winget configure 774.5s 属本机 winget 源当日偏慢，仍绿）。elevated-20261022-230552.log 里 Stage 6（152.8s）于提权上下文真实执行：有界查询（WSL 功能/Ubuntu）+ setup-ubuntu.sh root/user 双阶段输出可读（心跳触发一次）+ probe 七项全过，零挂死；Stage 7 dotfiles 同轮完成（ubuntu.ico 新装，渲染至机器本地）。verify 六组断言全绿、三域漂移=0。两机复验收口；工单保持开放——「新机首跑」待下一台真机。
- 2026-10-23（LETH会话）：新机首跑·虚拟真跑实录（主人 10-23 定夺由本机 Hyper-V 全程执行；Gen2 + 嵌套虚拟化 VM「WDC-VM01」4vCPU/8GB，apply 直部署 Win11 Pro 25H2 build 26200，无人值守 OOBE）——基线严格无预启用：WSL/VMP 双 Disabled。**run1：启用分支首次真实执行**——有界调用三次心跳，`wsl --install --no-distribution` 新控制台 ~4 分钟，按 0/3010/1641 判定 → `[CHANGED] WSL 功能已启用（需重启激活）`，BestEffort 不打红、其余阶段照常走完（330s）。冷启动（顺带开嵌套虚拟化）后 run2：`Test-WslEnabled` ✓（store 版 WSL 3.0.3 以 VMP 为据，旧特性名 Disabled 不碍判定）→ Ubuntu 分支真实执行，但 `wsl --install -d Ubuntu` 因**宿主 TUN(MITM) 对 raw.githubusercontent.com 返回 502/无效响应**拉取发行版目录失败，按设计降级黄字手工指引（Wsl/InstallDistro/HTTP_E_STATUS_BAD_GATEWAY，退出码 -1 不打红）——发行版注册最终由官方 `ubuntu.exe install --root` 一步完成（宿主网络限制所致的等价替代，非 WDC 路径问题；主人现场明示「用 wsl --install 就行、别太机械」后重试本尊仍 502）。run3：Ubuntu 已就位 → **发行版环境完整铺设**（root 阶段 7 次心跳：apt 基础包/gh apt 源/Docker 29.9.2/systemd=true/移除 Go/默认 bash；user 阶段 root 回落：uv 0.13.5/vp 1.3.0+Node 24.22.1/starship/dotfiles 链接/身份占位带过；probe：shell=/bin/bash、docker 29.9.2、uv、vp、node、links 全过，id:MISSING 为不填身份的红线预期）→ 6/7 阶段绿（2411s，唯一 FAIL 是 base-windows 域部分注册表单元在 26200 构建上不适用，见工单31）。终验 verify：5/6 组断言过，5 项未过全为身份红线预期 ×2 与 base-windows 同源 ×3。**结论：启用→重启→Ubuntu→收尾全链在无预启用环境完整走通，启用分支与 BestEffort 降级路径双双实证**；VM 证据是否可勾选「新机首跑」（措辞为真机）归主人定夺。宿主侧陪跑设施（wdc-test 交换机/NetNat/5.1 代理/根证）均为 LETH 网络特殊拓扑所迫，处置清单见会话收尾。
