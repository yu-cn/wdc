# 字体供应走 winget 声明式（JetBrainsMono NF）

CascadiaCode 被 winget 目录除名（2026-10-21，manifest 404、全源搜索为空）后评估三条路：A 字体归机器自留地；B 编排层脚本装官方 GitHub release（钉版本）；C 换 winget 在售 NF 包。选 **C**（`DEVCOM.JetBrainsMonoNerdFont`，WiX MSI）：全声明式、升级与漂移核销走 winget 原生、verify 零新增。注意该 MSI 注册**短族名**：NF=标准 / NFM=单宽图标（终端用）/ NFP=比例 / NL=无连字系。

B 首评因「注册姿势存疑」降级，后证实系查询路径乌龙（HKCU 正确路径是 `Windows NT\CurrentVersion\Fonts`——本机旧 Cascadia 字体在该处 74 条注册齐全，姿势完全标准），B 实际可行且本机字体从未被删；其唯一固有糙点是字体文件被进程占用不可覆盖（升版需手动删字体重跑）。环境主人 2026-10-21 体验 JetBrainsMono 后复审（含「换回 Cascadia」选项）决定**维持 C**：审美可接受，不值得为「新机首日开箱即有」的低频收益引入脚本机制与永久糙点。

拒绝的替代：A（新机首开终端提示符图标豆腐块，违背工单 28 初衷）；B（可行但引入安装脚本 + 钉子文件 + 占用不可覆盖的永久糙点）。
