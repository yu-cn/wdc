# WDC 与 WSL / LDC 的关系——分层与边界

> 一页讲清「WDC 管 WSL 的什么、和 LDC 怎么协作」。决策正典见 [ADR-0008](adr/0008-wsl-platform-config-declared.md)（平台配置）、[LDC ADR-0007](https://github.com/yu-cn/ldc/blob/main/docs/adr/0007-wdc-ldc-coordination.md)（双仓协作）、GLOSSARY「双边最优化」「机器对等」。

## 一图流

```
Windows 机器 ──bootstrap──> WDC ──WSL 平台层（下表四件）
                            │
                            └─发行版内部环境──委托──> LDC（~/dev/ldc，ensure_ldc 自动拉取）
                                apt 包 / gh / Docker Engine / uv / mise / Starship
                                / Linux dotfiles / 默认 shell
独立 Linux 机器 ─────────────────────────────────────> LDC 直接使用（不经 WDC）
```

## WDC 对 WSL 只管「平台层」，不进发行版

| 层 | 内容 | 机制 |
|---|---|---|
| WSL 功能与发行版安装 | 启用组件 → 重启 → 一次性续跑任务自动接续 → 装 Ubuntu → 收尾 | `install-wsl.ps1`；wsl.exe 全走有界调用纪律（坑1：`Invoke-WslBounded`，提权上下文零挂死） |
| `.wslconfig`（Windows 半边） | VM 形态（mirrored 网络 / dnsTunneling / 内存回收 / 稀疏 vhdx / virtiofs）+ 机器派生值公式渲染（内存=半数夹 4–16 且宿主留 ≥4GB；核数=逻辑核−6 下限 4） | 单一来源 `scripts/lib/wslconfig.ps1`，install/verify/inventory 四方共读；不入静态 dotfiles-map（纯拷贝承载不了派生值） |
| `/etc/wsl.conf`（发行版半边） | 只保护合并两个声明键（`[boot] systemd=true`、`[user] default=<探测>`）；未管理段（如你的 DNS 姿态）保护不动 | bootstrap root 阶段；首见替换/缺键补/重复剔 |
| 验收 | `.wslconfig` 渲染一致 + wsl.conf 两键互证；发行版内部透传 `ldc verify --quick` | verify 第 5/6 组 |

**划界判据：「配置属于谁」而非「文件在哪个文件系统」**——wsl.conf 的读者是 wslservice/init（平台，归 WDC）；发行版内的 shell/包管理（日常生活，归 LDC）。

## 与 LDC 的关系——对等双仓、最小契约、单向委托

- **两个独立项目、无主从**（工单41「双边最优化」+ v1-program 方案 A）：WDC 用 Windows 母语，LDC 用 Linux 母语（Ubuntu/Debian 双发行版 × 双架构），各自完整自闭环——**对齐的是目标，不是实现**。
- **一个发行版只归一个管理器**：WDC 管的 WSL Ubuntu 里 Linux 收敛走委托（`setup-ubuntu.sh` 薄包装 → LDC bootstrap）；LDC 独立管理的机器 WDC 不沾。
- **契约最小面**：退出码语义 + `LDC_TODO` 机器标记（未知标记透传真问题不静默吞）+ cli-parity UX 约定层。
- **姿态已对齐**（LDC ADR-0022 镜像 WDC ADR-0009）：双仓同为「一次性配置 + 显式更新/回归」。
- **退出面**：`wdc exit -WithWsl` 还原 WDC 的平台层（.wslconfig / wsl.conf 声明键）并打印 LDC 侧指引；**发行版卸载（`wsl --unregister`）只指路永不代跑**——发行版内可能有用户数据。LDC 侧退出见 LDC 仓。

## 想改 WSL 相关配置时找谁

| 想改什么 | 改哪里 |
|---|---|
| VM 形态（网络/内存/回收旗标） | `dotfiles/windows/wslconfig` 模板 + 公式在 `scripts/lib/wslconfig.ps1` |
| systemd / 默认用户 | bootstrap root 阶段声明键（ADR-0008） |
| 发行版内的包 / shell / 提示符 | LDC 仓（`configs/` 与 `dotfiles/`） |
| wsl.conf 未管理段（DNS 等） | 机器自留地——自己维护，WDC/LDC 都不碰 |
