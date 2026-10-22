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
- [ ] 两机复验：下次 wdc sync 后 WSL 阶段全绿（日常路径的持续验证）
- [ ] 新机首跑（启用→重启→Ubuntu→收尾）——等下一台真机，fresh-machine CI 部分覆盖

## Comments

- 2026-10-22（主机）：三方案推演与上游一手源码核对的完整过程见本工单首版（git 历史）；主人两轮追问后定夺全程提权，依据是上游两条流程的完整先例——含提权下发行版内执行的规模化实证（wsl-comfort RunOnce 续跑注释明写 elevated）。
- 2026-10-22（主机）：真机验收实录——主机提权重跑 bootstrap 全绿（294s，七阶段单回合）；elevated-20261022-202710.log 里 Stage 6 于提权上下文完整执行：有界查询（WSL/Ubuntu 探测）+ 发行版内 setup-ubuntu.sh（文件捕获输出可读、心跳触发一次、root/user 双阶段 + probe 全过、零挂死）。对比旧双回合结构同内容 403s——省去父回合补跑。唯一未验面 = 全新启用分支，待新机/fresh-machine CI。
