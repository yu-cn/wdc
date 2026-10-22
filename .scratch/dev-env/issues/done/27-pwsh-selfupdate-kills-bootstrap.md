# 27: cli-tools 的 PowerShell 自更新会杀死 bootstrap 宿主（真机隐患）

**What to decide:** fresh-machine 冒烟两跑实证（工单 26）：cli-tools 域声明 `Microsoft.WinGet/Package [Microsoft.PowerShell] useLatest: true`——当机器 pwsh 落后于 winget 最新版时，bootstrap（宿主是 pwsh）应用该单元触发 PS7 MSI 升级，MSI「关闭正在运行的应用」连带杀掉宿主 PowerShell 进程树（transcript：`[OK] base-windows` 后连续 pipeline stopped；cmd 步骤结论位假阳性报 success）。**现有两机幸免只因 pwsh 恰为最新（no-op）；任何 pwsh 过期的机器（新朋友、久未 sync 的机器）跑 bootstrap 会在 cli-tools 中途死亡。** CI 侧已用 cmd 宿主预对齐绕开（工单 26），产品层需要主人定夺：

- a) **移出 cli-tools，改由编排层管理**：入口引导层已自装 PS7（工单 04）；「保持最新」改为引导层预检「有新版则提示升级并中止/或先自升级再重入」——升级动作永远不在 pwsh 宿主内做
- b) **钉版本**（vp 同款思路）：声明具体版本号，升级成为显式决策——代价：失去自动跟进
- c) **接受现状 + 文档警示**：bootstrap 中途被杀属已知行为，重跑即续（幂等兜底）——代价：首次体验破碎

**Blocked by:** None

**Status:** ready-for-agent

- [x] 环境主人定夺（2026-10-21）：**方案 a**——PS7 生命周期归入口引导层
- [x] cli-tools.winget 移除 Microsoft.PowerShell 单元（同「语言版本走编排层」先例）
- [x] bootstrap.ps1 引导层双路径：5.1 宿主内安全升级（cmd /c 包装，容「无可升级」退出码）；pwsh 宿主（wdc sync）只列表探测+黄字提示走 5.1 入口，绝不本宿主升级
- [x] fresh-machine.yml 删除预对齐步骤（产品层接管，runner 即真实验场）
- [x] run6 验证：runner（pwsh 落后于最新）上无预对齐步骤时 cli-tools 不再杀宿主
- [x] 两机复验：下次 wdc sync 提示行为正常（pwsh 已最新时应静默）

## Comments

- 2026-10-21（主机会话）：证据链：run1/run2 transcript（artifact bootstrap-*.log）中断时间均在 cli-tools 应用 ~2 分钟处；runner 镜像 pwsh 版本落后于 winget stable 是触发条件；两跑结论位均 success（cmd 假阳性形态），判读必须看 transcript——这也是工单 26 加工件上传的原因。

- 2026-10-21（主机会话）补：run5 尝试过 winget 设置层切 winhttp 下载器（无效，但那是针对 Chrome/DO 问题的试验）；本工单的 pwsh-MSI-杀宿主问题独立成立——预对齐步骤（cmd 宿主提前升级 PS7）在 CI 侧已证明有效，真机侧仍待主人从 a/b/c 三案定夺。

- 2026-10-21（主机会话）定夺实录：主人「按建议来」→ 方案 a。弃 b（钉版本只把杀宿主推迟到每次升钉子日，且朋友拿到旧运行时）、弃 c（新朋友首次 bootstrap 无声暴毙，与工单04 的投入直接冲突）。

- 2026-10-21（主机会话）run6 实录：方案 a 生效——runner（落后 pwsh 的真实场）上步骤日志见「检查 PowerShell 7 更新（5.1 宿主内升级安全）…」→ 39 秒后「就位」，进程树全程无恙（transcript 无 pipeline stopped），bootstrap 跑完六阶段至 Summary、退出码诚实。唯一 FAIL 仍是 Chrome（工单26 已知 runner 限制，与本案无关）。顺带：run5 的 winhttp 设置被 run6 证实写坏 winget 配置加载（"Unexpected error while loading settings"），该步骤已删。
- 2026-10-22（ASUS 本机会话）：ASUS 侧复验——pwsh 7.6.6 已最新，今日 bootstrap（pwsh 宿主入口）全程静默、无升级提示，符合「已最新应静默」预期。主机侧下次 sync 顺带观察（行为代码同源、机器无关）。收口归档。
- 2026-10-22（LETH会话）：LETH 侧观察（上条所指主机，hostname=LETH）——pwsh 7.6.7 在位，今日 wdc sync（pwsh 宿主入口）引导层全程静默、无「PowerShell 7 有新版」黄字提示，符合「已最新应静默」预期。两机观察齐。
