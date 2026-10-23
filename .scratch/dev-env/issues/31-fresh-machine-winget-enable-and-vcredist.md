# 31: 新机首跑两缺口——winget configure 默认未启用 + vp 依赖 VC++ 运行库

**What to build:** 虚拟新机首跑实录（2026-10-23，全记录见工单 30 注释）暴露两个通用核心缺口——任何真裸机首跑 bootstrap 都会撞上，两机与 CI 从未暴露只因均有既有状态垫底：

1. **winget configure 需一次性启用**：全新 25H2 上 `winget configure`（validate 与 apply 全部）直接返回「Configuration is not enabled. Run `winget configure --enable` to enable it.」，退出码 -1978335127——Stage 2 校验与 Stage 3 应用全线 FAIL；`--accept-configuration-agreements` 不绕过该闸。`--enable` 声明需 store access，实测重试一次即成（首次可能 E_ABORT 0x80004004）。
2. **vp 依赖 VC++ 2015-2022 x64 运行库**：裸机无 vc_redist 时 vp.exe 报 0xC0000135（STATUS_DLL_NOT_FOUND）无法启动，Stage 4 install-languages FAIL（vp 安装器输出自带修复指引 aka.ms/vs/17/release/vc_redist.x64.exe）。

修复思路（供主人定夺）：bootstrap-main 在 Stage 3 前幂等执行 `winget configure --enable`（容 E_ABORT 重试）；install-languages.ps1 装 vp 前探测 VC++ 运行库缺失则预装 vc_redist（直链或 winget）。

**Blocked by:** None

**Status:** needs-triage

- [x] winget configure --enable 预置（bootstrap 编排层）
- [x] vc_redist 预检/预装（install-languages.ps1）
- [x] 复验（WDC-VM01 虚拟机在位，可直接重放裸机路径）

## Comments

- 2026-10-23（LETH会话）：开单实录——VM 首跑 run1/run2 的 Stage 2/3/4 FAIL 全部由此二因引起；宿主侧补 `winget configure --enable`（重试 1 次成功）与 vc_redist（25.6MB 静默装）后 run3 Stage 2/4 转绿。同场观察第三现象一并请裁：build 26200 上 base-windows 的 TaskbarHideWidgets/WidgetServiceOff 等小组件注册表单元应用失败（LETH 26300 全绿）——疑构建差异而非缺口，待定夺是否单列。
- 2026-10-23（LETH会话）：主人定夺「及时修复」——同日实施。修复①：bootstrap-main Stage 1 提权且非 -ValidateOnly 时幂等 `winget configure --enable`（重试×3 容 E_ABORT，未成黄字降级不打红）；修复②（改用声明式，优于原案的脚本预装）：cli-tools.winget 增 VCRedist2015Plus 单元（Microsoft.VCRedist.2015+.x64，Stage 3 应用天然先于 Stage 4 的 vp；两机与 CI 均已装=幂等无扰动）。**复验**（WDC-VM01 复现两触发条件——`configure --disable` + 卸载 VCRedist——后 run4，447s）：Stage 1 `[OK] configure 组件 - winget configure 已启用（幂等）`（7.2s）、Stage 2 校验全绿（原三域全 FAIL）、Stage 3 VCRedist2015Plus 单元已应用、Stage 4 vp 全绿——两缺口闭环。run4 唯一 FAIL 为 base-windows 26200 小组件注册表单元（上条已录的第三现象，与本案无关）。三框齐，归档。
