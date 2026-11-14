# 工单01：`.wslconfig` 入声明——机器派生值公式渲染

Status: done

## 背景

主人重度依赖 WSL（2026-11-14 自述）。盘点发现 `%USERPROFILE%\.wslconfig`（VM 形态：16 核/16GB 配额、mirrored 网络、dnsTunneling、autoMemoryReclaim、sparseVhd、virtiofs）为主人 2026-11-13 手调，**完全无人管**——新机器 bootstrap 后全默认（vmmem 只增不减、NAT 网络）；inventory 只收 `wsl -l -v` 不录它；verify 无断言，漂移不可见。

## 内容

- `dotfiles/windows/wslconfig` 模板：现手调件内容 + 通用化注释 + `{{WDC_WSL_PROCESSORS}}`/`{{WDC_WSL_MEMORY_GB}}` 占位符
- `scripts/lib/wslconfig.ps1` 渲染单一来源（install-wsl / install-dotfiles / verify / inventory 四方共读）：
  - 公式（ADR-0008，锚定主人手调值）：processors = 逻辑核−6 下限 4（22 核 → 16）；memory = 物理内存半数向上取整夹 8–16GB（31GB → 16）
  - 渲染 CRLF（Windows 侧文件习惯，与本机既有件一致）；幂等：内容一致 OK 跳过，不一致备份 `.bak` 一次重写 + 提示 `wsl --shutdown` 生效
- 不入 dotfiles-map 静态模型（纯拷贝不适配机器派生值；`~/.wdc` 指针同款先例）——install-dotfiles 在 map 循环外调 `Install-WslConfig`；install-wsl.ps1 在任何 wsl.exe 动作前预渲染（全新机器 VM 首启即读声明形态）
- verify 断言：落点内容 == 自当前机器事实的公式渲染（断效果；有意手调改模板/公式吸收）

## 验收清单

- [x] 本机首渲染：值与手调件一致（16/16GB），旧件备份 .bak
- [x] 幂等：二跑 OK 零 CHANGED（CI fresh-machine 幂等重跑腿同款判据）
- [x] verify 断言绿；validate 全绿（PSScriptAnalyzer 含新 lib）

## 实录

- 真机（ASUS）：`Get-WslConfigFacts` → 22 核/32GB → 16/16GB（与主人手调值逐项一致）；首跑 CHANGED + `.wslconfig.bak` 备份、二跑 OK 幂等跳过
- verify -Quick：`WSL .wslconfig 与声明渲染一致` OK；validate 三段全绿（wslconfig.ps1 过 PSScriptAnalyzer）
- 注：PhysicalGb=32（31.x 向上取整），公式 ceil(32/2)=16 封顶 16 ✓
