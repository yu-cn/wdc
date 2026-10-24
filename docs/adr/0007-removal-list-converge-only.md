# 移除清单收敛为「自清理 + 迁移冲突」

背景（谁在什么场景问的）：仓库以 MIT 开源后，README「快速开始/直接用」邀请陌生人直接 bootstrap，而移除清单 Stage 5 会在陌生机器上卸载 Oh My Posh、直装 Node、Python 3.13、nvm-windows、.NET SDK 10 与 ASP.NET 运行时，WSL 侧还有 `rm -rf /usr/local/go`。这些项的立项理由全是清环境主人机器上的 microsoft/WindowsDeveloperConfig 上游残留与 WDC 早期自装（工单21）——是机器史，不是配置语义；且两台主人机已分别收敛完毕（工单21 Comments 2026-10-22 实测），清单只剩幂等空转。环境主人 2026-10-25 定夺瘦身。

决策：移除清单语义收敛为两类，其余全部退出——

1. **自清理**：本仓自己的注入物（WT fragments：上游 wsl-comfort/dev-config 注入的 ComfortShell/DevConfig，与 ADR-0006 退役机制的残留片段）；
2. **迁移冲突**：与声明安装真冲突的项（VSCode 商店 MSIX——不卸则双编辑器并存；商店版与 winget 版用户数据独立，卸载不丢配置）。

退出项：Oh My Posh、直装 Node、Python 3.13、nvm-windows 全套、.NET SDK 10 与 ASP.NET 运行时、WSL Go。退出后 bootstrap 对陌生机器不再有卸载面——fragments 在陌生机器不存在（幂等 OK），MSIX 是有 README 披露的迁移。

理由：

- 「装我的偏好」是声明状态本体（Stage 3 各域），「删你的东西」不是——全仓唯一的减法机器就是这份清单，它减的恰是别人在用的软件；开源仓库破坏用户机器上的在用工具链，是比漏装严重得多的故障模式。
- 机器自留地原则（ADR-0003）要求清单外的工具一概不碰；反推即清单内的东西永远不能成为自留地——Oh My Posh、.NET SDK 这类工具被清单永久封死，属过度约束。
- 清理工作已在主人机全部完成，保留空转代码只付风险不收收益。

拒绝的替代：

- **全清单保留**：破坏公众机器 + 与自留地矛盾，只为主人机上已完成的清理保留空转代码。
- **整清单改主人机开关**（默认不执行、标记/参数启用）：瘦身后已无破坏面可保护，开关是纯复杂度（标记生命周期、verify 断言条件化、wdc sync 链路），违反「不为假想需求新增流程」。
- **只摘 .NET + Go**（主人原话最小集）：同类雷仍在（Node/nvm/Oh My Posh 对公众、对自留地），原则没有贯彻。

代价与边界：verify 删 oh-my-posh / nvm 目录 / .NET SDK 三条「已卸」断言，保留 VSCode 单版本（仍在清单）与 .NET Desktop 运行时保留（保护性）；「先装后拆」顺序语义失效，Stage 5 改为收敛执法（幂等、全用户级、无提权依赖）；vp 托管模式下 system node 若在由 PATH 优先级裁决，不再靠卸载兜底（`node 走 vp shim` 断言仍在，FAIL 按机器 PATH 自留地处置）；Stage 3 注册表收敛（远程桌面关闭等）是声明状态本体，本轮不动，README 披露覆盖。编号说明：本 ADR 与 LDC 侧 ADR-0007（双仓统筹）同号不同物——双仓共用决策落 LDC 编号（dev-standard §3），WDC 侧代码注释中的既有裸引用均指 LDC 侧，已就地加「LDC」限定词。
