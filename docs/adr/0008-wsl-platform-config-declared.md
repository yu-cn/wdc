# WSL 平台配置入声明——.wslconfig 自适应渲染 + wsl.conf 保护合并

2026-11-14 主人自述「对 WSL 服务重度依赖」，评审「新机器一次性收敛」时盘点出三层**手工咬合、仓库零声明**的状态（本机 ASUS 实录）：`%USERPROFILE%\.wslconfig`（2026-11-13 手调 VM 形态）、`/etc/wsl.conf` 的 `[network]` 段、systemd-resolved → dnscrypt-proxy 加密 DNS 链（2026-08-18 主人侧手工搭建，apt 账本/时间线/toml 原封三证——与 WSL dnsTunneling 无关，当时曾被误判）。同场主人定夺边界：**WSL 平台/集成配置归 WDC**——按「配置属于谁」而非「文件落在哪个文件系统」划界（wsl.conf 读者是 wslservice/init，非发行版内工具）；wsl.conf 管理权自 LDC 收回（联动 [LDC ADR-0021](https://github.com/yu-cn/ldc/blob/main/docs/adr/0021-wsl-platform-config-back-to-wdc.md)，其 install-packages 机器形态段瘦身为默认 shell + docker 组两件）。

## 决策

- **`.wslconfig` 入声明**（Windows 侧半边，VM 形态）：模板 `dotfiles/windows/wslconfig` + `scripts/lib/wslconfig.ps1` 渲染单一来源（install-wsl / install-dotfiles / verify / inventory 四方共读）。功能旗标（mirrored 网络、dnsTunneling、autoMemoryReclaim=gradual、sparseVhd、virtiofs 等）为通用核心；**机器派生值安装期公式渲染**（ADR-0004 模式，`~/.wdc` 指针同款先例）：`processors = 逻辑核−6`（下限 4）、`memory = 物理内存半数向上取整夹 8–16GB`——公式锚定主人手调值（22 核/31GB 机 → 16/16GB）。渲染 CRLF、幂等（内容一致跳过）、变更备份 `.bak` 一次并提示 `wsl --shutdown` 生效。install-wsl.ps1 在任何 wsl.exe 动作前预渲染——全新机器 WSL2 VM 自首次启动即读声明形态。不入 dotfiles-map 静态模型（纯拷贝不适配派生值，hash 比对会永久假漂移）。
- **`/etc/wsl.conf` 整文件归 WDC 单一实现**（发行版侧半边）：setup-ubuntu.sh root 阶段（委托 LDC 之前）**保护合并**声明键——`[boot]` systemd=true、`[user]` default=<默认用户>（`Get-WslDefaultUser` 探测值传入）。保护语义：段内首见替换、重复剔除、缺键段尾补、缺段文末补；**其余段与键原样保留**。fresh-machine 时序不变（写入 → `wsl --shutdown` 生效 → LDC `docker_skipped()` 无 systemd 中间态自跳、重启后重跑补装）。
- **verify 断言**（断效果不断实现，坑11）：`.wslconfig` 落点 == 自当前机器事实的公式渲染；wsl.conf 两声明键在位且 `[user] default` 与独立探测的默认用户互证。
- **DNS 姿态（dnscrypt + resolved drop-in + wsl.conf `[network]` 段）定性机器自留地**：主人 2026-11-14 定夺——对本机有价值（三个月无感运行、开发者域名抗污染解析），对大众不值得（Windows 11 原生 DoH 一开关即全机覆盖且 dnsTunneling 下 WSL 跟宿主走；`FallbackDNS` 空则隧道断即全瘫、因网而异），fork 用户与网络异质机器大面积触发 GLOSSARY 通用核心出局判据。故不入声明、verify 不断言；跨机差异由 inventory 补录呈现（工单03）。

## 取舍

当初把 wsl.conf 移交 LDC（工单41）的动因是 WDC root 直调缺 SUDO_USER 的实现便利，`LDC_USER` 契约补齐后障碍已消失；本 ADR 恢复领域划界。DNS 链曾评估入 LDC 通用核心（备选 a）——`127.0.2.1` 上行属 WSL 平台耦合产物，且入声明即要求全机同款网络姿势，主人否决。

拒绝的替代：**`.wslconfig` 入 dotfiles-map**（静态纯拷贝模型无法承载派生值——verify 的模板 hash 比对将永久假漂移，六方消费面全要开自适应分支，爆炸半径大于收益）；**固定通用值**（16GB 硬编码对小内存机器过量、对大机器武断——派生值就该渲染，ADR-0004 既有答案）；**wsl.conf INI 分段两仓共管**（WDC 管 `[boot]`/`[user]`、LDC 管 `[network]`——单文件两主是漂移温床，保护合并语义两仓各造一份）；**DNS 姿态入声明**（上述出局判据 + 四层链排障面——主人三个月后自己也需考古才知其存在）。
